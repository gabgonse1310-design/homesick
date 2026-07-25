import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../data/mock_people.dart';
import '../models/delivery_journey.dart';
import '../models/letter.dart';
import '../models/person.dart';
import '../services/letter_service.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';
import '../widgets/time_capsule_card.dart';
import 'delivery_method_screen.dart';
import 'handwritten_letter_screen.dart';
import 'scanned_letter_screen.dart';
import 'postcard_letter_screen.dart';
import 'time_capsule_creator_screen.dart';

class WriteLetterScreen extends StatefulWidget {
  final Person? initialPerson;
  final List<Person>? availablePeople;
  final Letter? initialLetter;
  final bool startAsTimeCapsule;

  const WriteLetterScreen({
    super.key,
    this.initialPerson,
    this.availablePeople,
    this.initialLetter,
    this.startAsTimeCapsule = false,
  });

  @override
  State<WriteLetterScreen> createState() => _WriteLetterScreenState();
}

class _WriteLetterScreenState extends State<WriteLetterScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _letterController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  LetterType? _selectedLetterType;
  Person? _selectedPerson;
  final List<String> _photoPaths = [];
  final List<String> _removedRemotePhotoUrls = [];

  bool _isTimeCapsule = false;
  DateTime? _openDate;
  String _capsuleAccessMode = CapsuleAccessMode.onlyMe;
  final List<String> _authorizedPersonKeys = [];
  final List<String> _capsuleRecipientKeys = [];

  bool _hasSaved = false;
  bool _isSaving = false;
  bool _isAddingPhotos = false;

  List<Person> get _people => widget.availablePeople ?? mockPeople;

  bool get _isEditing => widget.initialLetter != null;

  @override
  void initState() {
    super.initState();

    final initialLetter = widget.initialLetter;
    _selectedPerson = widget.initialPerson;
    if (widget.initialPerson != null) {
      _capsuleRecipientKeys.add(widget.initialPerson!.personKey);
    }
    _selectedLetterType = initialLetter?.letterType;

    if (initialLetter != null) {
      _titleController.text = initialLetter.title;
      _letterController.text = initialLetter.body;
      _photoPaths.addAll(initialLetter.photoPaths);
      _isTimeCapsule = initialLetter.isTimeCapsule;
      _openDate = initialLetter.openDate;
      _capsuleAccessMode = initialLetter.capsuleAccessMode;
      _authorizedPersonKeys.addAll(initialLetter.authorizedPersonKeys);
      if (!_capsuleRecipientKeys.contains(initialLetter.personKey)) {
        _capsuleRecipientKeys.add(initialLetter.personKey);
      }
    }

    if (widget.startAsTimeCapsule && initialLetter == null) {
      _isTimeCapsule = true;
      _selectedLetterType = LetterType.typed;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openTimeCapsuleCreator();
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _letterController.dispose();
    super.dispose();
  }

  String _personKey(Person person) {
    return person.personKey;
  }

  List<String> _authorizedPersonNames() {
    return _people
        .where((person) => _authorizedPersonKeys.contains(_personKey(person)))
        .map((person) => person.name)
        .toList();
  }

  String _createLetterId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _resolvedTitle({
    required String body,
    required bool isDraft,
  }) {
    final enteredTitle = _titleController.text.trim();

    if (enteredTitle.isNotEmpty) {
      return enteredTitle;
    }

    if (isDraft) {
      return 'Untitled Draft';
    }

    final firstLine = body
        .split('\n')
        .map((line) => line.trim())
        .firstWhere(
          (line) => line.isNotEmpty,
          orElse: () => 'Untitled Letter',
        );

    if (firstLine.length <= 42) {
      return firstLine;
    }

    return '${firstLine.substring(0, 42).trim()}…';
  }

  Future<void> _choosePerson() async {
    if (_people.isEmpty) {
      _showMessage('Add someone before writing a letter.');
      return;
    }

    final selectedPerson = await showModalBottomSheet<Person>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Who are you writing to?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _people.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final person = _people[index];
                      final isSelected = _selectedPerson != null &&
                          _personKey(_selectedPerson!) ==
                              _personKey(person);

                      return Material(
                        color: isSelected
                            ? AppColors.cream
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () =>
                              Navigator.pop(context, person),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.terracotta
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                BotanicalPersonIcon(
                                  symbol: person.symbol,
                                  size: 48,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      if (person
                                          .relationship.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          person.relationship,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppColors.softGrey,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.terracotta,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedPerson == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPerson = selectedPerson;
      if (!_isTimeCapsule) {
        _capsuleRecipientKeys
          ..clear()
          ..add(selectedPerson.personKey);
      }
    });
  }

  List<Person> get _capsuleRecipients {
    return _people
        .where((person) => _capsuleRecipientKeys.contains(person.personKey))
        .toList();
  }

  Future<void> _openTimeCapsuleCreator() async {
    if (_people.isEmpty) {
      _showMessage('Add someone before creating a time capsule.');
      return;
    }

    final result = await Navigator.push<TimeCapsuleSetupResult>(
      context,
      MaterialPageRoute(
        builder: (context) => TimeCapsuleCreatorScreen(
          people: _people,
          initialRecipientKeys: _capsuleRecipientKeys,
          initialOpenDate: _openDate,
          initialAccessMode: _capsuleAccessMode,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final selectedPeople = _people
        .where((person) => result.recipientKeys.contains(person.personKey))
        .toList();

    setState(() {
      _isTimeCapsule = true;
      _openDate = result.openDate;
      _capsuleAccessMode = result.accessMode;
      _capsuleRecipientKeys
        ..clear()
        ..addAll(result.recipientKeys);

      if (selectedPeople.isNotEmpty) {
        _selectedPerson = selectedPeople.first;
      }
    });
  }

  Future<void> _showPhotoSourcePicker() async {
    if (_isAddingPhotos || _isSaving) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add a Memory',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.terracotta,
                  ),
                  title: const Text('Choose from gallery'),
                  subtitle: const Text('Select one or more photos'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.terracotta,
                  ),
                  title: const Text('Take a photo'),
                  subtitle: const Text('Use your phone camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isAddingPhotos = true;
    });

    try {
      final pickedImages = await _imagePicker.pickMultiImage(
        imageQuality: 88,
      );

      if (pickedImages.isEmpty) {
        return;
      }

      final savedPaths = <String>[];

      for (final image in pickedImages) {
        savedPaths.add(await _copyPhotoToAppStorage(image));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _photoPaths.addAll(savedPaths);
      });
    } catch (_) {
      if (mounted) {
        _showMessage('We could not add those photos.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingPhotos = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isAddingPhotos = true;
    });

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
      );

      if (pickedImage == null) {
        return;
      }

      final savedPath = await _copyPhotoToAppStorage(pickedImage);

      if (!mounted) {
        return;
      }

      setState(() {
        _photoPaths.add(savedPath);
      });
    } catch (_) {
      if (mounted) {
        _showMessage('We could not add that photo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingPhotos = false;
        });
      }
    }
  }

  Future<String> _copyPhotoToAppStorage(XFile image) async {
    final documentsDirectory =
        await getApplicationDocumentsDirectory();
    final memoriesDirectory =
        Directory('${documentsDirectory.path}/homesick_memories');

    if (!await memoriesDirectory.exists()) {
      await memoriesDirectory.create(recursive: true);
    }

    final extension = _fileExtension(image.path);
    final filename =
        'memory_${DateTime.now().microsecondsSinceEpoch}$extension';
    final savedFile =
        await File(image.path).copy('${memoriesDirectory.path}/$filename');

    return savedFile.path;
  }

  String _fileExtension(String path) {
    final lastDot = path.lastIndexOf('.');

    if (lastDot == -1) {
      return '.jpg';
    }

    return path.substring(lastDot);
  }

  bool _isRemotePhoto(String path) {
    final uri = Uri.tryParse(path);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  Future<void> _removePhoto(String path) async {
    setState(() {
      _photoPaths.remove(path);
      if (_isRemotePhoto(path)) {
        _removedRemotePhotoUrls.add(path);
      }
    });

    if (_isRemotePhoto(path)) {
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // The letter can continue even if an unused local file cannot be deleted.
    }
  }

  Future<List<String>> _uploadPendingPhotos(String letterId) async {
    final remoteUrls = _photoPaths
        .where(_isRemotePhoto)
        .toList(growable: true);
    final localPaths = _photoPaths
        .where((path) => !_isRemotePhoto(path))
        .toList();

    if (localPaths.isNotEmpty) {
      final uploadedUrls = await PhotoStorageService.instance.uploadPhotos(
        letterId: letterId,
        localPaths: localPaths,
      );
      remoteUrls.addAll(uploadedUrls);
    }

    return remoteUrls;
  }

  Future<void> _deleteRemovedRemotePhotos() async {
    if (_removedRemotePhotoUrls.isEmpty) {
      return;
    }

    await PhotoStorageService.instance.deletePhotosByUrls(
      List<String>.from(_removedRemotePhotoUrls),
    );
    _removedRemotePhotoUrls.clear();
  }

  bool _validateLetter() {
    if (_isTimeCapsule && _capsuleRecipients.isEmpty) {
      _showMessage('Choose at least one person for this time capsule.');
      return false;
    }

    if (!_isTimeCapsule && _selectedPerson == null) {
      _showMessage('Please choose who this letter is for.');
      return false;
    }

    if (_letterController.text.trim().isEmpty) {
      _showMessage('Your letter is still empty.');
      return false;
    }

    return true;
  }

  Future<void> _saveDraft() async {
    if (!_validateLetter() || _isSaving) {
      return;
    }

    final person = _selectedPerson!;
    final body = _letterController.text.trim();
    final now = DateTime.now();
    final existingLetter = widget.initialLetter;
    final letterId = existingLetter?.id ?? _createLetterId();

    setState(() {
      _isSaving = true;
    });

    try {
      final photoUrls = await _uploadPendingPhotos(letterId);

      final draft = Letter(
        id: letterId,
        personKey: _personKey(person),
        recipientName: person.name,
        recipientRelationship: person.relationship,
        title: _resolvedTitle(body: body, isDraft: true),
        body: body,
        createdAt: existingLetter?.createdAt ?? now,
        updatedAt: now,
        isDraft: true,
        isFavorite: existingLetter?.isFavorite ?? false,
        isTimeCapsule: _isTimeCapsule,
        openDate: _isTimeCapsule ? _openDate : null,
        capsuleAccessMode: _isTimeCapsule
            ? _capsuleAccessMode
            : CapsuleAccessMode.onlyMe,
        authorizedPersonKeys: _isTimeCapsule
            ? List<String>.from(_authorizedPersonKeys)
            : const [],
        authorizedPersonNames: _isTimeCapsule
            ? _authorizedPersonNames()
            : const [],
        letterType: _selectedLetterType ?? LetterType.typed,
        photoPaths: photoUrls,
        deliveryJourney: existingLetter?.deliveryJourney,
      );

      await LetterService.instance.saveLetter(draft);
      await _deleteRemovedRemotePhotos();

      if (!mounted) {
        return;
      }

      setState(() {
        _hasSaved = true;
        _isSaving = false;
      });

      _showMessage(
        _isEditing
            ? 'Your changes were saved.'
            : 'Your draft for ${person.name} was saved.',
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage('We could not save your draft or upload its photos.');
    }
  }

  Future<void> _sealLetter() async {
    if (!_validateLetter() || _isSaving) {
      return;
    }

    if (_isTimeCapsule && _openDate == null) {
      _showMessage('Choose when the time capsule should open.');
      return;
    }

    if (_isTimeCapsule &&
        _capsuleAccessMode == CapsuleAccessMode.trustedPeople &&
        _authorizedPersonKeys.isEmpty) {
      _showMessage('Choose at least one trusted person who may open it.');
      return;
    }

    final recipients = _isTimeCapsule ? _capsuleRecipients : [_selectedPerson!];
    final person = recipients.first;
    final recipientLabel = recipients.length == 1
        ? recipients.first.name
        : '${recipients.length} people';

    final shouldSeal = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            _isTimeCapsule
                ? 'Seal this time capsule?'
                : 'Seal this letter?',
          ),
          content: Text(
            _isTimeCapsule
                ? 'These words for $recipientLabel will stay locked until ${_formatDate(_openDate!)}.'
                : 'Your letter to ${person.name} will be placed in their keepsake.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Writing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                _isTimeCapsule ? 'Seal Capsule' : 'Seal Letter',
              ),
            ),
          ],
        );
      },
    );

    if (shouldSeal != true || !mounted) {
      return;
    }

    final deliveryJourney = await Navigator.push<DeliveryJourney>(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryMethodScreen(
          recipientName: person.name,
          initialDestinationCountry: 'Uruguay',
          initialJourney: widget.initialLetter?.deliveryJourney,
        ),
      ),
    );

    if (deliveryJourney == null || !mounted) {
      return;
    }

    final body = _letterController.text.trim();
    final now = DateTime.now();
    final existingLetter = widget.initialLetter;
    final letterId = existingLetter?.id ?? _createLetterId();

    setState(() {
      _isSaving = true;
    });

    try {
      final photoUrls = await _uploadPendingPhotos(letterId);

      Letter? firstSealedLetter;

      for (var index = 0; index < recipients.length; index++) {
        final recipient = recipients[index];
        final recipientLetterId = recipients.length == 1
            ? letterId
            : '${letterId}_${recipient.personKey}';

        final sealedLetter = Letter(
          id: recipientLetterId,
          personKey: _personKey(recipient),
          recipientName: recipient.name,
          recipientRelationship: recipient.relationship,
          title: _resolvedTitle(body: body, isDraft: false),
          body: body,
          createdAt: existingLetter?.createdAt ?? now,
          updatedAt: now,
          isDraft: false,
          isFavorite: existingLetter?.isFavorite ?? false,
          isTimeCapsule: _isTimeCapsule,
          openDate: _isTimeCapsule ? _openDate : null,
          capsuleAccessMode: _isTimeCapsule
              ? _capsuleAccessMode
              : CapsuleAccessMode.onlyMe,
          authorizedPersonKeys: _isTimeCapsule
              ? recipients.map((item) => item.personKey).toList()
              : const [],
          authorizedPersonNames: _isTimeCapsule
              ? recipients.map((item) => item.name).toList()
              : const [],
          letterType: _selectedLetterType ?? LetterType.typed,
          photoPaths: photoUrls,
          deliveryJourney: deliveryJourney,
        );

        firstSealedLetter ??= sealedLetter;
        await LetterService.instance.saveLetter(sealedLetter);
      }

      final sealedLetter = firstSealedLetter!;
      await _deleteRemovedRemotePhotos();

      if (!mounted) {
        return;
      }

      setState(() {
        _hasSaved = true;
        _isSaving = false;
      });

      _showMessage(
        _isEditing
            ? 'Your changes were saved.'
            : _isTimeCapsule
                ? recipients.length == 1
                    ? '“${sealedLetter.title}” was sealed for ${recipients.first.name} until ${_formatDate(_openDate!)}.'
                    : '“${sealedLetter.title}” was sealed for ${recipients.length} people until ${_formatDate(_openDate!)}.'
                : deliveryJourney.mode == DeliveryMode.postalJourney
                    ? '“${sealedLetter.title}” has begun its journey to ${person.name}.'
                    : '“${sealedLetter.title}” was delivered to ${person.name}.',
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage('We could not save your letter or upload its photos.');
    }
  }

  Future<bool> _confirmLeaving() async {
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _letterController.text.trim().isNotEmpty ||
        _photoPaths.isNotEmpty;

    if (!hasContent || _hasSaved) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Leave this letter?'),
          content: const Text(
            'Your unfinished words and attached memories have not been saved yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Writing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    return shouldLeave ?? false;
  }

  Future<void> _handleBack() async {
    final canLeave = await _confirmLeaving();

    if (canLeave && mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _chooseLetterType(LetterType type) {
    setState(() {
      _selectedLetterType = type;
    });
  }

  void _returnToLetterTypeSelector() {
    if (_isEditing) {
      return;
    }

    setState(() {
      _selectedLetterType = null;
    });
  }

  String _letterTypeTitle(LetterType type) {
    switch (type) {
      case LetterType.typed:
        return 'Type a Letter';
      case LetterType.handwritten:
        return 'Write by Hand';
      case LetterType.scanned:
        return 'Scan a Letter';
      case LetterType.postcard:
        return 'Create a Postcard';
    }
  }

  String _letterTypeDescription(LetterType type) {
    switch (type) {
      case LetterType.typed:
        return 'Write with the keyboard and add memories.';
      case LetterType.handwritten:
        return 'Use your finger, stylus, or pencil on the screen.';
      case LetterType.scanned:
        return 'Photograph handwritten pages and preserve them in order.';
      case LetterType.postcard:
        return 'Pair one special image with a short personal message.';
    }
  }

  IconData _letterTypeIcon(LetterType type) {
    switch (type) {
      case LetterType.typed:
        return Icons.keyboard_alt_outlined;
      case LetterType.handwritten:
        return Icons.draw_outlined;
      case LetterType.scanned:
        return Icons.document_scanner_outlined;
      case LetterType.postcard:
        return Icons.photo_size_select_actual_outlined;
    }
  }

  Widget _buildLetterTypeSelector(BuildContext context) {
    final types = LetterType.values;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Write a Letter'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How would you like to write today?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose the form that feels most natural. Every kind of letter belongs in the keepsake.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.softGrey,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _LetterTypeCard(
                title: 'Create a Time Capsule',
                description:
                    'Write words for one or more people and choose the day they may be opened.',
                icon: Icons.lock_clock_rounded,
                isReady: true,
                onTap: () async {
                  _chooseLetterType(LetterType.typed);
                  await Future<void>.delayed(Duration.zero);
                  if (mounted) {
                    await _openTimeCapsuleCreator();
                  }
                },
              ),
              const SizedBox(height: 14),
              for (final type in types) ...[
                _LetterTypeCard(
                  title: _letterTypeTitle(type),
                  description: _letterTypeDescription(type),
                  icon: _letterTypeIcon(type),
                  isReady: true,
                  onTap: () => _chooseLetterType(type),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonScreen(
    BuildContext context,
    LetterType type,
  ) {
    final isEditingThisType =
        _isEditing && widget.initialLetter?.letterType == type;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          onPressed: isEditingThisType
              ? _handleBack
              : _returnToLetterTypeSelector,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(_letterTypeTitle(type)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(26, 34, 26, 32),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      _letterTypeIcon(type),
                      size: 40,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _letterTypeTitle(type),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _letterTypeDescription(type),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.softGrey,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'This writing experience is the next piece we are building.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!isEditingThisType) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _returnToLetterTypeSelector,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Choose Another Way'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = _selectedLetterType;

    if (selectedType == null) {
      return _buildLetterTypeSelector(context);
    }

    if (selectedType == LetterType.handwritten) {
      return HandwrittenLetterScreen(
        initialPerson: widget.initialPerson,
        availablePeople: widget.availablePeople,
        initialLetter: widget.initialLetter,
      );
    }

    if (selectedType == LetterType.scanned) {
      return ScannedLetterScreen(
        initialPerson: widget.initialPerson,
        availablePeople: widget.availablePeople,
        initialLetter: widget.initialLetter,
      );
    }

    if (selectedType == LetterType.postcard) {
      return PostcardLetterScreen(
        initialPerson: widget.initialPerson,
        availablePeople: widget.availablePeople,
        initialLetter: widget.initialLetter,
      );
    }

    final person = _selectedPerson;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: IconButton(
            onPressed: _isSaving ? null : _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text(_isEditing ? 'Edit Letter' : 'Write a Letter'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RecipientCard(
                        person: person,
                        onTap: _isSaving ? null : _choosePerson,
                      ),
                      const SizedBox(height: 12),
                      _TimeCapsuleEntryCard(
                        enabled: !_isSaving,
                        isConfigured: _isTimeCapsule &&
                            _openDate != null &&
                            _capsuleRecipients.isNotEmpty,
                        openDate: _openDate,
                        recipientNames: _capsuleRecipients
                            .map((item) => item.name)
                            .toList(),
                        onTap: _openTimeCapsuleCreator,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _titleController,
                          enabled: !_isSaving,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Give this letter a title',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        constraints:
                            const BoxConstraints(minHeight: 390),
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          24,
                          22,
                          24,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person == null
                                  ? 'Dear...'
                                  : 'Dear ${person.name},',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.terracotta,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _letterController,
                              enabled: !_isSaving,
                              autofocus: person != null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              minLines: 12,
                              maxLines: null,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(height: 1.65),
                              decoration: const InputDecoration(
                                hintText:
                                    'Write what you would like them to keep...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _MemoryArea(
                        photoPaths: _photoPaths,
                        isLoading: _isAddingPhotos,
                        onAdd: _isSaving
                            ? null
                            : _showPhotoSourcePicker,
                        onRemove: _isSaving ? null : _removePhoto,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _saveDraft,
                        child: const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSaving ? null : _sealLetter,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isTimeCapsule
                                    ? Icons.lock_clock_outlined
                                    : Icons.mark_email_read_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : _isEditing
                                  ? 'Save Changes'
                                  : _isTimeCapsule
                                      ? 'Seal Capsule'
                                      : 'Seal Letter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _TimeCapsuleEntryCard extends StatelessWidget {
  final bool enabled;
  final bool isConfigured;
  final DateTime? openDate;
  final List<String> recipientNames;
  final VoidCallback onTap;

  const _TimeCapsuleEntryCard({
    required this.enabled,
    required this.isConfigured,
    required this.openDate,
    required this.recipientNames,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = isConfigured
        ? '${recipientNames.join(' • ')}  ·  Opens ${_formatDate(openDate!)}'
        : 'Choose an opening date and add one or more people.';

    return Material(
      color: isConfigured ? AppColors.cream : AppColors.paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConfigured
                  ? AppColors.terracotta
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isConfigured
                      ? Icons.lock_clock_rounded
                      : Icons.auto_awesome_rounded,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfigured
                          ? 'Time capsule ready'
                          : 'Create a time capsule',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.softGrey,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.terracotta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isReady;
  final VoidCallback onTap;

  const _LetterTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  icon,
                  color: AppColors.terracotta,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (!isReady)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'Next',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.terracotta,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.softGrey,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.softGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final Person? person;
  final VoidCallback? onTap;

  const _RecipientCard({
    required this.person,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPerson = person;

    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: selectedPerson == null
              ? Row(
                  children: [
                    const _CircleSymbol(
                      child: Icon(
                        Icons.person_add_alt_1_outlined,
                        color: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose someone',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Who are these words for?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.softGrey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.softGrey,
                    ),
                  ],
                )
              : Row(
                  children: [
                    BotanicalPersonIcon(
                      symbol: selectedPerson.symbol,
                      size: 58,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedPerson.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          if (selectedPerson
                              .relationship.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              selectedPerson.relationship,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.softGrey,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.softGrey,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CircleSymbol extends StatelessWidget {
  final Widget child;

  const _CircleSymbol({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _MemoryArea extends StatelessWidget {
  final List<String> photoPaths;
  final bool isLoading;
  final VoidCallback? onAdd;
  final Future<void> Function(String path)? onRemove;

  const _MemoryArea({
    required this.photoPaths,
    required this.isLoading,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPaths.isEmpty) {
      return OutlinedButton(
        onPressed: isLoading ? null : onAdd,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.terracotta,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading
                        ? 'Adding memories...'
                        : 'Add a Memory',
                    style:
                        Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Photos can become part of this letter.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: AppColors.softGrey,
                        ),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              const Icon(Icons.add_rounded),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_outlined,
                color: AppColors.terracotta,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${photoPaths.length} '
                  '${photoPaths.length == 1 ? 'memory' : 'memories'} attached',
                  style:
                      Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : onAdd,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoPaths.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final path = photoPaths[index];

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _MemoryImage(path: path),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onRemove == null
                              ? null
                              : () => onRemove!(path),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _MemoryImage extends StatelessWidget {
  final String path;

  const _MemoryImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(path);
    final isRemote = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http');

    Widget errorPlaceholder() {
      return Container(
        width: 112,
        height: 112,
        color: AppColors.cream,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.softGrey,
        ),
      );
    }

    if (isRemote) {
      return Image.network(
        path,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => errorPlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 112,
            height: 112,
            color: AppColors.cream,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return Image.file(
      File(path),
      width: 112,
      height: 112,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => errorPlaceholder(),
    );
  }
}

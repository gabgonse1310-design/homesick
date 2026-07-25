import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/mock_people.dart';
import '../models/letter.dart';
import '../models/person.dart';
import '../services/letter_service.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';

class PostcardLetterScreen extends StatefulWidget {
  final Person? initialPerson;
  final List<Person>? availablePeople;
  final Letter? initialLetter;

  const PostcardLetterScreen({
    super.key,
    this.initialPerson,
    this.availablePeople,
    this.initialLetter,
  });

  @override
  State<PostcardLetterScreen> createState() => _PostcardLetterScreenState();
}

class _PostcardLetterScreenState extends State<PostcardLetterScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  late final List<Person> _people;
  Person? _selectedPerson;
  String? _imagePath;
  bool _showBack = false;
  bool _isSaving = false;
  bool _isTimeCapsule = false;
  DateTime? _openDate;

  @override
  void initState() {
    super.initState();
    _people = widget.availablePeople ?? mockPeople;
    _selectedPerson = widget.initialPerson;
    final initial = widget.initialLetter;
    if (initial != null) {
      _titleController.text = initial.title;
      _messageController.text = initial.body;
      _imagePath = initial.postcardImagePath;
      _isTimeCapsule = initial.isTimeCapsule;
      _openDate = initial.openDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _personKey(Person person) =>
      '${person.name.trim().toLowerCase()}_${person.relationship.trim().toLowerCase()}';

  bool _isRemote(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _choosePerson() async {
    final person = await showModalBottomSheet<Person>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: ListView.separated(
            padding: const EdgeInsets.all(22),
            itemCount: _people.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final person = _people[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: BotanicalPersonIcon(symbol: person.symbol, size: 45),
                title: Text(person.name),
                subtitle: Text(person.relationship),
                onTap: () => Navigator.pop(context, person),
              );
            },
          ),
        ),
      ),
    );
    if (person != null && mounted) setState(() => _selectedPerson = person);
  }

  Future<void> _chooseImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 92);
    if (image != null && mounted) setState(() => _imagePath = image.path);
  }

  Future<void> _chooseOpenDate() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _openDate ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 30),
    );
    if (chosen != null && mounted) setState(() => _openDate = chosen);
  }

  Future<void> _save({required bool isDraft}) async {
    if (_isSaving) return;
    if (_selectedPerson == null) {
      _message('Please choose who this postcard is for.');
      return;
    }
    if (_imagePath == null || _imagePath!.isEmpty) {
      _message('Choose a photograph for the postcard.');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _message('Write a short postcard message.');
      return;
    }
    if (_isTimeCapsule && _openDate == null) {
      _message('Choose when the time capsule should open.');
      return;
    }

    setState(() => _isSaving = true);
    final existing = widget.initialLetter;
    final id = existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    try {
      final imageUrl = _isRemote(_imagePath!)
          ? _imagePath!
          : await PhotoStorageService.instance.uploadPhoto(
              letterId: id,
              localPath: _imagePath!,
            );
      final person = _selectedPerson!;
      final enteredTitle = _titleController.text.trim();
      final letter = Letter(
        id: id,
        personKey: _personKey(person),
        recipientName: person.name,
        recipientRelationship: person.relationship,
        title: enteredTitle.isEmpty
            ? (isDraft ? 'Untitled Postcard' : 'A postcard for ${person.name}')
            : enteredTitle,
        body: _messageController.text.trim(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        isDraft: isDraft,
        isFavorite: existing?.isFavorite ?? false,
        isTimeCapsule: _isTimeCapsule,
        openDate: _isTimeCapsule ? _openDate : null,
        letterType: LetterType.postcard,
        postcardImagePath: imageUrl,
        photoPaths: existing?.photoPaths ?? const [],
      );
      await LetterService.instance.saveLetter(letter);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        _message('We could not upload or save the postcard.');
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _postcardImage() {
    final path = _imagePath;
    if (path == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 48, color: AppColors.terracotta),
            SizedBox(height: 8),
            Text('Choose the postcard photograph'),
          ],
        ),
      );
    }
    return _isRemote(path)
        ? Image.network(path, fit: BoxFit.cover, width: double.infinity)
        : Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: const Text('Create a Postcard'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _isSaving ? null : _choosePerson,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                color: AppColors.terracotta),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_selectedPerson == null
                                  ? 'Choose recipient'
                                  : '${_selectedPerson!.name} · ${_selectedPerson!.relationship}'),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Postcard title',
                        hintText: 'Greetings from Pretoria',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : () => _chooseImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : () => _chooseImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Front'), icon: Icon(Icons.photo_outlined)),
                        ButtonSegment(value: true, label: Text('Back'), icon: Icon(Icons.mail_outline_rounded)),
                      ],
                      selected: {_showBack},
                      onSelectionChanged: (value) => setState(() => _showBack = value.first),
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: AspectRatio(
                        key: ValueKey(_showBack),
                        aspectRatio: 1.48,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _showBack
                              ? Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: _messageController,
                                          maxLines: null,
                                          expands: true,
                                          textAlignVertical: TextAlignVertical.top,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: _selectedPerson == null
                                                ? 'Dear...\n\nWrite your message here.'
                                                : 'Dear ${_selectedPerson!.name},\n\nWrite your message here.',
                                          ),
                                        ),
                                      ),
                                      const VerticalDivider(width: 30),
                                      const Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: Icon(Icons.local_post_office_outlined,
                                                  size: 40, color: AppColors.terracotta),
                                            ),
                                            Spacer(),
                                            Divider(),
                                            SizedBox(height: 18),
                                            Divider(),
                                            SizedBox(height: 18),
                                            Divider(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _postcardImage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Make this a time capsule'),
                      subtitle: const Text('Keep the postcard locked until a future date.'),
                      value: _isTimeCapsule,
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() {
                                _isTimeCapsule = value;
                                if (!value) _openDate = null;
                              }),
                    ),
                    if (_isTimeCapsule)
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _chooseOpenDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(_openDate == null
                            ? 'Choose opening date'
                            : '${_openDate!.day}/${_openDate!.month}/${_openDate!.year}'),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _save(isDraft: true),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _save(isDraft: false),
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_read_outlined),
                      label: Text(_isTimeCapsule ? 'Seal Capsule' : 'Seal Postcard'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

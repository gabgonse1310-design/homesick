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

class ScannedLetterScreen extends StatefulWidget {
  final Person? initialPerson;
  final List<Person>? availablePeople;
  final Letter? initialLetter;

  const ScannedLetterScreen({
    super.key,
    this.initialPerson,
    this.availablePeople,
    this.initialLetter,
  });

  @override
  State<ScannedLetterScreen> createState() => _ScannedLetterScreenState();
}

class _ScannedLetterScreenState extends State<ScannedLetterScreen> {
  final _titleController = TextEditingController();
  final _picker = ImagePicker();
  late final List<Person> _people;
  Person? _selectedPerson;
  final List<String> _pagePaths = [];
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
      _pagePaths.addAll(initial.pages.map((page) => page.imagePath));
      _isTimeCapsule = initial.isTimeCapsule;
      _openDate = initial.openDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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

  Future<void> _addFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (image != null && mounted) setState(() => _pagePaths.add(image.path));
  }

  Future<void> _addFromGallery() async {
    final images = await _picker.pickMultiImage(imageQuality: 92);
    if (images.isNotEmpty && mounted) {
      setState(() => _pagePaths.addAll(images.map((image) => image.path)));
    }
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
      _message('Please choose who this letter is for.');
      return;
    }
    if (_pagePaths.isEmpty) {
      _message('Add at least one scanned page.');
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
      final uploaded = <String>[];
      for (final path in _pagePaths) {
        if (_isRemote(path)) {
          uploaded.add(path);
        } else {
          uploaded.add(await PhotoStorageService.instance.uploadPhoto(
            letterId: id,
            localPath: path,
          ));
        }
      }

      final person = _selectedPerson!;
      final title = _titleController.text.trim();
      final letter = Letter(
        id: id,
        personKey: _personKey(person),
        recipientName: person.name,
        recipientRelationship: person.relationship,
        title: title.isEmpty
            ? (isDraft ? 'Untitled Draft' : 'A scanned letter')
            : title,
        body: '',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        isDraft: isDraft,
        isFavorite: existing?.isFavorite ?? false,
        isTimeCapsule: _isTimeCapsule,
        openDate: _isTimeCapsule ? _openDate : null,
        letterType: LetterType.scanned,
        pages: [
          for (var i = 0; i < uploaded.length; i++)
            LetterPage(
              id: '${id}_page_$i',
              type: LetterPageType.scanned,
              imagePath: uploaded[i],
              pageNumber: i,
              createdAt: now,
            ),
        ],
        photoPaths: existing?.photoPaths ?? const [],
      );

      await LetterService.instance.saveLetter(letter);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        _message('We could not upload or save the scanned letter.');
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _pageImage(String path) {
    final image = _isRemote(path)
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: const Text('Scan a Letter'),
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
                              child: Text(
                                _selectedPerson == null
                                    ? 'Choose recipient'
                                    : '${_selectedPerson!.name} · ${_selectedPerson!.relationship}',
                              ),
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
                        labelText: 'Letter title',
                        hintText: 'A letter from home',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Pages', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Photograph each page or choose existing photos. Hold and drag to reorder.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.softGrey,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _addFromCamera,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _addFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_pagePaths.isEmpty)
                      Container(
                        height: 220,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.document_scanner_outlined,
                                size: 48, color: AppColors.terracotta),
                            SizedBox(height: 10),
                            Text('Your scanned pages will appear here'),
                          ],
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pagePaths.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _pagePaths.removeAt(oldIndex);
                            _pagePaths.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final path = _pagePaths[index];
                          return Container(
                            key: ValueKey('$path-$index'),
                            height: 170,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 115, child: _pageImage(path)),
                                const SizedBox(width: 14),
                                Expanded(child: Text('Page ${index + 1}')),
                                IconButton(
                                  onPressed: () => setState(() => _pagePaths.removeAt(index)),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                                const Icon(Icons.drag_handle_rounded),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 18),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Make this a time capsule'),
                      subtitle: const Text('Keep the pages locked until a future date.'),
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
                        label: Text(
                          _openDate == null
                              ? 'Choose opening date'
                              : '${_openDate!.day}/${_openDate!.month}/${_openDate!.year}',
                        ),
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
                      label: Text(_isTimeCapsule ? 'Seal Capsule' : 'Seal Letter'),
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

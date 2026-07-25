import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../data/mock_people.dart';
import '../models/letter.dart';
import '../models/person.dart';
import '../services/letter_service.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';
import '../widgets/time_capsule_card.dart';

class HandwrittenLetterScreen extends StatefulWidget {
  final Person? initialPerson;
  final List<Person>? availablePeople;
  final Letter? initialLetter;

  const HandwrittenLetterScreen({
    super.key,
    this.initialPerson,
    this.availablePeople,
    this.initialLetter,
  });

  @override
  State<HandwrittenLetterScreen> createState() =>
      _HandwrittenLetterScreenState();
}

class _HandwrittenLetterScreenState extends State<HandwrittenLetterScreen> {
  final TextEditingController _titleController = TextEditingController();
  final PageController _pageController = PageController();

  final List<_DrawingPage> _pages = [];
  Person? _selectedPerson;
  int _currentPage = 0;
  bool _isSaving = false;
  bool _hasSaved = false;

  _InkTool _tool = _InkTool.pen;
  double _strokeWidth = 3.0;
  Color _inkColor = const Color(0xFF2F2A26);

  bool _isTimeCapsule = false;
  DateTime? _openDate;
  String _capsuleAccessMode = CapsuleAccessMode.onlyMe;
  final List<String> _authorizedPersonKeys = [];

  List<Person> get _people => widget.availablePeople ?? mockPeople;
  bool get _isEditing => widget.initialLetter != null;

  static const List<Color> _inkColors = [
    Color(0xFF2F2A26),
    Color(0xFF243B61),
    Color(0xFF6E4B35),
    Color(0xFF294D3B),
    Color(0xFF6D2E3C),
  ];

  @override
  void initState() {
    super.initState();
    final initialLetter = widget.initialLetter;
    _selectedPerson = widget.initialPerson;

    if (initialLetter != null) {
      _titleController.text = initialLetter.title;
      _isTimeCapsule = initialLetter.isTimeCapsule;
      _openDate = initialLetter.openDate;
      _capsuleAccessMode = initialLetter.capsuleAccessMode;
      _authorizedPersonKeys.addAll(initialLetter.authorizedPersonKeys);

      final sortedPages = List<LetterPage>.from(initialLetter.pages)
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      for (final page in sortedPages) {
        _pages.add(_DrawingPage(backgroundPath: page.imagePath));
      }
    }

    if (_pages.isEmpty) {
      _pages.add(_DrawingPage());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _personKey(Person person) {
    return '${person.name.trim().toLowerCase()}::'
        '${person.relationship.trim().toLowerCase()}';
  }

  List<String> _authorizedPersonNames() {
    return _people
        .where((person) => _authorizedPersonKeys.contains(_personKey(person)))
        .map((person) => person.name)
        .toList();
  }

  Future<void> _choosePerson() async {
    if (_people.isEmpty) {
      _showMessage('Add someone before writing a letter.');
      return;
    }

    final selected = await showModalBottomSheet<Person>(
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
                const SizedBox(height: 20),
                Text(
                  'Who are you writing to?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _people.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final person = _people[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: AppColors.border),
                        ),
                        leading: BotanicalPersonIcon(
                          symbol: person.symbol,
                          size: 46,
                        ),
                        title: Text(person.name),
                        subtitle: person.relationship.isEmpty
                            ? null
                            : Text(person.relationship),
                        onTap: () => Navigator.pop(context, person),
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

    if (selected != null && mounted) {
      setState(() => _selectedPerson = selected);
    }
  }

  void _startStroke(int pageIndex, Offset point) {
    final page = _pages[pageIndex];
    final color = _tool == _InkTool.eraser ? AppColors.paper : _inkColor;
    final width = _tool == _InkTool.marker
        ? _strokeWidth * 2.6
        : _tool == _InkTool.pencil
            ? _strokeWidth * 0.75
            : _strokeWidth;

    setState(() {
      page.redoStack.clear();
      page.strokes.add(
        _Stroke(
          points: [point],
          color: color,
          width: width,
          opacity: _tool == _InkTool.pencil
              ? 0.48
              : _tool == _InkTool.marker
                  ? 0.32
                  : 1,
        ),
      );
    });
  }

  void _continueStroke(int pageIndex, Offset point) {
    final page = _pages[pageIndex];
    if (page.strokes.isEmpty) return;

    setState(() {
      page.strokes.last.points.add(point);
    });
  }

  void _undo() {
    final page = _pages[_currentPage];
    if (page.strokes.isEmpty) return;
    setState(() => page.redoStack.add(page.strokes.removeLast()));
  }

  void _redo() {
    final page = _pages[_currentPage];
    if (page.redoStack.isEmpty) return;
    setState(() => page.strokes.add(page.redoStack.removeLast()));
  }

  void _addPage() {
    setState(() {
      _pages.add(_DrawingPage());
      _currentPage = _pages.length - 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _removeCurrentPage() async {
    if (_pages.length == 1) {
      setState(() {
        _pages.first.strokes.clear();
        _pages.first.redoStack.clear();
        _pages.first.backgroundPath = null;
      });
      return;
    }

    setState(() {
      _pages.removeAt(_currentPage);
      _currentPage = _currentPage.clamp(0, _pages.length - 1);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  Future<String> _exportPage(_DrawingPage page, int index) async {
    final boundary = page.boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary == null) {
      throw StateError('The handwritten page is not ready to export.');
    }

    final image = await boundary.toImage(pixelRatio: 2.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('The handwritten page could not be exported.');
    }

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/handwritten_${DateTime.now().microsecondsSinceEpoch}_$index.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  bool _pageHasContent(_DrawingPage page) {
    return page.strokes.isNotEmpty ||
        (page.backgroundPath != null && page.backgroundPath!.isNotEmpty);
  }

  Future<void> _saveLetter({required bool isDraft}) async {
    if (_isSaving) return;
    if (_selectedPerson == null) {
      _showMessage('Please choose who this letter is for.');
      return;
    }

    final contentPages = _pages.where(_pageHasContent).toList();
    if (contentPages.isEmpty) {
      _showMessage('Your handwritten letter is still empty.');
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

    final person = _selectedPerson!;
    final existing = widget.initialLetter;
    final letterId =
        existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    setState(() => _isSaving = true);

    try {
      final pageModels = <LetterPage>[];

      for (var index = 0; index < contentPages.length; index++) {
        final localPath = await _exportPage(contentPages[index], index);
        final remoteUrl = await PhotoStorageService.instance.uploadPhoto(
          letterId: letterId,
          localPath: localPath,
        );

        pageModels.add(
          LetterPage(
            id: '${letterId}_page_$index',
            type: LetterPageType.handwritten,
            imagePath: remoteUrl,
            pageNumber: index,
            createdAt: now,
          ),
        );
      }

      final enteredTitle = _titleController.text.trim();
      final letter = Letter(
        id: letterId,
        personKey: _personKey(person),
        recipientName: person.name,
        recipientRelationship: person.relationship,
        title: enteredTitle.isEmpty
            ? (isDraft ? 'Untitled Draft' : 'A handwritten letter')
            : enteredTitle,
        body: '',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        isDraft: isDraft,
        isFavorite: existing?.isFavorite ?? false,
        isTimeCapsule: _isTimeCapsule,
        openDate: _isTimeCapsule ? _openDate : null,
        capsuleAccessMode: _isTimeCapsule
            ? _capsuleAccessMode
            : CapsuleAccessMode.onlyMe,
        authorizedPersonKeys: _isTimeCapsule
            ? List<String>.from(_authorizedPersonKeys)
            : const [],
        authorizedPersonNames:
            _isTimeCapsule ? _authorizedPersonNames() : const [],
        letterType: LetterType.handwritten,
        pages: pageModels,
        photoPaths: existing?.photoPaths ?? const [],
      );

      await LetterService.instance.saveLetter(letter);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasSaved = true;
      });

      _showMessage(
        isDraft
            ? 'Your handwritten draft was saved.'
            : _isTimeCapsule
                ? 'Your handwritten time capsule was sealed.'
                : 'Your handwritten letter was sealed for ${person.name}.',
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('We could not save the handwritten pages.');
    }
  }

  Future<void> _handleBack() async {
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _pages.any(_pageHasContent);

    if (!hasContent || _hasSaved) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('Leave this letter?'),
        content: const Text('Your unsaved handwriting will be lost.'),
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
      ),
    );

    if (leave == true && mounted) Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildRecipientCard() {
    final person = _selectedPerson;
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _isSaving ? null : _choosePerson,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (person == null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: AppColors.terracotta,
                  ),
                )
              else
                BotanicalPersonIcon(symbol: person.symbol, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person == null ? 'Choose a person' : person.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      person == null
                          ? 'Who will keep these words?'
                          : person.relationship,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.softGrey,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required _InkTool tool,
    required IconData icon,
    required String label,
  }) {
    final selected = _tool == tool;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => setState(() => _tool = tool),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.terracotta : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: selected ? AppColors.terracotta : AppColors.softGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasPage(int index) {
    final page = _pages[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: RepaintBoundary(
        key: page.boundaryKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: AppColors.paper,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (page.backgroundPath != null)
                  _PageBackground(path: page.backgroundPath!),
                CustomPaint(
                  painter: _HandwritingPainter(page.strokes),
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) =>
                        _startStroke(index, event.localPosition),
                    onPointerMove: (event) =>
                        _continueStroke(index, event.localPosition),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
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
          title: Text(_isEditing ? 'Edit Handwritten Letter' : 'Write by Hand'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRecipientCard(),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _titleController,
                          enabled: !_isSaving,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Give this letter a title',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _undo,
                                  tooltip: 'Undo',
                                  icon: const Icon(Icons.undo_rounded),
                                ),
                                IconButton(
                                  onPressed: _redo,
                                  tooltip: 'Redo',
                                  icon: const Icon(Icons.redo_rounded),
                                ),
                                const Spacer(),
                                Text(
                                  'Page ${_currentPage + 1} of ${_pages.length}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                IconButton(
                                  onPressed: _isSaving ? null : _removeCurrentPage,
                                  tooltip: 'Remove page',
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildToolButton(
                                  tool: _InkTool.pen,
                                  icon: Icons.edit_rounded,
                                  label: 'Pen',
                                ),
                                _buildToolButton(
                                  tool: _InkTool.pencil,
                                  icon: Icons.mode_edit_outline_outlined,
                                  label: 'Pencil',
                                ),
                                _buildToolButton(
                                  tool: _InkTool.marker,
                                  icon: Icons.border_color_outlined,
                                  label: 'Marker',
                                ),
                                _buildToolButton(
                                  tool: _InkTool.eraser,
                                  icon: Icons.auto_fix_normal_outlined,
                                  label: 'Eraser',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.line_weight_rounded, size: 20),
                                Expanded(
                                  child: Slider(
                                    min: 1.5,
                                    max: 9,
                                    value: _strokeWidth,
                                    onChanged: (value) =>
                                        setState(() => _strokeWidth = value),
                                  ),
                                ),
                                for (final color in _inkColors)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 7),
                                    child: InkWell(
                                      onTap: () => setState(() {
                                        _inkColor = color;
                                        if (_tool == _InkTool.eraser) {
                                          _tool = _InkTool.pen;
                                        }
                                      }),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 25,
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _inkColor == color
                                                ? AppColors.terracotta
                                                : AppColors.border,
                                            width: _inkColor == color ? 3 : 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 540,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) =>
                              _buildCanvasPage(index),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _addPage,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Another Page'),
                      ),
                      const SizedBox(height: 18),
                      TimeCapsuleCard(
                        isTimeCapsule: _isTimeCapsule,
                        openDate: _openDate,
                        recipient: _selectedPerson,
                        availablePeople: _people,
                        accessMode: _capsuleAccessMode,
                        authorizedPersonKeys: _authorizedPersonKeys,
                        enabled: !_isSaving,
                        onTypeChanged: (value) {
                          setState(() {
                            _isTimeCapsule = value;
                            if (!value) {
                              _openDate = null;
                              _capsuleAccessMode = CapsuleAccessMode.onlyMe;
                              _authorizedPersonKeys.clear();
                            }
                          });
                        },
                        onDateChanged: (date) =>
                            setState(() => _openDate = date),
                        onAccessModeChanged: (mode) {
                          setState(() {
                            _capsuleAccessMode = mode;
                            if (mode != CapsuleAccessMode.trustedPeople) {
                              _authorizedPersonKeys.clear();
                            }
                          });
                        },
                        onAuthorizedPeopleChanged: (keys) {
                          setState(() {
                            _authorizedPersonKeys
                              ..clear()
                              ..addAll(keys);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 13, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _saveLetter(isDraft: true),
                        child: const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveLetter(isDraft: false),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isTimeCapsule
                                    ? Icons.lock_clock_outlined
                                    : Icons.mark_email_read_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
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

enum _InkTool { pen, pencil, marker, eraser }

class _DrawingPage {
  _DrawingPage({this.backgroundPath});

  final GlobalKey boundaryKey = GlobalKey();
  final List<_Stroke> strokes = [];
  final List<_Stroke> redoStack = [];
  String? backgroundPath;
}

class _Stroke {
  _Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final double opacity;
}

class _HandwritingPainter extends CustomPainter {
  const _HandwritingPainter(this.strokes);

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: stroke.opacity)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
        continue;
      }

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var index = 1; index < stroke.points.length; index++) {
        final previous = stroke.points[index - 1];
        final current = stroke.points[index];
        final midpoint = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(previous.dx, previous.dy, midpoint.dx, midpoint.dy);
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) => true;
}

class _PageBackground extends StatelessWidget {
  final String path;

  const _PageBackground({required this.path});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(path);
    final isRemote = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http');

    return isRemote
        ? Image.network(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);
  }
}

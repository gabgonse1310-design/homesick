import 'dart:io';

import 'package:flutter/material.dart';

import '../models/letter.dart';
import '../models/person.dart';
import '../services/letter_storage_service.dart';
import '../theme/app_theme.dart';
import 'write_letter_screen.dart';

class ReadLetterScreen extends StatefulWidget {
  final Letter? letter;
  final Person? person;
  final List<Person>? availablePeople;
  final bool isIncoming;
  final String? senderName;

  const ReadLetterScreen({
    super.key,
    this.letter,
    this.person,
    this.availablePeople,
    this.isIncoming = false,
    this.senderName,
  });

  @override
  State<ReadLetterScreen> createState() => _ReadLetterScreenState();
}

class _ReadLetterScreenState extends State<ReadLetterScreen> {
  late Letter? _letter;
  bool _isUpdating = false;

  bool get _isIncoming =>
      widget.isIncoming || (_letter?.isIncoming ?? false);

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
  }

  Future<void> _toggleFavorite() async {
    final currentLetter = _letter;

    if (currentLetter == null || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final newFavoriteValue = !currentLetter.isFavorite;

      await LetterStorageService.instance.setFavorite(
        id: currentLetter.id,
        isFavorite: newFavoriteValue,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _letter = currentLetter.copyWith(
          isFavorite: newFavoriteValue,
          updatedAt: DateTime.now(),
        );
        _isUpdating = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not update this letter.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteLetter() async {
    final currentLetter = _letter;

    if (currentLetter == null || _isUpdating) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            currentLetter.isDraft
                ? 'Remove this draft?'
                : 'Remove this letter?',
          ),
          content: Text(
            currentLetter.isDraft
                ? 'This unfinished letter will be removed permanently.'
                : 'This letter will be removed from the keepsake permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep It'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await LetterStorageService.instance.deleteLetter(currentLetter.id);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not remove this letter.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editLetter() async {
    final currentLetter = _letter;
    final person = widget.person;

    if (currentLetter == null || person == null || _isUpdating) {
      return;
    }

    if (currentLetter.isTimeCapsule &&
        !currentLetter.canOpen &&
        !currentLetter.isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A sealed time capsule cannot be edited before it opens.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WriteLetterScreen(
          initialPerson: person,
          availablePeople: widget.availablePeople,
          initialLetter: currentLetter,
        ),
      ),
    );

    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = _letter;

    if (letter == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('Read Letter'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No letter was selected.\nOpen a letter from a person’s keepsake.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isLocked = letter.isTimeCapsule && !letter.canOpen;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: _isIncoming
            ? const []
            : [
          if (!isLocked && widget.person != null)
            IconButton(
              onPressed: _isUpdating ? null : _editLetter,
              tooltip: letter.isDraft
                  ? 'Continue writing'
                  : 'Edit letter',
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            onPressed: _isUpdating ? null : _toggleFavorite,
            tooltip: letter.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            icon: Icon(
              letter.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: letter.isFavorite
                  ? AppColors.terracotta
                  : null,
            ),
          ),
          PopupMenuButton<String>(
            enabled: !_isUpdating,
            onSelected: (value) {
              if (value == 'delete') {
                _deleteLetter();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded),
                    const SizedBox(width: 10),
                    Text(
                      letter.isDraft
                          ? 'Remove draft'
                          : 'Remove letter',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: isLocked
            ? _buildLockedLetter(context, letter)
            : _buildReadableLetter(context, letter),
      ),
    );
  }

  Widget _buildLockedLetter(
    BuildContext context,
    Letter letter,
  ) {
    final openDate = letter.openDate;
    final countdown = openDate == null
        ? 'Opening date unavailable'
        : _countdownText(openDate);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 32, 26, 30),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.94, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 102,
                  height: 102,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.markunread_mailbox_outlined,
                        size: 45,
                        color: AppColors.terracotta,
                      ),
                      Positioned(
                        right: 18,
                        bottom: 17,
                        child: Container(
                          width: 31,
                          height: 31,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'A memory is waiting...',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Some words were written for another time.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.softGrey,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'OPENS ON',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      openDate == null
                          ? 'Date unavailable'
                          : _formatDate(openDate),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      countdown,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.softGrey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                letter.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                width: 46,
                height: 1,
                color: AppColors.border,
              ),
              const SizedBox(height: 18),
              Text(
                'Until then, these words remain safely tucked away.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.softGrey,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.terracotta,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                'Someone believed this moment\nwas worth waiting for.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.softGrey,
                      height: 1.45,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadableLetter(
    BuildContext context,
    Letter letter,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _initials(
                  _isIncoming
                      ? (widget.senderName ?? letter.senderName)
                      : letter.recipientName,
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.terracotta,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isIncoming
                ? 'From ${widget.senderName ?? (letter.senderName.isEmpty ? 'Someone special' : letter.senderName)}'
                : letter.recipientName,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (!_isIncoming &&
              letter.recipientRelationship.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              letter.recipientRelationship,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.softGrey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (letter.isDraft)
                      const _LetterLabel(label: 'Draft'),
                    if (letter.isTimeCapsule)
                      const _LetterLabel(label: 'Time Capsule'),
                    if (letter.isFavorite)
                      const _LetterLabel(label: 'Favorite'),
                  ],
                ),
                if (letter.isDraft ||
                    letter.isTimeCapsule ||
                    letter.isFavorite)
                  const SizedBox(height: 16),
                Text(
                  letter.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(letter.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.softGrey,
                      ),
                ),
                const SizedBox(height: 22),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 24),
                Text(
                  'Dear ${letter.recipientName},',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.terracotta,
                      ),
                ),
                const SizedBox(height: 18),
                _buildLetterContent(context, letter),
                if (letter.photoPaths.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_outlined,
                        size: 20,
                        color: AppColors.terracotta,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${letter.photoPaths.length} attached '
                        '${letter.photoPaths.length == 1 ? 'memory' : 'memories'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.local_florist_outlined,
                    color: AppColors.terracotta.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterContent(BuildContext context, Letter letter) {
    if (letter.isPostcard) {
      final imagePath = letter.postcardImagePath;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagePath != null && imagePath.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.48,
                child: _buildStoredImage(imagePath),
              ),
            ),
            const SizedBox(height: 22),
          ],
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              letter.body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                  ),
            ),
          ),
        ],
      );
    }

    if (letter.isHandwritten || letter.isScanned) {
      final pages = List<LetterPage>.from(letter.pages)
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      if (pages.isEmpty) {
        return Text(
          'No pages are available for this letter.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.softGrey,
              ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < pages.length; index++) ...[
            Text(
              'Page ${index + 1} of ${pages.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.terracotta,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                  ),
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: AppColors.cream,
                child: _buildStoredImage(pages[index].imagePath),
              ),
            ),
            if (index != pages.length - 1) ...[
              const SizedBox(height: 24),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 24),
            ],
          ],
        ],
      );
    }

    return SelectableText(
      letter.body,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.75,
          ),
    );
  }

  Widget _buildStoredImage(String path) {
    final uri = Uri.tryParse(path);
    final isRemote = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http');

    if (isRemote) {
      return Image.network(
        path,
        width: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }

    return Image.file(
      File(path),
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _imageError(),
    );
  }

  Widget _imageError() {
    return const SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: AppColors.softGrey,
              size: 38,
            ),
            SizedBox(height: 8),
            Text('This page could not be displayed.'),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'H';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _countdownText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final openingDay = DateTime(date.year, date.month, date.day);
    final days = openingDay.difference(today).inDays;

    if (days <= 0) {
      return 'Ready to open';
    }

    if (days == 1) {
      return 'Opens tomorrow';
    }

    if (days < 30) {
      return 'Opens in $days days';
    }

    final months = (days / 30).floor();

    if (months == 1) {
      return 'Opens in about 1 month';
    }

    if (months < 12) {
      return 'Opens in about $months months';
    }

    final years = (days / 365).floor();

    if (years == 1) {
      return 'Opens in about 1 year';
    }

    return 'Opens in about $years years';
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
}

class _LetterLabel extends StatelessWidget {
  final String label;

  const _LetterLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.terracotta,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

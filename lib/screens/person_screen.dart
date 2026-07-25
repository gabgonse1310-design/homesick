import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/delivery_journey.dart';
import '../models/letter.dart';
import '../models/person.dart';
import '../services/letter_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';
import 'memories_gallery_screen.dart';
import 'envelope_opening_screen.dart';
import 'write_letter_screen.dart';

class PersonScreen extends StatefulWidget {
  final Person person;
  final List<Person> availablePeople;

  const PersonScreen({
    super.key,
    required this.person,
    required this.availablePeople,
  });

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  List<Letter> _letters = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';
  Timer? _journeyTimer;

  String get _personKey => widget.person.personKey;

  List<Letter> get _sealedLetters =>
      _letters.where((letter) => !letter.isDraft).toList();

  List<Letter> get _travellingLetters => _sealedLetters
      .where((letter) => letter.isTravelling)
      .toList();

  List<Letter> get _deliveredLetters => _sealedLetters
      .where((letter) => !letter.isTravelling)
      .toList();

  List<Letter> get _drafts =>
      _letters.where((letter) => letter.isDraft).toList();

  List<Letter> get _filteredLetters {
    final letters = _deliveredLetters;

    switch (_selectedFilter) {
      case 'favorites':
        return letters.where((letter) => letter.isFavorite).toList();
      case 'capsules':
        return letters.where((letter) => letter.isTimeCapsule).toList();
      case 'paper':
        return letters
            .where(
              (letter) =>
                  letter.letterType == LetterType.handwritten ||
                  letter.letterType == LetterType.scanned,
            )
            .toList();
      case 'postcards':
        return letters
            .where((letter) => letter.letterType == LetterType.postcard)
            .toList();
      default:
        return letters;
    }
  }

  int get _memoryCount => _letters.fold<int>(
        widget.person.memoryCount,
        (total, letter) => total + letter.photoPaths.length,
      );

  int get _favoriteCount =>
      _deliveredLetters.where((letter) => letter.isFavorite).length;

  int get _capsuleCount =>
      _deliveredLetters.where((letter) => letter.isTimeCapsule).length;

  @override
  void initState() {
    super.initState();
    _loadLetters();

    _journeyTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted && _travellingLetters.isNotEmpty) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _journeyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final letters =
          await LetterService.instance.loadLettersForPerson(_personKey);

      if (!mounted) return;

      setState(() {
        _letters = letters;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'We could not load this keepsake box.';
      });
    }
  }

  Future<void> _openWriteLetterScreen() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WriteLetterScreen(
          initialPerson: widget.person,
          availablePeople: widget.availablePeople,
        ),
      ),
    );

    if (changed == true) {
      await _loadLetters();
    }
  }

  Future<void> _openLetter(Letter letter) async {
    if (letter.isTravelling) {
      final journey = letter.deliveryJourney;

      _showMessage(
        journey == null
            ? 'This letter is still travelling.'
            : '${journey.statusLabel}. ${journey.remainingDays} ${journey.remainingDays == 1 ? 'day' : 'days'} remaining.',
      );
      return;
    }

    if (letter.isDraft) {
      await _editLetter(letter);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnvelopeOpeningScreen(
          letter: letter,
          person: letter.isIncoming ? null : widget.person,
          availablePeople:
              letter.isIncoming ? null : widget.availablePeople,
          isIncoming: letter.isIncoming,
          senderName: letter.senderName,
        ),
      ),
    );

    await _loadLetters();
  }

  Future<void> _editLetter(Letter letter) async {
    if (letter.isTimeCapsule && !letter.canOpen && !letter.isDraft) {
      _showMessage(
        'A sealed time capsule cannot be edited before it opens.',
      );
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WriteLetterScreen(
          initialPerson: widget.person,
          availablePeople: widget.availablePeople,
          initialLetter: letter,
        ),
      ),
    );

    if (changed == true) {
      await _loadLetters();
    }
  }

  Future<void> _openMemoriesGallery() async {
    if (_memoryCount == 0) {
      _showMessage(
        'Add a photo to a letter and it will appear here.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoriesGalleryScreen(
          person: widget.person,
          letters: _letters,
        ),
      ),
    );

    await _loadLetters();
  }

  Future<void> _toggleFavorite(Letter letter) async {
    try {
      await LetterService.instance.setFavorite(
        id: letter.id,
        isFavorite: !letter.isFavorite,
      );
      await _loadLetters();
    } catch (_) {
      if (mounted) {
        _showMessage('We could not update this letter.');
      }
    }
  }

  Future<void> _deleteLetter(Letter letter) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          letter.isDraft ? 'Delete this draft?' : 'Delete this letter?',
        ),
        content: Text(
          letter.isDraft
              ? 'This unfinished letter will be removed permanently.'
              : '“${letter.title}” will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await LetterService.instance.deleteLetter(letter.id);
      await _loadLetters();

      if (mounted) {
        _showMessage(
          letter.isDraft ? 'Draft deleted.' : 'Letter deleted.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('We could not delete this letter.');
      }
    }
  }

  Future<void> _showLetterOptions(Letter letter) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 18),
              if (!letter.isTravelling && !letter.isIncoming)
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.terracotta,
                  ),
                  title: Text(
                    letter.isDraft ? 'Continue writing' : 'Edit letter',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editLetter(letter);
                  },
                ),
              ListTile(
                leading: Icon(
                  letter.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: AppColors.terracotta,
                ),
                title: Text(
                  letter.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite(letter);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.terracotta,
                ),
                title: Text(
                  letter.isDraft ? 'Delete draft' : 'Delete letter',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteLetter(letter);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        title: const Text('Keepsake Box'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh letters',
            onPressed: _isLoading ? null : _loadLetters,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLetters,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildStatistics(),
                    const SizedBox(height: 28),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 70),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadLetters,
                      )
                    else ...[
                      if (_travellingLetters.isNotEmpty) ...[
                        _buildSectionHeading(
                          title: 'Travelling',
                          subtitle:
                              '${_travellingLetters.length} ${_travellingLetters.length == 1 ? 'letter is' : 'letters are'} making the journey',
                        ),
                        const SizedBox(height: 12),
                        ..._travellingLetters.map(
                          (letter) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TravellingLetterCard(
                              letter: letter,
                              onTap: () => _openLetter(letter),
                              onMore: () => _showLetterOptions(letter),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_drafts.isNotEmpty) ...[
                        _buildSectionHeading(
                          title: 'Words waiting',
                          subtitle:
                              '${_drafts.length} unfinished ${_drafts.length == 1 ? 'letter' : 'letters'}',
                        ),
                        const SizedBox(height: 12),
                        ..._drafts.map(
                          (letter) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DraftKeepsakeCard(
                              letter: letter,
                              onTap: () => _openLetter(letter),
                              onMore: () => _showLetterOptions(letter),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildSectionHeading(
                        title: 'Inside the box',
                        subtitle: _deliveredLetters.isEmpty
                            ? 'No delivered letters yet'
                            : '${_deliveredLetters.length} ${_deliveredLetters.length == 1 ? 'letter' : 'letters'} kept here',
                      ),
                      const SizedBox(height: 14),
                      if (_deliveredLetters.isNotEmpty) ...[
                        _buildFilters(),
                        const SizedBox(height: 18),
                      ],
                      if (_deliveredLetters.isEmpty)
                        _EmptyKeepsakeState(
                          personName: widget.person.name,
                          symbol: widget.person.symbol,
                          onWrite: _openWriteLetterScreen,
                        )
                      else if (_filteredLetters.isEmpty)
                        _EmptyFilterState(
                          onShowAll: () {
                            setState(() {
                              _selectedFilter = 'all';
                            });
                          },
                        )
                      else
                        _buildEnvelopeGrid(),
                      const SizedBox(height: 26),
                      _buildMemoryShelf(),
                    ],
                  ],
                ),
              ),
            ),
            _buildWriteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: BotanicalPersonIcon(
              symbol: widget.person.symbol,
              size: 76,
              padding: const EdgeInsets.all(9),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.person.name,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (widget.person.relationship.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.person.relationship,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.softGrey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'A quiet place for every word you keep.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softGrey,
                  height: 1.45,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.mail_outline_rounded,
            value: _deliveredLetters.length.toString(),
            label: 'Letters',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_border_rounded,
            value: _favoriteCount.toString(),
            label: 'Favorites',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            value: _capsuleCount.toString(),
            label: 'Capsules',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.softGrey,
              ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = <_FilterItem>[
      const _FilterItem('all', 'All'),
      const _FilterItem('favorites', 'Favorites'),
      const _FilterItem('capsules', 'Capsules'),
      const _FilterItem('paper', 'On paper'),
      const _FilterItem('postcards', 'Postcards'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selected = item.keyName == _selectedFilter;

          return ChoiceChip(
            label: Text(item.label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) {
              setState(() {
                _selectedFilter = item.keyName;
              });
            },
            backgroundColor: AppColors.paper,
            selectedColor:
                AppColors.terracotta.withOpacity(0.12),
            side: BorderSide(
              color: selected
                  ? AppColors.terracotta
                  : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? AppColors.terracotta
                  : AppColors.softGrey,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnvelopeGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: _filteredLetters.map((letter) {
            return SizedBox(
              width: cardWidth,
              child: _EnvelopeCard(
                letter: letter,
                personSymbol: widget.person.symbol,
                onTap: () => _openLetter(letter),
                onMore: () => _showLetterOptions(letter),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMemoryShelf() {
    return InkWell(
      onTap: _openMemoriesGallery,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memory shelf',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _memoryCount == 0
                        ? 'Photos added to letters will gather here.'
                        : '$_memoryCount ${_memoryCount == 1 ? 'memory' : 'memories'} kept together.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.softGrey,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.softGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWriteButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openWriteLetterScreen,
          icon: const Icon(Icons.edit_outlined),
          label: Text('Write to ${widget.person.name}'),
        ),
      ),
    );
  }
}

class _FilterItem {
  final String keyName;
  final String label;

  const _FilterItem(this.keyName, this.label);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
            color: AppColors.terracotta,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.terracotta,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.softGrey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class _TravellingLetterCard extends StatelessWidget {
  final Letter letter;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _TravellingLetterCard({
    required this.letter,
    required this.onTap,
    required this.onMore,
  });

  String _place(String city, String country) {
    final cleanCity = city.trim();
    final cleanCountry = country.trim();

    if (cleanCity.isEmpty) return cleanCountry;
    if (cleanCountry.isEmpty) return cleanCity;
    return '$cleanCity, $cleanCountry';
  }

  String _remainingLabel(DeliveryJourney journey) {
    final days = journey.remainingDays;

    if (days <= 0) {
      return 'Arriving today';
    }

    return '$days ${days == 1 ? 'day' : 'days'} remaining';
  }

  @override
  Widget build(BuildContext context) {
    final journey = letter.deliveryJourney;

    if (journey == null) {
      return const SizedBox.shrink();
    }

    final progress = journey.progress.clamp(0.0, 1.0);

    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.terracotta.withOpacity(0.42),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_post_office_outlined,
                          size: 16,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          journey.statusLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Letter options',
                    visualDensity: VisualDensity.compact,
                    onPressed: onMore,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.softGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                letter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _JourneyPlace(
                      label: 'From',
                      place: _place(
                        journey.originCity,
                        journey.originCountry,
                      ),
                      alignment: CrossAxisAlignment.start,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.flight_rounded,
                      color: AppColors.terracotta,
                      size: 25,
                    ),
                  ),
                  Expanded(
                    child: _JourneyPlace(
                      label: 'To',
                      place: _place(
                        journey.destinationCity,
                        journey.destinationCountry,
                      ),
                      alignment: CrossAxisAlignment.end,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.cream,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}% travelled',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.softGrey),
                  ),
                  const Spacer(),
                  Text(
                    _remainingLabel(journey),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Estimated arrival ${_formatDate(journey.estimatedArrival)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.softGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyPlace extends StatelessWidget {
  final String label;
  final String place;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  const _JourneyPlace({
    required this.label,
    required this.place,
    required this.alignment,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.softGrey,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          place,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _DraftKeepsakeCard extends StatelessWidget {
  final Letter letter;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _DraftKeepsakeCard({
    required this.letter,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.terracotta,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Badge(label: 'Draft'),
                    const SizedBox(height: 8),
                    Text(
                      letter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(letter.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.softGrey,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Draft options',
                onPressed: onMore,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.softGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvelopeCard extends StatefulWidget {
  final Letter letter;
  final String personSymbol;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _EnvelopeCard({
    required this.letter,
    required this.personSymbol,
    required this.onTap,
    required this.onMore,
  });

  @override
  State<_EnvelopeCard> createState() => _EnvelopeCardState();
}

class _EnvelopeCardState extends State<_EnvelopeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _lift;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _lift = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scale = Tween<double>(begin: 1, end: 1.025).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();

    if (!mounted) return;
    widget.onTap();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;
    final isLocked = letter.isTimeCapsule && !letter.canOpen;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _lift.value),
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            height: 252,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.11),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: CustomPaint(
                      painter: _WatercolorEnvelopePainter(
                        borderColor:
                            AppColors.terracotta.withOpacity(0.18),
                        flowerColor:
                            AppColors.terracotta.withOpacity(0.34),
                        leafColor: AppColors.olive.withOpacity(0.36),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _LetterTypeIcon(letter: letter),
                ),
                Positioned(
                  top: 8,
                  right: 7,
                  child: Row(
                    children: [
                      if (letter.isFavorite)
                        const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.terracotta,
                          size: 18,
                        ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Letter options',
                        onPressed: widget.onMore,
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: AppColors.terracotta,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 91,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _BotanicalWaxSeal(
                      symbol: widget.personSymbol,
                      isLocked: isLocked,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 17,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (letter.isTimeCapsule) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isLocked ? 'Time capsule' : 'Capsule opened',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.terracotta,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        letter.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isLocked && letter.openDate != null
                            ? 'Opens ${_formatDate(letter.openDate!)}'
                            : _formatDate(letter.updatedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.softGrey,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WatercolorEnvelopePainter extends CustomPainter {
  final Color borderColor;
  final Color flowerColor;
  final Color leafColor;

  const _WatercolorEnvelopePainter({
    required this.borderColor,
    required this.flowerColor,
    required this.leafColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final body = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(26),
    );

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFBF4),
          Color(0xFFF8EFDFFF),
        ],
      ).createShader(rect);

    canvas.drawRRect(body, basePaint);

    final paperGlow = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.18),
        width: size.width * 0.92,
        height: size.height * 0.36,
      ),
      paperGlow,
    );

    final flapShadow = Paint()
      ..color = Colors.black.withOpacity(0.055)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final flapShadowPath = Path()
      ..moveTo(0, 8)
      ..quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.36,
        size.width * 0.5,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.36,
        size.width,
        8,
      )
      ..close();

    canvas.drawPath(
      flapShadowPath.shift(const Offset(0, 5)),
      flapShadow,
    );

    final flapPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFCF6),
          Color(0xFFF3E8D5),
        ],
      ).createShader(rect);

    final flapPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.34,
        size.width * 0.5,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.34,
        size.width,
        0,
      )
      ..close();

    canvas.drawPath(flapPath, flapPaint);

    final foldPaint = Paint()
      ..color = const Color(0xFFE7D5BC).withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    final leftFold = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.72,
        size.width * 0.5,
        size.height * 0.54,
      );

    final rightFold = Path()
      ..moveTo(size.width, size.height)
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.72,
        size.width * 0.5,
        size.height * 0.54,
      );

    canvas.drawPath(leftFold, foldPaint);
    canvas.drawPath(rightFold, foldPaint);

    final outlinePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;

    canvas.drawRRect(body.deflate(0.7), outlinePaint);

    final grainPaint = Paint()
      ..color = const Color(0xFFB99B78).withOpacity(0.055)
      ..strokeWidth = 0.7;

    for (var i = 0; i < 42; i++) {
      final x = ((i * 37) % 101) / 101 * size.width;
      final y = ((i * 61) % 97) / 97 * size.height;
      canvas.drawCircle(Offset(x, y), 0.7, grainPaint);
    }

    _drawBranch(
      canvas,
      origin: Offset(size.width * 0.17, size.height * 0.31),
      direction: const Offset(1, -0.18),
      scale: 0.82,
    );

    _drawBranch(
      canvas,
      origin: Offset(size.width * 0.78, size.height * 0.86),
      direction: const Offset(-0.9, -0.35),
      scale: 0.94,
    );
  }

  void _drawBranch(
    Canvas canvas, {
    required Offset origin,
    required Offset direction,
    required double scale,
  }) {
    final stemPaint = Paint()
      ..color = leafColor.withOpacity(0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;

    final end = origin + direction * (70 * scale);
    final stem = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(
        origin.dx + direction.dx * 30 * scale,
        origin.dy + direction.dy * 16 * scale,
        end.dx,
        end.dy,
      );

    canvas.drawPath(stem, stemPaint);

    for (var i = 1; i <= 4; i++) {
      final t = i / 5;
      final point = Offset.lerp(origin, end, t)!;
      final side = i.isEven ? 1.0 : -1.0;

      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(
        math.atan2(direction.dy, direction.dx) + side * 0.75,
      );

      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          7 * scale,
          -6 * scale,
          14 * scale,
          0,
        )
        ..quadraticBezierTo(
          7 * scale,
          6 * scale,
          0,
          0,
        )
        ..close();

      final leafPaint = Paint()
        ..color = leafColor.withOpacity(0.72 - (i * 0.07));

      canvas.drawPath(leafPath, leafPaint);
      canvas.restore();
    }

    _drawFlower(
      canvas,
      end,
      radius: 8.0 * scale,
    );

    _drawFlower(
      canvas,
      Offset.lerp(origin, end, 0.58)! +
          Offset(-direction.dy, direction.dx) * (10 * scale),
      radius: 5.5 * scale,
    );
  }

  void _drawFlower(
    Canvas canvas,
    Offset center, {
    required double radius,
  }) {
    final petalPaint = Paint()
      ..color = flowerColor.withOpacity(0.62);

    for (var i = 0; i < 5; i++) {
      final angle = (math.pi * 2 / 5) * i;
      final petalCenter = center +
          Offset(
            math.cos(angle) * radius * 0.58,
            math.sin(angle) * radius * 0.58,
          );

      canvas.drawOval(
        Rect.fromCenter(
          center: petalCenter,
          width: radius * 0.86,
          height: radius * 1.18,
        ),
        petalPaint,
      );
    }

    canvas.drawCircle(
      center,
      radius * 0.28,
      Paint()..color = const Color(0xFFCA8A5D).withOpacity(0.78),
    );
  }

  @override
  bool shouldRepaint(covariant _WatercolorEnvelopePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.flowerColor != flowerColor ||
        oldDelegate.leafColor != leafColor;
  }
}

class _BotanicalWaxSeal extends StatelessWidget {
  final String symbol;
  final bool isLocked;

  const _BotanicalWaxSeal({
    required this.symbol,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.28, -0.32),
          radius: 0.95,
          colors: [
            Color(0xFFE78B69),
            Color(0xFFC85D43),
            Color(0xFFA94431),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF9D402E),
          width: 1.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.32),
            blurRadius: 2,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Container(
        width: 57,
        height: 57,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFF2B29D).withOpacity(0.72),
            width: 1.4,
          ),
          color: const Color(0xFFC85D43).withOpacity(0.42),
        ),
        child: isLocked
            ? const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFFE7DA),
                size: 24,
              )
            : BotanicalPersonIcon(
                symbol: symbol,
                size: 42,
                padding: const EdgeInsets.all(5),
              ),
      ),
    );
  }
}

class _LetterTypeIcon extends StatelessWidget {
  final Letter letter;

  const _LetterTypeIcon({
    required this.letter,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip;

    switch (letter.letterType) {
      case LetterType.handwritten:
        icon = Icons.draw_outlined;
        tooltip = 'Handwritten';
        break;
      case LetterType.scanned:
        icon = Icons.document_scanner_outlined;
        tooltip = 'Scanned';
        break;
      case LetterType.postcard:
        icon = Icons.photo_outlined;
        tooltip = 'Postcard';
        break;
      case LetterType.typed:
        icon = Icons.text_fields_rounded;
        tooltip = 'Typed';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cream,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 17,
          color: AppColors.terracotta,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.terracotta,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyKeepsakeState extends StatelessWidget {
  final String personName;
  final String symbol;
  final VoidCallback onWrite;

  const _EmptyKeepsakeState({
    required this.personName,
    required this.symbol,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: BotanicalPersonIcon(
              symbol: symbol,
              size: 66,
              padding: const EdgeInsets.all(7),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'The box is waiting',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 9),
          Text(
            'The first letter you write to $personName will be kept safely here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softGrey,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onWrite,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Write the first letter'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final VoidCallback onShowAll;

  const _EmptyFilterState({
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.terracotta,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing tucked here yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 7),
          Text(
            'Try another keepsake filter.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softGrey,
                ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onShowAll,
            child: const Text('Show all letters'),
          ),
        ],
      ),
    );
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

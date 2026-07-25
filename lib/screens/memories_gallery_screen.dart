import 'dart:io';

import 'package:flutter/material.dart';

import '../models/letter.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';

class MemoriesGalleryScreen extends StatelessWidget {
  final Person person;
  final List<Letter> letters;

  const MemoriesGalleryScreen({
    super.key,
    required this.person,
    required this.letters,
  });

  List<_MemoryItem> get _memories {
    final items = <_MemoryItem>[];

    for (final letter in letters) {
      for (var index = 0; index < letter.photoPaths.length; index++) {
        final path = letter.photoPaths[index];

        if (path.trim().isEmpty) {
          continue;
        }

        items.add(
          _MemoryItem(
            id: '${letter.id}-$index',
            path: path,
            date: letter.updatedAt,
            letterTitle: letter.title,
          ),
        );
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Map<int, List<_MemoryItem>> _groupByYear(List<_MemoryItem> memories) {
    final grouped = <int, List<_MemoryItem>>{};

    for (final memory in memories) {
      grouped.putIfAbsent(memory.date.year, () => []).add(memory);
    }

    return grouped;
  }

  void _openViewer(
    BuildContext context,
    List<_MemoryItem> memories,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MemoryViewerScreen(
          person: person,
          memories: memories,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memories = _memories;
    final groupedMemories = _groupByYear(memories);
    final years = groupedMemories.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Memories'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: memories.isEmpty
            ? _EmptyMemoriesState(person: person)
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                      child: _GalleryHeader(
                        person: person,
                        memoryCount: memories.length,
                      ),
                    ),
                  ),
                  for (final year in years) ...[
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _YearHeaderDelegate(year: year),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final memory = groupedMemories[year]![index];
                            final globalIndex = memories.indexOf(memory);

                            return _MemoryTile(
                              memory: memory,
                              onTap: () => _openViewer(
                                context,
                                memories,
                                globalIndex,
                              ),
                            );
                          },
                          childCount: groupedMemories[year]!.length,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 22),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  final Person person;
  final int memoryCount;

  const _GalleryHeader({
    required this.person,
    required this.memoryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.paper,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: BotanicalPersonIcon(
            symbol: person.symbol,
            size: 72,
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          person.name,
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '$memoryCount ${memoryCount == 1 ? 'memory' : 'memories'} kept here',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.softGrey,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MemoryTile extends StatelessWidget {
  final _MemoryItem memory;
  final VoidCallback onTap;

  const _MemoryTile({
    required this.memory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: memory.id,
      child: Material(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Image.file(
            File(memory.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                color: AppColors.paper,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.softGrey,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MemoryViewerScreen extends StatefulWidget {
  final Person person;
  final List<_MemoryItem> memories;
  final int initialIndex;

  const _MemoryViewerScreen({
    required this.person,
    required this.memories,
    required this.initialIndex,
  });

  @override
  State<_MemoryViewerScreen> createState() =>
      _MemoryViewerScreenState();
}

class _MemoryViewerScreenState extends State<_MemoryViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} of ${widget.memories.length}',
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.memories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.memories[index];

              return Center(
                child: Hero(
                  tag: item.id,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(
                      File(item.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 52,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.58),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (memory.letterTitle.trim().isNotEmpty)
                      Text(
                        memory.letterTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(memory.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

class _EmptyMemoriesState extends StatelessWidget {
  final Person person;

  const _EmptyMemoriesState({required this.person});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 32, 26, 30),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BotanicalPersonIcon(
                symbol: person.symbol,
                size: 78,
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(height: 16),
              Text(
                'No memories yet',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Photos attached to letters for ${person.name} will appear here and be organised by year.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.softGrey,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int year;

  _YearHeaderDelegate({required this.year});

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        year.toString(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.terracotta,
            ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _YearHeaderDelegate oldDelegate) {
    return oldDelegate.year != year;
  }
}

class _MemoryItem {
  final String id;
  final String path;
  final DateTime date;
  final String letterTitle;

  const _MemoryItem({
    required this.id,
    required this.path,
    required this.date,
    required this.letterTitle,
  });
}

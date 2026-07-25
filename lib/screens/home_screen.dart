import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../models/person.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';
import '../widgets/homesick_background.dart';
import '../widgets/micro_animations.dart';
import 'add_person_screen.dart';
import 'inbox_screen.dart';
import 'invitations_screen.dart';
import 'person_screen.dart';
import 'write_letter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _service = FirestoreService.instance;

  bool _preparingProfile = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _prepareUserProfile();
  }

  Future<void> _prepareUserProfile() async {
    try {
      await _service.ensureCurrentUserProfile();

      if (!mounted) return;
      setState(() {
        _preparingProfile = false;
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preparingProfile = false;
        _profileError = error.toString();
      });
    }
  }

  Future<void> _openAddPersonScreen() async {
    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddPersonScreen(),
      ),
    );

    if (person == null || !mounted) return;

    try {
      final id = await _service.addPerson(
        name: person.name,
        relationship: person.relationship,
        symbol: person.symbol,
        email: person.email,
        city: person.city,
        country: person.country,
        letterCount: person.letterCount,
        memoryCount: person.memoryCount,
        createdYear: person.createdYear,
        lastActivity: person.lastActivity,
        hasNewWords: person.hasNewWords,
      );

      final savedPerson = person.copyWith(id: id);

      if (savedPerson.hasEmail && !savedPerson.isConnected) {
        await _service.sendConnectionInvitation(person: savedPerson);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPerson.hasEmail
                ? '${savedPerson.name} was added and the connection was prepared.'
                : '${savedPerson.name} was added.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  void _openWriteLetterScreen(List<Person> people) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteLetterScreen(
          availablePeople: people,
        ),
      ),
    );
  }

  void _openTimeCapsuleScreen(List<Person> people) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteLetterScreen(
          availablePeople: people,
          startAsTimeCapsule: true,
        ),
      ),
    );
  }

  void _openPersonScreen(Person person, List<Person> people) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonScreen(
          person: person,
          availablePeople: people,
        ),
      ),
    );
  }

  Person _personFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = Map<String, dynamic>.from(document.data());

    data['id'] = data['id']?.toString().isNotEmpty == true
        ? data['id']
        : document.id;

    final lastActivity = data['lastActivity'];

    if (lastActivity is Timestamp) {
      data['lastActivity'] = _formatLastActivity(lastActivity.toDate());
    }

    return Person.fromMap(data);
  }

  String _formatLastActivity(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(activityDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  String get _greetingName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';

    if (displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'there';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Color _statusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green.shade700;
      case ConnectionStatus.invited:
        return Colors.amber.shade800;
      case ConnectionStatus.local:
        return AppColors.softGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _preparingProfile ? null : _service.watchPeople(),
      builder: (context, snapshot) {
        final people = snapshot.data?.docs
                .map(_personFromDocument)
                .where((person) => person.name.isNotEmpty)
                .toList() ??
            <Person>[];

        return Scaffold(
          body: HomesickBackground(
            asset: AppAssets.homeBackground,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  GentleReveal(
                    delay: const Duration(milliseconds: 40),
                    child: Row(
                      children: [
                        BreathingWidget(
                        amplitude: 0.018,
                        duration: const Duration(milliseconds: 2600),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            AppAssets.homeIcon,
                            width: 66,
                            height: 66,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting, $_greetingName',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                            ),
                            const SizedBox(height: 3),
                            const Text('Home is only a letter away.'),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Invitations',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvitationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: AppColors.terracotta,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GentleReveal(
                    delay: const Duration(milliseconds: 130),
                    child: StreamBuilder<int>(
                    stream: _service.watchUnreadIncomingLetterCount(),
                    builder: (context, unreadSnapshot) {
                      return _actionTile(
                        title: 'Words for you',
                        asset: AppAssets.letterIcon,
                        badgeCount: unreadSnapshot.data ?? 0,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InboxScreen(),
                            ),
                          );
                        },
                      );
                    },
                    ),
                  ),
                  const SizedBox(height: 12),
                  GentleReveal(
                    delay: const Duration(milliseconds: 210),
                    child: _actionTile(
                    title: 'Write a letter',
                    asset: AppAssets.letterIcon,
                    onTap: () => _openWriteLetterScreen(people),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GentleReveal(
                    delay: const Duration(milliseconds: 290),
                    child: _actionTile(
                      title: 'Create a time capsule',
                      asset: AppAssets.letterIcon,
                      onTap: () => _openTimeCapsuleScreen(people),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GentleReveal(
                    delay: const Duration(milliseconds: 370),
                    child: _actionTile(
                    title: 'Add someone',
                    asset: AppAssets.personIcon,
                    onTap: _openAddPersonScreen,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        'Your people',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _openAddPersonScreen,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_preparingProfile)
                    _statusCard('Preparing your keepsake box...')
                  else if (_profileError != null)
                    _statusCard(
                      'We could not connect to your keepsake box.',
                    )
                  else if (snapshot.hasError)
                    _statusCard(
                      'We could not load your people. Please try again.',
                    )
                  else if (snapshot.connectionState ==
                      ConnectionState.waiting)
                    _statusCard('Gathering your people...')
                  else if (people.isEmpty)
                    _statusCard(
                      'Add someone to begin keeping letters together.',
                    )
                  else
                    ...people.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final person = entry.value;

                        return GentleReveal(
                          delay: Duration(
                            milliseconds: 340 + (index.clamp(0, 8) * 55),
                          ),
                          child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: AppColors.paper.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                            onTap: () =>
                                _openPersonScreen(person, people),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            leading: BotanicalPersonIcon(
                              symbol: person.symbol,
                              size: 46,
                              padding: const EdgeInsets.all(4),
                            ),
                            title: Text(person.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (person.relationship.isNotEmpty)
                                  Text(person.relationship),
                                if (person.city.isNotEmpty ||
                                    person.country.isNotEmpty)
                                  Text(
                                    [
                                      person.city,
                                      person.country,
                                    ]
                                        .where((value) => value.isNotEmpty)
                                        .join(', '),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: _statusColor(
                                        person.connectionStatus,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      person.connectionLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: _statusColor(
                                              person.connectionStatus,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (person.hasNewWords)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: PulsingDot(
                                      size: 10,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          floatingActionButton: BreathingWidget(
            amplitude: 0.012,
            duration: const Duration(milliseconds: 2200),
            child: FloatingActionButton.extended(
            onPressed: () => _openWriteLetterScreen(people),
            backgroundColor: AppColors.terracotta,
            foregroundColor: Colors.white,
            icon: Image.asset(
              AppAssets.writeIcon,
              width: 26,
              height: 26,
            ),
            label: const Text('Write a letter'),
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required String title,
    required String asset,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: AppColors.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Image.asset(
                asset,
                width: 46,
                height: 46,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (badgeCount > 0)
                PulsingBadge(
                  count: badgeCount,
                  color: AppColors.terracotta,
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.softInk,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(String message) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
      ),
    );
  }
}

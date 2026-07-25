import 'package:flutter/material.dart';

import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';
import '../widgets/time_capsule_card.dart';

class TimeCapsuleSetupResult {
  final DateTime openDate;
  final List<String> recipientKeys;
  final String accessMode;

  const TimeCapsuleSetupResult({
    required this.openDate,
    required this.recipientKeys,
    required this.accessMode,
  });
}

class TimeCapsuleCreatorScreen extends StatefulWidget {
  final List<Person> people;
  final List<String> initialRecipientKeys;
  final DateTime? initialOpenDate;
  final String initialAccessMode;

  const TimeCapsuleCreatorScreen({
    super.key,
    required this.people,
    this.initialRecipientKeys = const [],
    this.initialOpenDate,
    this.initialAccessMode = CapsuleAccessMode.onlyMe,
  });

  @override
  State<TimeCapsuleCreatorScreen> createState() =>
      _TimeCapsuleCreatorScreenState();
}

class _TimeCapsuleCreatorScreenState
    extends State<TimeCapsuleCreatorScreen> {
  late final Set<String> _selectedKeys;
  DateTime? _openDate;
  late String _accessMode;

  @override
  void initState() {
    super.initState();
    _selectedKeys = widget.initialRecipientKeys.toSet();
    _openDate = widget.initialOpenDate;
    _accessMode = widget.initialAccessMode;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final result = await showDatePicker(
      context: context,
      initialDate: _openDate ?? tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 20),
      helpText: 'When should the capsule open?',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.terracotta,
                surface: AppColors.paper,
              ),
        ),
        child: child!,
      ),
    );

    if (result != null && mounted) {
      setState(() => _openDate = result);
    }
  }

  void _usePreset(Duration duration) {
    final now = DateTime.now();
    setState(() {
      _openDate = DateTime(now.year, now.month, now.day).add(duration);
    });
  }

  void _finish() {
    if (_openDate == null) {
      _message('Choose when the capsule should open.');
      return;
    }
    if (_selectedKeys.isEmpty) {
      _message('Choose at least one person for this capsule.');
      return;
    }

    Navigator.pop(
      context,
      TimeCapsuleSetupResult(
        openDate: _openDate!,
        recipientKeys: _selectedKeys.toList(),
        accessMode: _accessMode,
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Create a Time Capsule'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_clock_rounded,
                          size: 52,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Words for the future',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Choose who will receive these words and when the capsule may be opened.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.softGrey,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Opening date',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Material(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: AppColors.terracotta),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                _openDate == null
                                    ? 'Choose a date'
                                    : _formatDate(_openDate!),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('In 1 month'),
                        onPressed: () => _usePreset(const Duration(days: 30)),
                      ),
                      ActionChip(
                        label: const Text('In 6 months'),
                        onPressed: () => _usePreset(const Duration(days: 182)),
                      ),
                      ActionChip(
                        label: const Text('In 1 year'),
                        onPressed: () => _usePreset(const Duration(days: 365)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Who will receive it?',
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      Text(
                        '${_selectedKeys.length} selected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...widget.people.map((person) {
                    final selected = _selectedKeys.contains(person.personKey);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: selected ? AppColors.cream : AppColors.paper,
                        borderRadius: BorderRadius.circular(19),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedKeys.remove(person.personKey);
                              } else {
                                _selectedKeys.add(person.personKey);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(19),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: selected
                                    ? AppColors.terracotta
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                BotanicalPersonIcon(
                                  symbol: person.symbol,
                                  size: 46,
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(person.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      if (person.relationship.isNotEmpty)
                                        Text(
                                          person.relationship,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: AppColors.softGrey),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: selected
                                      ? AppColors.terracotta
                                      : AppColors.softGrey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  Text('How should it open?',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _AccessOption(
                    title: 'Each person opens individually',
                    subtitle: 'Everyone receives their own sealed copy.',
                    icon: Icons.person_outline_rounded,
                    selected: _accessMode == CapsuleAccessMode.onlyMe,
                    onTap: () => setState(
                      () => _accessMode = CapsuleAccessMode.onlyMe,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AccessOption(
                    title: 'Open together',
                    subtitle: 'Keep the same people linked to the capsule.',
                    icon: Icons.groups_2_outlined,
                    selected:
                        _accessMode == CapsuleAccessMode.trustedPeople,
                    onTap: () => setState(
                      () => _accessMode = CapsuleAccessMode.trustedPeople,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Use This Time Capsule'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AccessOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.cream : AppColors.paper,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.terracotta : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.terracotta),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.softGrey,
                            )),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? AppColors.terracotta
                    : AppColors.softGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

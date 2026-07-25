import 'package:flutter/material.dart';

import '../models/person.dart';
import '../theme/app_theme.dart';
import 'botanical_person_icon.dart';

class CapsuleAccessMode {
  static const String onlyMe = 'onlyMe';
  static const String recipientAndMe = 'recipientAndMe';
  static const String trustedPeople = 'trustedPeople';
}

class TimeCapsuleCard extends StatelessWidget {
  final bool isTimeCapsule;
  final DateTime? openDate;
  final Person? recipient;
  final List<Person> availablePeople;
  final String accessMode;
  final List<String> authorizedPersonKeys;
  final ValueChanged<bool> onTypeChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<String> onAccessModeChanged;
  final ValueChanged<List<String>> onAuthorizedPeopleChanged;
  final bool enabled;

  const TimeCapsuleCard({
    super.key,
    required this.isTimeCapsule,
    required this.openDate,
    required this.recipient,
    required this.availablePeople,
    required this.accessMode,
    required this.authorizedPersonKeys,
    required this.onTypeChanged,
    required this.onDateChanged,
    required this.onAccessModeChanged,
    required this.onAuthorizedPeopleChanged,
    this.enabled = true,
  });

  String _personKey(Person person) {
    return '${person.name.trim().toLowerCase()}::'
        '${person.relationship.trim().toLowerCase()}';
  }

  Future<void> _chooseOpenDate(BuildContext context) async {
    if (!enabled) return;

    final now = DateTime.now();
    final firstAllowedDate = DateTime(now.year, now.month, now.day + 1);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: openDate ?? firstAllowedDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(now.year + 20),
      helpText: 'Choose when this capsule can be opened',
      cancelText: 'Cancel',
      confirmText: 'Choose Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.terracotta,
                  surface: AppColors.paper,
                ),
            dialogBackgroundColor: AppColors.paper,
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) onDateChanged(selectedDate);
  }

  Future<void> _chooseTrustedPeople(BuildContext context) async {
    if (!enabled) return;

    final selected = Set<String>.from(authorizedPersonKeys);
    final recipientKey = recipient == null ? null : _personKey(recipient!);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      'Choose trusted people',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'They will be allowed to open this capsule once its date arrives.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.softGrey,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: availablePeople.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final person = availablePeople[index];
                          final key = _personKey(person);
                          final isRecipient = key == recipientKey;
                          final isSelected = selected.contains(key);

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: AppColors.terracotta,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            secondary: BotanicalPersonIcon(
                              symbol: person.symbol,
                              size: 44,
                            ),
                            title: Text(person.name),
                            subtitle: Text(
                              isRecipient
                                  ? '${person.relationship} · Recipient'
                                  : person.relationship,
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selected.add(key);
                                } else {
                                  selected.remove(key);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, selected.toList()),
                        child: const Text('Save Access'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) onAuthorizedPeopleChanged(result);
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _countdownText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final openingDay = DateTime(date.year, date.month, date.day);
    final days = openingDay.difference(today).inDays;

    if (days <= 0) return 'Ready to open';
    if (days == 1) return 'Opens tomorrow';
    if (days < 30) return 'Opens in $days days';

    final months = (days / 30).floor();
    if (months == 1) return 'Opens in about 1 month';
    if (months < 12) return 'Opens in about $months months';

    final years = (days / 365).floor();
    return years == 1
        ? 'Opens in about 1 year'
        : 'Opens in about $years years';
  }

  String _accessSummary() {
    switch (accessMode) {
      case CapsuleAccessMode.recipientAndMe:
        return recipient == null
            ? 'You and the recipient'
            : 'You and ${recipient!.name}';
      case CapsuleAccessMode.trustedPeople:
        final count = authorizedPersonKeys.length;
        if (count == 0) return 'Choose at least one trusted person';
        return '$count trusted ${count == 1 ? 'person' : 'people'} selected';
      default:
        return 'Only you';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTimeCapsule ? AppColors.terracotta : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How should these words arrive?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Seal them as a letter now, or keep them closed until a future date.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softGrey,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TypeOption(
                  title: 'Letter',
                  subtitle: 'Ready to read',
                  icon: Icons.mail_outline_rounded,
                  isSelected: !isTimeCapsule,
                  enabled: enabled,
                  onTap: () {
                    onTypeChanged(false);
                    onDateChanged(null);
                    onAccessModeChanged(CapsuleAccessMode.onlyMe);
                    onAuthorizedPeopleChanged(const []);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeOption(
                  title: 'Time Capsule',
                  subtitle: 'Open later',
                  icon: Icons.lock_clock_outlined,
                  isSelected: isTimeCapsule,
                  enabled: enabled,
                  onTap: () => onTypeChanged(true),
                ),
              ),
            ],
          ),
          if (isTimeCapsule) ...[
            const SizedBox(height: 18),
            _SectionLabel(
              icon: Icons.calendar_month_outlined,
              title: 'When should it open?',
            ),
            const SizedBox(height: 10),
            _ActionBox(
              icon: Icons.calendar_month_outlined,
              title: openDate == null
                  ? 'Choose an opening date'
                  : _formatDate(openDate!),
              subtitle: openDate == null
                  ? 'The capsule will stay locked until then.'
                  : _countdownText(openDate!),
              enabled: enabled,
              onTap: () => _chooseOpenDate(context),
            ),
            const SizedBox(height: 22),
            _SectionLabel(
              icon: Icons.key_outlined,
              title: 'Who may open it?',
            ),
            const SizedBox(height: 10),
            _AccessOption(
              title: 'Only me',
              subtitle: 'Keep this capsule private',
              value: CapsuleAccessMode.onlyMe,
              groupValue: accessMode,
              enabled: enabled,
              onChanged: onAccessModeChanged,
            ),
            _AccessOption(
              title: 'Me + recipient',
              subtitle: recipient == null
                  ? 'Choose a recipient first'
                  : '${recipient!.name} may open it too',
              value: CapsuleAccessMode.recipientAndMe,
              groupValue: accessMode,
              enabled: enabled && recipient != null,
              onChanged: onAccessModeChanged,
            ),
            _AccessOption(
              title: 'Choose trusted people',
              subtitle: 'Select one or more people from My People',
              value: CapsuleAccessMode.trustedPeople,
              groupValue: accessMode,
              enabled: enabled,
              onChanged: (value) {
                onAccessModeChanged(value);
                _chooseTrustedPeople(context);
              },
            ),
            if (accessMode == CapsuleAccessMode.trustedPeople) ...[
              const SizedBox(height: 10),
              _ActionBox(
                icon: Icons.group_outlined,
                title: _accessSummary(),
                subtitle: 'Tap to review who has access',
                enabled: enabled,
                onTap: () => _chooseTrustedPeople(context),
              ),
            ],
            if (openDate != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.terracotta,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This capsule will remain closed until '
                        '${_formatDate(openDate!)}. ${_accessSummary()} may open it then.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.softGrey,
                              height: 1.45,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.terracotta),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ActionBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.terracotta),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          ),
        ),
      ),
    );
  }
}

class _AccessOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _AccessOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.terracotta,
              onChanged: enabled
                  ? (newValue) {
                      if (newValue != null) onChanged(newValue);
                    }
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.softGrey,
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

class _TypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _TypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.cream : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.terracotta : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.terracotta
                    : AppColors.softGrey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isSelected ? AppColors.terracotta : null,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

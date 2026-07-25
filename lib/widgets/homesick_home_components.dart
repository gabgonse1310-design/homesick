import 'package:flutter/material.dart';

import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_person_icon.dart';

class HomesickHomeHeader extends StatelessWidget {
  const HomesickHomeHeader({
    super.key,
    required this.greeting,
    required this.onSettingsPressed,
  });

  final String greeting;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.softGrey,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome home.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSettingsPressed,
          tooltip: 'Settings',
          icon: const Icon(
            Icons.settings_outlined,
            color: AppColors.deepBrown,
          ),
        ),
      ],
    );
  }
}

class HomesickHeroCard extends StatelessWidget {
  const HomesickHeroCard({
    super.key,
    required this.waitingLetters,
  });

  final int waitingLetters;

  @override
  Widget build(BuildContext context) {
    final waitingText = waitingLetters == 1
        ? '1 letter is waiting for you.'
        : '$waitingLetters letters are waiting for you.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -6,
            right: -2,
            child: Icon(
              Icons.local_florist_outlined,
              size: 62,
              color: AppColors.mutedRose.withValues(alpha: 0.38),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home is only\na letter away.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      height: 1.12,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppColors.terracotta,
                    ),
                  ),

                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      waitingText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.warmBrown,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomesickSectionTitle extends StatelessWidget {
  const HomesickSectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class HomesickPersonCard extends StatelessWidget {
  const HomesickPersonCard({
    super.key,
    required this.person,
    required this.onTap,
  });

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: BotanicalPersonIcon(
                  symbol: person.symbol,
                  size: 48,
                  padding: const EdgeInsets.all(6),
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
                            person.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (person.hasNewWords)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppColors.terracotta,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (person.relationship.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        person.relationship,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${person.letterCount} letters · ${person.memoryCount} memories',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.lastActivity,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: person.hasNewWords
                                ? AppColors.terracotta
                                : AppColors.softGrey,
                            fontWeight: person.hasNewWords
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

class HomesickEmptyState extends StatelessWidget {
  const HomesickEmptyState({
    super.key,
    required this.onInvitePressed,
  });

  final VoidCallback onInvitePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mail_outline_rounded,
            size: 42,
            color: AppColors.terracotta,
          ),
          const SizedBox(height: 16),
          Text(
            'Every meaningful conversation\nstarts with a first letter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onInvitePressed,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Invite someone'),
          ),
        ],
      ),
    );
  }
}

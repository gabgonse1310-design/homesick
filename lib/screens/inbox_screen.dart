import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/delivery_journey.dart';
import '../services/cloud_letter_service.dart';
import '../theme/app_theme.dart';
import 'envelope_opening_screen.dart';
import 'read_letter_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {

  final CloudLetterService _service = CloudLetterService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Words for You'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.watchIncomingLetters(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _InboxMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Your letters could not be loaded',
                message: 'Please check your connection and try again.',
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final records = _service.recordsFromSnapshot(snapshot.data!);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _service.syncIncomingLettersToKeepsakes(records);
            });

            if (records.isEmpty) {
              return const _InboxMessage(
                icon: Icons.mark_email_unread_outlined,
                title: 'No words are waiting yet',
                message:
                    'When someone sends you a letter, its journey will appear here.',
              );
            }

            final travelling = records
                .where((record) => record.isTravelling)
                .toList();
            final arrived = records
                .where((record) => record.hasArrived)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
              children: [
                Text(
                  'Letters take their time here.',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Follow each journey, then open the words when they arrive.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.softGrey,
                        height: 1.45,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (travelling.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _SectionTitle(
                    title: 'Travelling',
                    count: travelling.length,
                  ),
                  const SizedBox(height: 12),
                  ...travelling.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IncomingLetterCard(
                        record: record,
                        onTap: () => _showJourney(context, record),
                      ),
                    ),
                  ),
                ],
                if (arrived.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Arrived',
                    count: arrived.length,
                  ),
                  const SizedBox(height: 12),
                  ...arrived.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IncomingLetterCard(
                        record: record,
                        onTap: () => _openArrivedLetter(context, record),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openArrivedLetter(
    BuildContext context,
    CloudLetterRecord record,
  ) async {
    if (!record.canOpen) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ReadLetterScreen(
            letter: record.letter,
            isIncoming: true,
            senderName: record.displaySender,
          ),
        ),
      );
      return;
    }

    try {
      if (!record.isOpened) {
        await _service.markLetterOpened(record.documentId);
      }

      if (!context.mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => EnvelopeOpeningScreen(
            letter: record.letter,
            isIncoming: true,
            senderName: record.displaySender,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This letter could not be opened right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showJourney(
    BuildContext context,
    CloudLetterRecord record,
  ) async {
    final journey = record.letter.deliveryJourney;
    if (journey == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.local_post_office_outlined,
                  size: 52,
                  color: AppColors.terracotta,
                ),
                const SizedBox(height: 16),
                Text(
                  'A letter from ${record.displaySender}',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  journey.statusLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.terracotta,
                      ),
                ),
                const SizedBox(height: 22),
                LinearProgressIndicator(
                  value: journey.progress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: AppColors.cream,
                ),
                const SizedBox(height: 18),
                _JourneyRoute(journey: journey),
                const SizedBox(height: 18),
                Text(
                  journey.remainingDays == 1
                      ? 'About 1 day remaining'
                      : 'About ${journey.remainingDays} days remaining',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'The letter will unlock automatically when it arrives.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.softGrey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text('$count'),
        ),
      ],
    );
  }
}

class _IncomingLetterCard extends StatelessWidget {
  final CloudLetterRecord record;
  final VoidCallback onTap;

  const _IncomingLetterCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letter = record.letter;
    final journey = letter.deliveryJourney;

    String status;
    IconData statusIcon;

    if (record.isTravelling) {
      status = journey?.remainingDays == 1
          ? '1 day remaining'
          : '${journey?.remainingDays ?? 0} days remaining';
      statusIcon = Icons.flight_takeoff_rounded;
    } else if (!record.canOpen) {
      status = 'Waiting for its moment';
      statusIcon = Icons.lock_clock_outlined;
    } else if (record.isOpened) {
      status = 'Opened';
      statusIcon = Icons.drafts_outlined;
    } else {
      status = 'Ready to open';
      statusIcon = Icons.mark_email_unread_outlined;
    }

    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: !record.isOpened && record.hasArrived
                  ? AppColors.terracotta
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  statusIcon,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displaySender,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      letter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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

class _JourneyRoute extends StatelessWidget {
  final DeliveryJourney journey;

  const _JourneyRoute({required this.journey});

  @override
  Widget build(BuildContext context) {
    final origin = [
      journey.originCity,
      journey.originCountry,
    ].where((value) => value.trim().isNotEmpty).join(', ');

    final destination = [
      journey.destinationCity,
      journey.destinationCountry,
    ].where((value) => value.trim().isNotEmpty).join(', ');

    return Row(
      children: [
        Expanded(
          child: Text(
            origin.isEmpty ? 'On its way' : origin,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.terracotta,
          ),
        ),
        Expanded(
          child: Text(
            destination.isEmpty ? 'Destination' : destination,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _InboxMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InboxMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 32),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 54, color: AppColors.terracotta),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 9),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
}

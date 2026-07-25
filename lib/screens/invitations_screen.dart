import 'package:flutter/material.dart';

import '../models/connection_invitation.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final FirestoreService _service = FirestoreService.instance;
  final Set<String> _working = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Invitations'),
      ),
      body: StreamBuilder<List<ConnectionInvitation>>(
        stream: _service.watchIncomingInvitations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('We could not load your invitations.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final invitations = snapshot.data!;

          if (invitations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No invitations are waiting right now.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: invitations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invitation = invitations[index];

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.senderName.isEmpty
                          ? invitation.senderEmail
                          : invitation.senderName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'invited you to connect on Homesick.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (invitation.relationship.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        invitation.relationship,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.softGrey,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _working.contains(invitation.id)
                                ? null
                                : () async {
                                    setState(() => _working.add(invitation.id));
                                    try {
                                      await _service.declineInvitation(invitation);
                                    } finally {
                                      if (mounted) {
                                        setState(() => _working.remove(invitation.id));
                                      }
                                    }
                                  },
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _working.contains(invitation.id)
                                ? null
                                : () async {
                                    setState(() => _working.add(invitation.id));
                                    try {
                                      await _service.acceptInvitation(invitation);

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Connection accepted.'),
                                        ),
                                      );
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'The invitation could not be accepted.',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => _working.remove(invitation.id));
                                      }
                                    }
                                  },
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

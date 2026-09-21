import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../models/person.dart';
import '../services/family_service.dart';
import '../theme/app_theme.dart';
import '../widgets/homesick_banner_ad.dart';

class FamilyHubScreen extends StatefulWidget {
  const FamilyHubScreen({super.key, required this.people});

  final List<Person> people;

  @override
  State<FamilyHubScreen> createState() => _FamilyHubScreenState();
}

class _FamilyHubScreenState extends State<FamilyHubScreen>
    with SingleTickerProviderStateMixin {
  final FamilyService _service = FamilyService.instance;
  late final TabController _tabs;
  String? _circleId;
  Object? _loadError;
  bool _easyRead = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadCircle();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadCircle() async {
    try {
      final id = await _service.ensureFamilyCircle(
        connectedUserIds: widget.people
            .where((person) => person.isConnected)
            .map((person) => person.recipientUid!)
            .toSet(),
      );
      if (mounted) setState(() => _circleId = id);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final circleId = _circleId;
    final content = _loadError != null
        ? _ErrorView(onRetry: _loadCircle)
        : circleId == null
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [
              _TodayTab(circleId: circleId, service: _service),
              _AgendaTab(circleId: circleId, service: _service),
              _TasksTab(circleId: circleId, service: _service),
              _UpdatesTab(circleId: circleId, service: _service),
            ],
          );

    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(_easyRead ? 1.2 : 1)),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(context.familyText('familyHub')),
          actions: [
            PopupMenuButton<bool>(
              tooltip: context.familyText('elderMode'),
              initialValue: _easyRead,
              onSelected: (value) => setState(() => _easyRead = value),
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: !_easyRead,
                  checked: _easyRead,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.familyText('elderMode')),
                      Text(
                        context.familyText('elderModeHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.text_fields_rounded),
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: [
              Tab(text: context.familyText('today')),
              Tab(text: context.familyText('agenda')),
              Tab(text: context.familyText('tasks')),
              Tab(text: context.familyText('updates')),
            ],
          ),
        ),
        body: content,
        bottomNavigationBar: const SafeArea(child: HomesickBannerAd()),
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.circleId, required this.service});

  final String circleId;
  final FamilyService service;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _WelcomeCard(),
        const SizedBox(height: 18),
        Text(
          context.familyText('today'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.watchEvents(circleId),
          builder: (context, snapshot) {
            final now = DateTime.now();
            final events =
                snapshot.data?.docs.where((doc) {
                  final date = _date(doc.data()['startsAt']);
                  return date != null &&
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                }).toList() ??
                [];
            if (events.isEmpty) {
              return _EmptyCard(text: context.familyText('todayEmpty'));
            }
            return Column(
              children: events
                  .map((doc) => _EventCard(data: doc.data()))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: context.familyText('updates'),
          action: context.familyText('shareUpdate'),
          onPressed: () => _showUpdateDialog(context, circleId, service),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.watchUpdates(circleId),
          builder: (context, snapshot) {
            final updates = snapshot.data?.docs.take(3).toList() ?? [];
            if (updates.isEmpty) {
              return _EmptyCard(text: context.familyText('noUpdates'));
            }
            return Column(
              children: updates
                  .map((doc) => _UpdateCard(data: doc.data()))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AgendaTab extends StatelessWidget {
  const _AgendaTab({required this.circleId, required this.service});

  final String circleId;
  final FamilyService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchEvents(circleId),
      builder: (context, snapshot) {
        final events =
            snapshot.data?.docs.where((doc) {
              final date = _date(doc.data()['startsAt']);
              return date == null || date.isAfter(DateTime.now());
            }).toList() ??
            [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              title: context.familyText('agenda'),
              action: context.familyText('addEvent'),
              onPressed: () => _showEventDialog(context, circleId, service),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (events.isEmpty)
              _EmptyCard(text: context.familyText('noEvents'))
            else
              ...events.map((doc) => _EventCard(data: doc.data())),
          ],
        );
      },
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.circleId, required this.service});

  final String circleId;
  final FamilyService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchTasks(circleId),
      builder: (context, snapshot) {
        final tasks = snapshot.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              title: context.familyText('tasks'),
              action: context.familyText('addTask'),
              onPressed: () => _showTaskDialog(context, circleId, service),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (tasks.isEmpty)
              _EmptyCard(text: context.familyText('noTasks'))
            else
              ...tasks.map(
                (doc) => _TaskCard(
                  data: doc.data(),
                  onClaim: () => service.claimTask(circleId, doc.id),
                  onComplete: () => service.completeTask(circleId, doc.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UpdatesTab extends StatelessWidget {
  const _UpdatesTab({required this.circleId, required this.service});

  final String circleId;
  final FamilyService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchUpdates(circleId),
      builder: (context, snapshot) {
        final updates = snapshot.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              title: context.familyText('updates'),
              action: context.familyText('shareUpdate'),
              onPressed: () => _showUpdateDialog(context, circleId, service),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (updates.isEmpty)
              _EmptyCard(text: context.familyText('noUpdates'))
            else
              ...updates.map((doc) => _UpdateCard(data: doc.data())),
          ],
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warmPaper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.diversity_1_rounded,
            size: 38,
            color: AppColors.terracotta,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.familyText('familyWelcome'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(context.familyText('connectedMembers')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: Text(action),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final startsAt = _date(data['startsAt']);
    return _FamilyCard(
      icon: Icons.event_rounded,
      title: data['title']?.toString() ?? '',
      subtitle: [
        if (startsAt != null) _formatDateTime(context, startsAt),
        if ((data['details']?.toString() ?? '').isNotEmpty)
          data['details'].toString(),
      ].join('\n'),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.data,
    required this.onClaim,
    required this.onComplete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onClaim;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final completed = data['completed'] == true;
    final claimedBy = data['claimedByName']?.toString() ?? '';
    return _FamilyCard(
      icon: completed ? Icons.check_circle_rounded : Icons.volunteer_activism,
      title: data['title']?.toString() ?? '',
      subtitle: [
        if ((data['details']?.toString() ?? '').isNotEmpty)
          data['details'].toString(),
        if (claimedBy.isNotEmpty)
          '${context.familyText('claimedBy')}: $claimedBy',
      ].join('\n'),
      trailing: completed
          ? Chip(label: Text(context.familyText('completed')))
          : Wrap(
              spacing: 4,
              children: [
                if (claimedBy.isEmpty)
                  TextButton(
                    onPressed: onClaim,
                    child: Text(context.familyText('claim')),
                  ),
                if (claimedBy.isNotEmpty)
                  IconButton(
                    tooltip: context.familyText('complete'),
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_rounded),
                  ),
              ],
            ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final author = data['createdByName']?.toString() ?? '';
    return _FamilyCard(
      icon: Icons.chat_bubble_outline_rounded,
      title: data['message']?.toString() ?? '',
      subtitle: author.isEmpty
          ? ''
          : '${context.familyText('createdBy')}: $author',
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.terracotta),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(subtitle),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.familyText('familyLoadError')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.familyText('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showEventDialog(
  BuildContext context,
  String circleId,
  FamilyService service,
) async {
  final title = TextEditingController();
  final details = TextEditingController();
  var date = DateTime.now();
  var time = TimeOfDay.now();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(context.familyText('addEvent')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: context.familyText('eventTitle'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: details,
                decoration: InputDecoration(
                  labelText: context.familyText('details'),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(_formatDate(context, date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    initialDate: date,
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(time.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked != null) setDialogState(() => time = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.familyText('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              await service.addEvent(
                circleId: circleId,
                title: title.text,
                details: details.text,
                startsAt: DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(context.familyText('save')),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  details.dispose();
}

Future<void> _showTaskDialog(
  BuildContext context,
  String circleId,
  FamilyService service,
) async {
  final title = TextEditingController();
  final details = TextEditingController();
  await _textDialog(
    context: context,
    title: context.familyText('addTask'),
    primaryLabel: context.familyText('taskTitle'),
    primaryController: title,
    secondaryController: details,
    actionLabel: context.familyText('save'),
    onSave: () => service.addTask(
      circleId: circleId,
      title: title.text,
      details: details.text,
    ),
  );
  title.dispose();
  details.dispose();
}

Future<void> _showUpdateDialog(
  BuildContext context,
  String circleId,
  FamilyService service,
) async {
  final message = TextEditingController();
  await _textDialog(
    context: context,
    title: context.familyText('shareUpdate'),
    primaryLabel: context.familyText('updateHint'),
    primaryController: message,
    actionLabel: context.familyText('post'),
    onSave: () => service.addUpdate(circleId: circleId, message: message.text),
  );
  message.dispose();
}

Future<void> _textDialog({
  required BuildContext context,
  required String title,
  required String primaryLabel,
  required TextEditingController primaryController,
  TextEditingController? secondaryController,
  required String actionLabel,
  required Future<void> Function() onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: primaryController,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: primaryLabel),
          ),
          if (secondaryController != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: secondaryController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.familyText('details'),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.familyText('cancel')),
        ),
        ElevatedButton(
          onPressed: () async {
            if (primaryController.text.trim().isEmpty) return;
            await onSave();
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String _formatDate(BuildContext context, DateTime date) {
  final spanish = Localizations.localeOf(context).languageCode == 'es';
  const enMonths = [
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
  const esMonths = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  final months = spanish ? esMonths : enMonths;
  return spanish
      ? '${date.day} de ${months[date.month - 1]} de ${date.year}'
      : '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatDateTime(BuildContext context, DateTime date) {
  final time = TimeOfDay.fromDateTime(date).format(context);
  return '${_formatDate(context, date)} · $time';
}

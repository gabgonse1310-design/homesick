import 'package:flutter/material.dart';

import '../services/profile_storage_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Gabriela');
  final TextEditingController _signatureController =
      TextEditingController(text: 'Gabriela');
  final TextEditingController _closingController =
      TextEditingController(text: 'With love,');

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileStorageService.instance.loadProfile();

      if (!mounted) return;

      setState(() {
        _nameController.text = profile.name;
        _signatureController.text = profile.signature;
        _closingController.text = profile.closing;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not load your profile.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _signatureController.dispose();
    _closingController.dispose();
    super.dispose();
  }

  Future<void> _toggleEditing() async {
    if (_isSaving) return;

    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
      return;
    }

    final name = _nameController.text.trim();
    final signature = _signatureController.text.trim();
    final closing = _closingController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    if (signature.isEmpty) {
      _showMessage('Please enter your letter signature.');
      return;
    }

    if (closing.isEmpty) {
      _showMessage('Please enter a letter closing.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ProfileStorageService.instance.saveProfile(
        name: name,
        signature: signature,
        closing: closing,
      );

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      _showMessage('Profile saved.');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('We could not save your profile.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
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
                const SizedBox(height: 22),
                Text(
                  'Profile photo',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.terracotta,
                  ),
                  title: const Text('Choose from photos'),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon('Photo selection');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.terracotta,
                  ),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon('Camera access');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    _showMessage('$feature will be connected soon.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Your Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading || _isSaving ? null : _toggleEditing,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save' : 'Edit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.local_florist_outlined,
                                color: AppColors.terracotta,
                                size: 46,
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: InkWell(
                                  onTap: _showPhotoOptions,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.terracotta,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.cream,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text.trim().isEmpty
                              ? 'Your name'
                              : _nameController.text.trim(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Everlasting words.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.softGrey,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _ProfileSectionTitle(title: 'About you'),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    child: Column(
                      children: [
                        _ProfileField(
                          label: 'Name',
                          controller: _nameController,
                          enabled: _isEditing,
                          hintText: 'Your name',
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),
                        const _StaticProfileRow(
                          label: 'Language',
                          value: 'English',
                          icon: Icons.language_rounded,
                        ),
                        const SizedBox(height: 18),
                        const _StaticProfileRow(
                          label: 'Member since',
                          value: '2026',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _ProfileSectionTitle(title: 'Your letters'),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileField(
                          label: 'Letter closing',
                          controller: _closingController,
                          enabled: _isEditing,
                          hintText: 'With love,',
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),
                        _ProfileField(
                          label: 'Signature',
                          controller: _signatureController,
                          enabled: _isEditing,
                          hintText: 'Your name',
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Letter preview',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.softGrey,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Dear Mom,',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'I wanted to write these words down so you could keep them close.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      height: 1.55,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _closingController.text.trim().isEmpty
                                    ? 'With love,'
                                    : _closingController.text.trim(),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _signatureController.text.trim().isEmpty
                                    ? 'Your name'
                                    : _signatureController.text.trim(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _ProfileSectionTitle(title: 'Account'),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    child: Column(
                      children: [
                        _ProfileActionRow(
                          icon: Icons.email_outlined,
                          title: 'Email address',
                          subtitle: 'Manage your sign-in email',
                          onTap: () =>
                              _showComingSoon('Email management'),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 56),
                          child: Divider(height: 1),
                        ),
                        _ProfileActionRow(
                          icon: Icons.lock_outline_rounded,
                          title: 'Password and security',
                          subtitle: 'Keep your account protected',
                          onTap: () =>
                              _showComingSoon('Security settings'),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _toggleEditing,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Profile'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String title;

  const _ProfileSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.softGrey,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;

  const _ProfileCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.textCapitalization,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _StaticProfileRow(
        label: label,
        value: controller.text.trim().isEmpty ? 'Not added' : controller.text,
        icon: label == 'Name'
            ? Icons.person_outline_rounded
            : Icons.edit_note_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.softGrey,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
          ),
        ),
      ],
    );
  }
}

class _StaticProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StaticProfileRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            color: AppColors.terracotta,
            size: 21,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.softGrey,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  icon,
                  color: AppColors.terracotta,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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

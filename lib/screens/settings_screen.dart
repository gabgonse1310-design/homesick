import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _selectedLanguage =>
      AppLanguageController.instance.locale.languageCode == 'es'
      ? 'Español'
      : 'English';
  bool _letterNotifications = true;
  bool _scheduledDeliveryNotifications = true;
  bool _isWorking = false;

  User? get _user => _auth.currentUser;

  Future<void> _chooseLanguage() async {
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  context.familyText('chooseLanguage'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                _LanguageOption(
                  title: context.familyText('english'),
                  isSelected: _selectedLanguage == 'English',
                  onTap: () => Navigator.pop(context, 'English'),
                ),
                const SizedBox(height: 10),
                _LanguageOption(
                  title: context.familyText('spanish'),
                  isSelected: _selectedLanguage == 'Español',
                  onTap: () => Navigator.pop(context, 'Español'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedLanguage == null || !mounted) return;

    final code = selectedLanguage == 'Español' ? 'es' : 'en';
    await AppLanguageController.instance.setLanguage(code);
    await FirestoreService.instance.updateCurrentUserProfile(
      preferredLanguage: code,
    );
    if (mounted) setState(() {});
  }

  Future<void> _sendVerificationEmail() async {
    final user = _user;
    if (user == null) {
      _showMessage('No signed-in account was found.');
      return;
    }

    if (user.emailVerified) {
      _showMessage('Your email is already verified.');
      return;
    }

    setState(() => _isWorking = true);

    try {
      await user.sendEmailVerification();
      if (mounted) {
        _showMessage(
          'Verification email sent to ${user.email ?? 'your email'}.',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showMessage(
          error.message ?? 'We could not send the verification email.',
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email;
    if (email == null || email.trim().isEmpty) {
      _showMessage('No email address is linked to this account.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset password?'),
        content: Text('We will send password reset instructions to $email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isWorking = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showMessage('Password reset email sent.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'We could not send the reset email.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _refreshAccount() async {
    final user = _user;
    if (user == null) return;

    setState(() => _isWorking = true);

    try {
      await user.reload();
      if (mounted) {
        setState(() {});
        _showMessage(
          _auth.currentUser?.emailVerified == true
              ? 'Your email is verified.'
              : 'Your email is still awaiting verification.',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'We could not refresh your account.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Sign out?'),
          content: const Text(
            'Your letters and keepsakes will remain safely stored.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) return;

    setState(() => _isWorking = true);

    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _isWorking = false);
        _showMessage(error.message ?? 'We could not sign you out.');
      }
    }
  }

  void _showComingSoon(String feature) {
    _showMessage('$feature will be connected before release.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showAboutHomesick() {
    showAboutDialog(
      context: context,
      applicationName: 'Homesick',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cream,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.local_florist_outlined,
          color: AppColors.terracotta,
          size: 30,
        ),
      ),
      children: const [
        SizedBox(height: 10),
        Text('Everlasting words.'),
        SizedBox(height: 6),
        Text('Home is only a letter away.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final email = user?.email ?? 'No email available';
    final displayName = user?.displayName?.trim();
    final isVerified = user?.emailVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
              children: [
                Text(
                  'Make Homesick your own.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your account, letters and preferences.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.softGrey),
                ),
                const SizedBox(height: 28),
                const _SettingsSectionTitle(title: 'Your account'),
                const SizedBox(height: 12),
                _AccountHeader(
                  name: displayName?.isNotEmpty == true
                      ? displayName!
                      : email.split('@').first,
                  email: email,
                  isVerified: isVerified,
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Your Profile',
                      subtitle: 'Name, photo and letter signature',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: isVerified
                          ? Icons.verified_outlined
                          : Icons.mark_email_unread_outlined,
                      title: isVerified
                          ? 'Email verified'
                          : 'Verify your email',
                      subtitle: isVerified
                          ? email
                          : 'Send a verification link to $email',
                      onTap: isVerified
                          ? _refreshAccount
                          : _sendVerificationEmail,
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.refresh_rounded,
                      title: 'Refresh verification status',
                      subtitle: 'Check after opening the verification email',
                      onTap: _refreshAccount,
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Change password',
                      subtitle: 'Receive a secure password reset email',
                      onTap: _sendPasswordReset,
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: context.familyText('language'),
                      subtitle: _selectedLanguage,
                      onTap: _chooseLanguage,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _SettingsSectionTitle(title: 'Letters'),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'Letter notifications',
                      subtitle: 'Let me know when a letter arrives',
                      value: _letterNotifications,
                      onChanged: (value) {
                        setState(() => _letterNotifications = value);
      
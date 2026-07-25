import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorageService {
  ProfileStorageService._();

  static final ProfileStorageService instance =
  ProfileStorageService._();

  static const String _nameKey = 'profile_name';
  static const String _signatureKey = 'profile_signature';
  static const String _closingKey = 'profile_closing';

  Future<UserProfileData> loadProfile() async {
    final preferences = await SharedPreferences.getInstance();

    return UserProfileData(
      name: preferences.getString(_nameKey) ?? 'Gabriela',
      signature:
      preferences.getString(_signatureKey) ?? 'Gabriela',
      closing:
      preferences.getString(_closingKey) ?? 'With love,',
    );
  }

  Future<void> saveProfile({
    required String name,
    required String signature,
    required String closing,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.setString(_nameKey, name),
      preferences.setString(_signatureKey, signature),
      preferences.setString(_closingKey, closing),
    ]);
  }

  Future<void> clearProfile() async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.remove(_nameKey),
      preferences.remove(_signatureKey),
      preferences.remove(_closingKey),
    ]);
  }
}

class UserProfileData {
  final String name;
  final String signature;
  final String closing;

  const UserProfileData({
    required this.name,
    required this.signature,
    required this.closing,
  });
}
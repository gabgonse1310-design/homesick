import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PhotoStorageService {
  PhotoStorageService._();

  static final PhotoStorageService instance = PhotoStorageService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    return user;
  }

  /// Uploads a single photo and returns its Firebase download URL.
  Future<String> uploadPhoto({
    required String letterId,
    required String localPath,
  }) async {
    final file = File(localPath);

    if (!await file.exists()) {
      throw ArgumentError('The selected photo does not exist: $localPath');
    }

    final extension = _fileExtension(localPath);
    final filename =
        'photo_${DateTime.now().microsecondsSinceEpoch}$extension';

    final reference = _storage
        .ref()
        .child('users')
        .child(_currentUser.uid)
        .child('letters')
        .child(letterId)
        .child(filename);

    final metadata = SettableMetadata(
      contentType: _contentTypeForExtension(extension),
      customMetadata: {
        'letterId': letterId,
        'uploadedBy': _currentUser.uid,
      },
    );

    final uploadTask = await reference.putFile(file, metadata);

    return uploadTask.ref.getDownloadURL();
  }

  /// Uploads several photos and returns their Firebase download URLs.
  ///
  /// Uploads are performed one by one so a failed upload is easier to identify
  /// and does not overwhelm slower mobile connections.
  Future<List<String>> uploadPhotos({
    required String letterId,
    required List<String> localPaths,
  }) async {
    final downloadUrls = <String>[];

    for (final localPath in localPaths) {
      final url = await uploadPhoto(
        letterId: letterId,
        localPath: localPath,
      );

      downloadUrls.add(url);
    }

    return downloadUrls;
  }

  /// Deletes a Firebase Storage file using its download URL.
  ///
  /// Local filesystem paths are ignored because they are not Storage objects.
  Future<void> deletePhotoByUrl(String photoUrl) async {
    if (!_isRemoteUrl(photoUrl)) {
      return;
    }

    try {
      await _storage.refFromURL(photoUrl).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        return;
      }

      rethrow;
    }
  }

  /// Deletes all remote photos associated with a letter.
  Future<void> deletePhotosByUrls(List<String> photoUrls) async {
    for (final photoUrl in photoUrls) {
      await deletePhotoByUrl(photoUrl);
    }
  }

  /// Deletes the complete Firebase Storage folder for one letter.
  ///
  /// Firebase Storage does not delete folders directly, so every stored item
  /// in the folder is listed and deleted individually.
  Future<void> deleteLetterFolder(String letterId) async {
    final folder = _storage
        .ref()
        .child('users')
        .child(_currentUser.uid)
        .child('letters')
        .child(letterId);

    await _deleteAllItems(folder);
  }

  Future<void> _deleteAllItems(Reference folder) async {
    String? pageToken;

    do {
      final result = await folder.list(
        ListOptions(
          maxResults: 1000,
          pageToken: pageToken,
        ),
      );

      for (final item in result.items) {
        try {
          await item.delete();
        } on FirebaseException catch (error) {
          if (error.code != 'object-not-found') {
            rethrow;
          }
        }
      }

      for (final prefix in result.prefixes) {
        await _deleteAllItems(prefix);
      }

      pageToken = result.nextPageToken;
    } while (pageToken != null);
  }

  bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  String _fileExtension(String path) {
    final normalizedPath = path.split('?').first;
    final lastDot = normalizedPath.lastIndexOf('.');

    if (lastDot == -1) {
      return '.jpg';
    }

    final extension = normalizedPath.substring(lastDot).toLowerCase();

    if (extension.length > 6) {
      return '.jpg';
    }

    return extension;
  }

  String _contentTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/letter.dart';
import '../models/person.dart';
import 'firestore_service.dart';
import 'letter_service.dart';

class CloudLetterRecord {
  final String documentId;
  final Letter letter;
  final String senderUid;
  final String senderName;
  final String senderEmail;
  final bool isOpened;
  final DateTime? sentAt;
  final DateTime? openedAt;

  const CloudLetterRecord({
    required this.documentId,
    required this.letter,
    required this.senderUid,
    required this.senderName,
    required this.senderEmail,
    required this.isOpened,
    required this.sentAt,
    required this.openedAt,
  });

  bool get isTravelling => letter.isTravelling;
  bool get hasArrived => !letter.isTravelling;
  bool get canOpen => letter.canOpen;

  String get displaySender {
    final name = senderName.trim();
    if (name.isNotEmpty) return name;

    final email = senderEmail.trim();
    if (email.isNotEmpty) return email.split('@').first;

    return 'Someone special';
  }

  factory CloudLetterRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = Map<String, dynamic>.from(document.data());
    final letterJson = <String, dynamic>{
      'id': data['id']?.toString() ?? document.id,
      'personKey': data['recipientPersonId']?.toString() ?? '',
      'recipientName': data['recipientName']?.toString() ?? '',
      'recipientRelationship':
          data['recipientRelationship']?.toString() ?? '',
      'title': data['title']?.toString() ?? 'Untitled Letter',
      'body': data['body']?.toString() ?? '',
      'createdAt': _dateAsIso(data['createdAt']) ??
          _dateAsIso(data['sentAt']) ??
          DateTime.now().toIso8601String(),
      'updatedAt': _dateAsIso(data['updatedAt']) ??
          _dateAsIso(data['sentAt']) ??
          DateTime.now().toIso8601String(),
      'isDraft': false,
      'isFavorite': false,
      'isTimeCapsule': data['isTimeCapsule'] as bool? ?? false,
      'openDate': _dateAsIso(data['openDate']),
      'capsuleAccessMode':
          data['capsuleAccessMode']?.toString() ?? 'onlyMe',
      'authorizedPersonKeys':
          data['authorizedPersonKeys'] as List<dynamic>? ?? const [],
      'authorizedPersonNames':
          data['authorizedPersonNames'] as List<dynamic>? ?? const [],
      'letterType': data['letterType']?.toString() ?? 'typed',
      'pages': data['pages'] as List<dynamic>? ?? const [],
      'photoPaths': data['photoPaths'] as List<dynamic>? ?? const [],
      'postcardImagePath': data['postcardImagePath']?.toString(),
      'deliveryJourney': data['deliveryJourney'],
    };

    return CloudLetterRecord(
      documentId: document.id,
      letter: Letter.fromJson(letterJson),
      senderUid: data['senderUid']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      senderEmail: data['senderEmail']?.toString() ?? '',
      isOpened: data['isOpened'] as bool? ?? false,
      sentAt: _readDate(data['sentAt']) ?? _readDate(data['createdAt']),
      openedAt: _readDate(data['openedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? _dateAsIso(dynamic value) {
    return _readDate(value)?.toIso8601String();
  }
}

class CloudLetterService {
  CloudLetterService._();

  static final CloudLetterService instance = CloudLetterService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'A signed-in user is required to use cloud letters.',
      );
    }

    return user;
  }

  CollectionReference<Map<String, dynamic>> get _sharedLetters =>
      _firestore.collection('sharedLetters');

  Future<String> sendSealedLetter({
    required Letter letter,
    required Person recipient,
  }) async {
    if (letter.isDraft) {
      throw StateError('Drafts cannot be sent.');
    }

    if (!recipient.isConnected ||
        recipient.recipientUid == null ||
        recipient.recipientUid!.trim().isEmpty) {
      throw StateError(
        '${recipient.name} is not connected on Homesick yet.',
      );
    }

    final sender = _currentUser;
    final reference = _sharedLetters.doc(letter.id);

    await reference.set({
      'id': letter.id,
      'senderUid': sender.uid,
      'senderName': sender.displayName?.trim() ?? '',
      'senderEmail': sender.email?.trim().toLowerCase() ?? '',
      'recipientUid': recipient.recipientUid!.trim(),
      'recipientName': recipient.name,
      'recipientRelationship': recipient.relationship,
      'recipientEmail': recipient.email.trim().toLowerCase(),
      'recipientPersonId': recipient.personKey,
      'title': letter.title,
      'body': letter.body,
      'letterType': letter.letterType.name,
      'pages': letter.pages.map((page) => page.toJson()).toList(),
      'photoPaths': letter.photoPaths,
      'postcardImagePath': letter.postcardImagePath,
      'isTimeCapsule': letter.isTimeCapsule,
      'openDate': letter.openDate?.toIso8601String(),
      'capsuleAccessMode': letter.capsuleAccessMode,
      'authorizedPersonKeys': letter.authorizedPersonKeys,
      'authorizedPersonNames': letter.authorizedPersonNames,
      'deliveryJourney': letter.deliveryJourney?.toMap(),
      'sentAt': FieldValue.serverTimestamp(),
      'createdAt': letter.createdAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'openedAt': null,
      'isOpened': false,
    });

    return reference.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchIncomingLetters() {
    return _sharedLetters
        .where('recipientUid', isEqualTo: _currentUser.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOutgoingLetters() {
    return _sharedLetters
        .where('senderUid', isEqualTo: _currentUser.uid)
        .snapshots();
  }

  List<CloudLetterRecord> recordsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final records = snapshot.docs
        .map(CloudLetterRecord.fromDocument)
        .toList();

    records.sort((a, b) {
      final aDate = a.sentAt ?? a.letter.createdAt;
      final bDate = b.sentAt ?? b.letter.createdAt;
      return bDate.compareTo(aDate);
    });

    return records;
  }


  Future<void> syncIncomingLettersToKeepsakes(
    List<CloudLetterRecord> records,
  ) async {
    for (final record in records) {
      if (!record.hasArrived) continue;

      await FirestoreService.instance.ensureConnectedPersonForSender(
        senderUid: record.senderUid,
        senderName: record.senderName,
        senderEmail: record.senderEmail,
      );

      final localId = 'incoming_${record.documentId}';
      final existing = await LetterService.instance.findLetter(localId);

      final incomingCopy = record.letter.copyWith(
        id: localId,
        personKey: record.senderUid,
        recipientName: record.displaySender,
        recipientRelationship: 'Connected on Homesick',
        isIncoming: true,
        senderName: record.displaySender,
        cloudDocumentId: record.documentId,
        updatedAt: record.sentAt ?? record.letter.updatedAt,
      );

      if (existing == null ||
          existing.updatedAt.isBefore(incomingCopy.updatedAt)) {
        await LetterService.instance.saveLetter(incomingCopy);
      }
    }
  }

  Future<void> markLetterOpened(String letterId) async {
    final reference = _sharedLetters.doc(letterId);
    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw StateError('This letter no longer exists.');
    }

    final data = snapshot.data()!;
    final recipientUid = data['recipientUid']?.toString() ?? '';

    if (recipientUid != _currentUser.uid) {
      throw StateError('Only the recipient can open this letter.');
    }

    await reference.update({
      'isOpened': true,
      'openedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final senderUid = data['senderUid']?.toString() ?? '';
    if (senderUid.isNotEmpty) {
      await FirestoreService.instance.markPersonHasNewWords(
        personId: senderUid,
        hasNewWords: false,
        lastActivity: 'Letter opened',
      );
    }
  }

  Future<void> deleteOutgoingLetter(String letterId) async {
    final reference = _sharedLetters.doc(letterId);
    final snapshot = await reference.get();

    if (!snapshot.exists) return;

    final senderUid = snapshot.data()?['senderUid']?.toString() ?? '';

    if (senderUid != _currentUser.uid) {
      throw StateError('Only the sender can remove this letter.');
    }

    await reference.delete();
  }
}

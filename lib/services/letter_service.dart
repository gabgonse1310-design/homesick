import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/delivery_journey.dart';
import '../models/letter.dart';

class LetterService {
  LetterService._();

  static final LetterService instance = LetterService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'A signed-in user is required to access letters.',
      );
    }

    return user;
  }

  CollectionReference<Map<String, dynamic>> get _lettersCollection {
    return _firestore
        .collection('users')
        .doc(_currentUser.uid)
        .collection('letters');
  }

  Future<void> saveLetter(Letter letter) async {
    final letterId = letter.id.trim().isEmpty
        ? _lettersCollection.doc().id
        : letter.id.trim();

    await _lettersCollection.doc(letterId).set(
      _letterToFirestore(
        letter.copyWith(id: letterId),
      ),
      SetOptions(merge: true),
    );
  }

  Future<List<Letter>> loadLetters() async {
    final snapshot = await _lettersCollection
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map(_letterFromDocument).toList();
  }

  Future<List<Letter>> loadLettersForPerson(
    String personKey,
  ) async {
    final snapshot = await _lettersCollection
        .where('personKey', isEqualTo: personKey)
        .get();

    final letters = snapshot.docs
        .map(_letterFromDocument)
        .toList();

    letters.sort(
      (first, second) =>
          second.updatedAt.compareTo(first.updatedAt),
    );

    return letters;
  }

  Stream<List<Letter>> watchLetters() {
    return _lettersCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_letterFromDocument).toList(),
        );
  }

  Stream<List<Letter>> watchLettersForPerson(
    String personKey,
  ) {
    return _lettersCollection
        .where('personKey', isEqualTo: personKey)
        .snapshots()
        .map((snapshot) {
      final letters =
          snapshot.docs.map(_letterFromDocument).toList();

      letters.sort(
        (first, second) =>
            second.updatedAt.compareTo(first.updatedAt),
      );

      return letters;
    });
  }

  Future<Letter?> findLetter(String id) async {
    final snapshot = await _lettersCollection.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return _letterFromSnapshot(snapshot);
  }

  Future<void> setFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    await _lettersCollection.doc(id).update({
      'isFavorite': isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLetter(String id) async {
    await _lettersCollection.doc(id).delete();
  }

  Future<void> clearLetters() async {
    final snapshot = await _lettersCollection.get();
    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }

  Map<String, dynamic> _letterToFirestore(Letter letter) {
    return {
      'id': letter.id,
      'personKey': letter.personKey,
      'recipientName': letter.recipientName,
      'recipientRelationship': letter.recipientRelationship,
      'title': letter.title,
      'body': letter.body,
      'createdAt': Timestamp.fromDate(letter.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'isDraft': letter.isDraft,
      'isFavorite': letter.isFavorite,
      'isTimeCapsule': letter.isTimeCapsule,
      'openDate': letter.openDate == null
          ? null
          : Timestamp.fromDate(letter.openDate!),
      'capsuleAccessMode': letter.capsuleAccessMode,
      'authorizedPersonKeys': letter.authorizedPersonKeys,
      'authorizedPersonNames': letter.authorizedPersonNames,
      'letterType': letter.letterType.name,
      'pages': letter.pages
          .map(
            (page) => {
              'id': page.id,
              'type': page.type.name,
              'imagePath': page.imagePath,
              'pageNumber': page.pageNumber,
              'createdAt': Timestamp.fromDate(page.createdAt),
            },
          )
          .toList(),
      'photoPaths': letter.photoPaths,
      'postcardImagePath': letter.postcardImagePath,
      'isIncoming': letter.isIncoming,
      'senderName': letter.senderName,
      'cloudDocumentId': letter.cloudDocumentId,
      'deliveryJourney': letter.deliveryJourney == null
          ? null
          : {
              'deliveryMode': letter.deliveryJourney!.mode.name,
              'originCountry':
                  letter.deliveryJourney!.originCountry,
              'originCity': letter.deliveryJourney!.originCity,
              'destinationCountry':
                  letter.deliveryJourney!.destinationCountry,
              'destinationCity':
                  letter.deliveryJourney!.destinationCity,
              'sentAt':
                  Timestamp.fromDate(letter.deliveryJourney!.sentAt),
              'estimatedArrival': Timestamp.fromDate(
                letter.deliveryJourney!.estimatedArrival,
              ),
              'estimatedDays':
                  letter.deliveryJourney!.estimatedDays,
            },
    };
  }

  Letter _letterFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return _letterFromData(
      document.id,
      document.data(),
    );
  }

  Letter _letterFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return _letterFromData(
      document.id,
      document.data() ?? const <String, dynamic>{},
    );
  }

  Letter _letterFromData(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return Letter(
      id: data['id'] as String? ?? documentId,
      personKey: data['personKey'] as String? ?? '',
      recipientName: data['recipientName'] as String? ?? '',
      recipientRelationship:
          data['recipientRelationship'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled Letter',
      body: data['body'] as String? ?? '',
      createdAt: _dateFromFirestore(data['createdAt']),
      updatedAt: _dateFromFirestore(data['updatedAt']),
      isDraft: data['isDraft'] as bool? ?? false,
      isFavorite: data['isFavorite'] as bool? ?? false,
      isTimeCapsule: data['isTimeCapsule'] as bool? ?? false,
      openDate: _nullableDateFromFirestore(data['openDate']),
      capsuleAccessMode:
          data['capsuleAccessMode'] as String? ?? 'onlyMe',
      authorizedPersonKeys:
          _stringList(data['authorizedPersonKeys']),
      authorizedPersonNames:
          _stringList(data['authorizedPersonNames']),
      letterType: _letterTypeFromFirestore(data['letterType']),
      pages: _pagesFromFirestore(data['pages']),
      photoPaths: _stringList(data['photoPaths']),
      postcardImagePath: data['postcardImagePath']?.toString(),
      deliveryJourney:
          _deliveryJourneyFromFirestore(data['deliveryJourney']),
      isIncoming: data['isIncoming'] as bool? ?? false,
      senderName: data['senderName']?.toString() ?? '',
      cloudDocumentId: data['cloudDocumentId']?.toString(),
    );
  }

  LetterType _letterTypeFromFirestore(dynamic value) {
    final name = value?.toString();

    return LetterType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => LetterType.typed,
    );
  }

  List<LetterPage> _pagesFromFirestore(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<Map>().map((rawPage) {
      final page = Map<String, dynamic>.from(rawPage);
      final rawType = page['type']?.toString();

      return LetterPage(
        id: page['id']?.toString() ?? '',
        type: LetterPageType.values.firstWhere(
          (type) => type.name == rawType,
          orElse: () => LetterPageType.scanned,
        ),
        imagePath: page['imagePath']?.toString() ?? '',
        pageNumber: (page['pageNumber'] as num?)?.toInt() ?? 0,
        createdAt: _dateFromFirestore(page['createdAt']),
      );
    }).toList();
  }

  DeliveryJourney? _deliveryJourneyFromFirestore(
    dynamic value,
  ) {
    if (value is! Map) {
      return null;
    }

    final data = Map<String, dynamic>.from(value);
    final modeName = data['deliveryMode']?.toString();

    final mode = DeliveryMode.values.firstWhere(
      (item) => item.name == modeName,
      orElse: () => DeliveryMode.instant,
    );

    final sentAt =
        _nullableDateFromFirestore(data['sentAt']) ?? DateTime.now();

    final estimatedDays =
        (data['estimatedDays'] as num?)?.toInt() ?? 0;

    final arrival =
        _nullableDateFromFirestore(data['estimatedArrival']) ??
        sentAt.add(Duration(days: estimatedDays));

    return DeliveryJourney(
      mode: mode,
      originCountry: data['originCountry']?.toString() ?? '',
      originCity: data['originCity']?.toString() ?? '',
      destinationCountry:
          data['destinationCountry']?.toString() ?? '',
      destinationCity: data['destinationCity']?.toString() ?? '',
      sentAt: sentAt,
      estimatedArrival: arrival,
      estimatedDays: estimatedDays,
    );
  }

  DateTime _dateFromFirestore(dynamic value) {
    return _nullableDateFromFirestore(value) ?? DateTime.now();
  }

  DateTime? _nullableDateFromFirestore(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.map((item) => item.toString()).toList();
  }
}

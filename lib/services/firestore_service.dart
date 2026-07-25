import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/connection_invitation.dart';
import '../models/person.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'A signed-in user is required to access Firestore.',
      );
    }

    return user;
  }

  DocumentReference<Map<String, dynamic>> get _currentUserDocument =>
      _firestore.collection('users').doc(_currentUser.uid);

  CollectionReference<Map<String, dynamic>> get _peopleCollection =>
      _currentUserDocument.collection('people');

  CollectionReference<Map<String, dynamic>> get _lettersCollection =>
      _currentUserDocument.collection('letters');

  CollectionReference<Map<String, dynamic>> get _timeCapsulesCollection =>
      _currentUserDocument.collection('timeCapsules');

  CollectionReference<Map<String, dynamic>> get _invitationsCollection =>
      _firestore.collection('connectionInvitations');

  Future<void> ensureCurrentUserProfile() async {
    final user = _currentUser;
    final reference = _currentUserDocument;
    final snapshot = await reference.get();
    final normalizedEmail = _normalizeEmail(user.email ?? '');

    final data = <String, dynamic>{
      'uid': user.uid,
      'displayName': user.displayName?.trim() ?? '',
      'email': user.email?.trim() ?? '',
      'emailNormalized': normalizedEmail,
      'photoUrl': user.photoURL ?? '',
      'emailVerified': user.emailVerified,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await reference.set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final snapshot = await _currentUserDocument.get();
    return snapshot.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchCurrentUserProfile() {
    return _currentUserDocument.snapshots();
  }

  Future<void> updateCurrentUserProfile({
    String? displayName,
    String? photoUrl,
    String? preferredLanguage,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) {
      updates['displayName'] = displayName.trim();
    }

    if (photoUrl != null) {
      updates['photoUrl'] = photoUrl.trim();
    }

    if (preferredLanguage != null) {
      updates['preferredLanguage'] = preferredLanguage.trim();
    }

    await _currentUserDocument.set(
      updates,
      SetOptions(merge: true),
    );
  }

  Future<String> addPerson({
    required String name,
    required String relationship,
    required String symbol,
    String email = '',
    String city = '',
    String country = '',
    int letterCount = 0,
    int memoryCount = 0,
    int? createdYear,
    String lastActivity = 'No letters yet',
    bool hasNewWords = false,
  }) async {
    final personReference = _peopleCollection.doc();
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail.isNotEmpty &&
        normalizedEmail == _normalizeEmail(_currentUser.email ?? '')) {
      throw StateError('You cannot add your own email address.');
    }

    final matchedUser = normalizedEmail.isEmpty
        ? null
        : await findUserByEmail(normalizedEmail);

    final recipientUid = matchedUser?['uid']?.toString();
    final status = recipientUid == null || recipientUid.isEmpty
        ? ConnectionStatus.local
        : ConnectionStatus.connected;

    await personReference.set({
      'id': personReference.id,
      'name': name.trim(),
      'relationship': relationship.trim(),
      'symbol': symbol,
      'email': normalizedEmail,
      'city': city.trim(),
      'country': country.trim(),
      'recipientUid': recipientUid,
      'connectionStatus': status.name,
      'letterCount': letterCount,
      'memoryCount': memoryCount,
      'createdYear': createdYear ?? DateTime.now().year,
      'lastActivity': lastActivity.trim().isEmpty
          ? 'No letters yet'
          : lastActivity.trim(),
      'hasNewWords': hasNewWords,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return personReference.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPeople() {
    return _peopleCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updatePerson(
    String personId,
    Map<String, dynamic> values,
  ) async {
    final updates = Map<String, dynamic>.from(values)
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _peopleCollection.doc(personId).update(updates);
  }

  Future<void> deletePerson(String personId) async {
    await _peopleCollection.doc(personId).delete();
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail.isEmpty) return null;

    final query = await _firestore
        .collection('users')
        .where('emailNormalized', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first.data();
  }

  Future<String> sendConnectionInvitation({
    required Person person,
  }) async {
    final email = _normalizeEmail(person.email);

    if (email.isEmpty) {
      throw StateError('An email address is required.');
    }

    if (email == _normalizeEmail(_currentUser.email ?? '')) {
      throw StateError('You cannot invite your own email address.');
    }

    final recipient = await findUserByEmail(email);
    final recipientUid = recipient?['uid']?.toString() ?? '';

    final existing = await _invitationsCollection
        .where('senderUid', isEqualTo: _currentUser.uid)
        .where('recipientEmail', isEqualTo: email)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final invitation = _invitationsCollection.doc();

    await invitation.set({
      'id': invitation.id,
      'senderUid': _currentUser.uid,
      'senderName': _currentUser.displayName?.trim() ?? '',
      'senderEmail': _normalizeEmail(_currentUser.email ?? ''),
      'recipientEmail': email,
      'recipientUid': recipientUid,
      'personId': person.personKey,
      'relationship': person.relationship,
      'status': InvitationStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _peopleCollection.doc(person.personKey).set({
      'email': email,
      'recipientUid': recipientUid.isEmpty ? null : recipientUid,
      'connectionStatus': recipientUid.isEmpty
          ? ConnectionStatus.invited.name
          : ConnectionStatus.connected.name,
      'lastActivity': recipientUid.isEmpty
          ? 'Invitation pending'
          : 'Connected on Homesick',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return invitation.id;
  }

  Stream<List<ConnectionInvitation>> watchIncomingInvitations() {
    final email = _normalizeEmail(_currentUser.email ?? '');

    return _invitationsCollection
        .where('recipientEmail', isEqualTo: email)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => ConnectionInvitation.fromMap(
                  document.id,
                  document.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> acceptInvitation(ConnectionInvitation invitation) async {
    final batch = _firestore.batch();

    final invitationReference =
        _invitationsCollection.doc(invitation.id);

    batch.update(invitationReference, {
      'recipientUid': _currentUser.uid,
      'status': InvitationStatus.accepted.name,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final senderPersonReference = _firestore
        .collection('users')
        .doc(invitation.senderUid)
        .collection('people')
        .doc(invitation.personId);

    batch.set(
      senderPersonReference,
      {
        'recipientUid': _currentUser.uid,
        'connectionStatus': ConnectionStatus.connected.name,
        'lastActivity': 'Connected on Homesick',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final reversePersonReference = _currentUserDocument
        .collection('people')
        .doc(invitation.senderUid);

    batch.set(
      reversePersonReference,
      {
        'id': invitation.senderUid,
        'name': invitation.senderName.isEmpty
            ? invitation.senderEmail
            : invitation.senderName,
        'relationship': invitation.relationship,
        'symbol': 'assets/images/flowers/blossom.png',
        'email': invitation.senderEmail,
        'city': '',
        'country': '',
        'recipientUid': invitation.senderUid,
        'connectionStatus': ConnectionStatus.connected.name,
        'letterCount': 0,
        'memoryCount': 0,
        'createdYear': DateTime.now().year,
        'lastActivity': 'Connected on Homesick',
        'hasNewWords': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> declineInvitation(ConnectionInvitation invitation) async {
    await _invitationsCollection.doc(invitation.id).update({
      'status': InvitationStatus.declined.name,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> watchUnreadIncomingLetterCount() {
    return _firestore
        .collection('sharedLetters')
        .where('recipientUid', isEqualTo: _currentUser.uid)
        .where('isOpened', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markPersonHasNewWords({
    required String personId,
    required bool hasNewWords,
    int? letterCount,
    String? lastActivity,
  }) async {
    final updates = <String, dynamic>{
      'hasNewWords': hasNewWords,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (letterCount != null) {
      updates['letterCount'] = letterCount;
    }

    if (lastActivity != null) {
      updates['lastActivity'] = lastActivity;
    }

    await _peopleCollection.doc(personId).set(
      updates,
      SetOptions(merge: true),
    );
  }

  Future<void> ensureConnectedPersonForSender({
    required String senderUid,
    required String senderName,
    required String senderEmail,
  }) async {
    final reference = _peopleCollection.doc(senderUid);
    final snapshot = await reference.get();

    if (snapshot.exists) {
      await reference.set({
        'recipientUid': senderUid,
        'connectionStatus': ConnectionStatus.connected.name,
        'hasNewWords': true,
        'lastActivity': 'New words arrived',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await reference.set({
      'id': senderUid,
      'name': senderName.trim().isEmpty ? senderEmail : senderName.trim(),
      'relationship': 'Connected on Homesick',
      'symbol': 'assets/images/flowers/blossom.png',
      'email': senderEmail.trim().toLowerCase(),
      'city': '',
      'country': '',
      'recipientUid': senderUid,
      'connectionStatus': ConnectionStatus.connected.name,
      'letterCount': 1,
      'memoryCount': 0,
      'createdYear': DateTime.now().year,
      'lastActivity': 'New words arrived',
      'hasNewWords': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  DocumentReference<Map<String, dynamic>> newLetterDocument() =>
      _lettersCollection.doc();

  DocumentReference<Map<String, dynamic>> newTimeCapsuleDocument() =>
      _timeCapsulesCollection.doc();

  String _normalizeEmail(String email) =>
      email.trim().toLowerCase();
}

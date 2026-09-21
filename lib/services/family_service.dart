import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  FamilyService._();

  static final FamilyService instance = FamilyService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('A signed-in user is required.');
    return user;
  }

  CollectionReference<Map<String, dynamic>> get _circles =>
      _firestore.collection('familyCircles');

  Future<String> ensureFamilyCircle({
    required Iterable<String> connectedUserIds,
  }) async {
    final user = _user;
    final existing = await _circles
        .where('memberUids', arrayContains: user.uid)
        .limit(1)
        .get();

    final memberUids = <String>{
      user.uid,
      ...connectedUserIds.where((id) => id.trim().isNotEmpty),
    }.toList();

    if (existing.docs.isNotEmpty) {
      final circle = existing.docs.first;
      if (circle.data()['ownerUid'] == user.uid) {
        await circle.reference.set({
          'memberUids': FieldValue.arrayUnion(memberUids),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return circle.id;
    }

    final reference = _circles.doc();
    await reference.set({
      'id': reference.id,
      'name': 'Our Family',
      'ownerUid': user.uid,
      'memberUids': memberUids,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEvents(String circleId) {
    return _circles
        .doc(circleId)
        .collection('events')
        .orderBy('startsAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTasks(String circleId) {
    return _circles
        .doc(circleId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUpdates(String circleId) {
    return _circles
        .doc(circleId)
        .collection('updates')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> addEvent({
    required String circleId,
    required String title,
    required String details,
    required DateTime startsAt,
  }) async {
    final user = _user;
    await _circles.doc(circleId).collection('events').add({
      'title': title.trim(),
      'details': details.trim(),
      'startsAt': Timestamp.fromDate(startsAt),
      'createdByUid': user.uid,
      'createdByName': _displayName(user),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTask({
    required String circleId,
    required String title,
    required String details,
  }) async {
    final user = _user;
    await _circles.doc(circleId).collection('tasks').add({
      'title': title.trim(),
      'details': details.trim(),
      'createdByUid': user.uid,
      'createdByName': _displayName(user),
      'claimedByUid': null,
      'claimedByName': '',
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> claimTask(String circleId, String taskId) async {
    final user = _user;
    await _circles.doc(circleId).collection('tasks').doc(taskId).update({
      'claimedByUid': user.uid,
      'claimedByName': _displayName(user),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeTask(String circleId, String taskId) async {
    await _circles.doc(circleId).collection('tasks').doc(taskId).update({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addUpdate({
    required String circleId,
    required String message,
  }) async {
    final user = _user;
    await _circles.doc(circleId).collection('updates').add({
      'message': message.trim(),
      'createdByUid': user.uid,
      'createdByName': _displayName(user),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _displayName(User user) {
    final name = user.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return (user.email ?? '').split('@').first;
  }
}

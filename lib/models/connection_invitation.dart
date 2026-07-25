import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

class ConnectionInvitation {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderEmail;
  final String recipientEmail;
  final String recipientUid;
  final String personId;
  final String relationship;
  final InvitationStatus status;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  const ConnectionInvitation({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderEmail,
    required this.recipientEmail,
    required this.recipientUid,
    required this.personId,
    required this.relationship,
    required this.status,
    this.createdAt,
    this.respondedAt,
  });

  factory ConnectionInvitation.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ConnectionInvitation(
      id: id,
      senderUid: map['senderUid']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      senderEmail: map['senderEmail']?.toString() ?? '',
      recipientEmail: map['recipientEmail']?.toString() ?? '',
      recipientUid: map['recipientUid']?.toString() ?? '',
      personId: map['personId']?.toString() ?? '',
      relationship: map['relationship']?.toString() ?? '',
      status: InvitationStatus.values.firstWhere(
        (status) => status.name == map['status']?.toString(),
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: _date(map['createdAt']),
      respondedAt: _date(map['respondedAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

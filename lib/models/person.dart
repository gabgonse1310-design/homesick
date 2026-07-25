enum ConnectionStatus {
  local,
  invited,
  connected,
}

class Person {
  final String id;
  final String name;
  final String relationship;
  final String symbol;
  final String email;
  final String city;
  final String country;
  final String? recipientUid;
  final ConnectionStatus connectionStatus;
  final int letterCount;
  final int memoryCount;
  final int createdYear;
  final String lastActivity;
  final bool hasNewWords;

  const Person({
    this.id = '',
    required this.name,
    required this.relationship,
    required this.symbol,
    this.email = '',
    this.city = '',
    this.country = '',
    this.recipientUid,
    this.connectionStatus = ConnectionStatus.local,
    this.letterCount = 0,
    this.memoryCount = 0,
    required this.createdYear,
    this.lastActivity = 'No letters yet',
    this.hasNewWords = false,
  });

  bool get hasEmail => email.trim().isNotEmpty;

  bool get isConnected =>
      connectionStatus == ConnectionStatus.connected &&
      recipientUid != null &&
      recipientUid!.trim().isNotEmpty;

  bool get isInvitationPending =>
      connectionStatus == ConnectionStatus.invited;

  String get personKey {
    if (id.trim().isNotEmpty) return id;

    final seed =
        '${name.toLowerCase()}_${relationship.toLowerCase()}_$createdYear';

    final cleaned = seed
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return cleaned.isEmpty ? 'person_$createdYear' : cleaned;
  }

  String get connectionLabel {
    switch (connectionStatus) {
      case ConnectionStatus.local:
        return 'Not invited';
      case ConnectionStatus.invited:
        return 'Invitation pending';
      case ConnectionStatus.connected:
        return 'Connected';
    }
  }

  Person copyWith({
    String? id,
    String? name,
    String? relationship,
    String? symbol,
    String? email,
    String? city,
    String? country,
    String? recipientUid,
    bool clearRecipientUid = false,
    ConnectionStatus? connectionStatus,
    int? letterCount,
    int? memoryCount,
    int? createdYear,
    String? lastActivity,
    bool? hasNewWords,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      symbol: symbol ?? this.symbol,
      email: email ?? this.email,
      city: city ?? this.city,
      country: country ?? this.country,
      recipientUid:
          clearRecipientUid ? null : recipientUid ?? this.recipientUid,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      letterCount: letterCount ?? this.letterCount,
      memoryCount: memoryCount ?? this.memoryCount,
      createdYear: createdYear ?? this.createdYear,
      lastActivity: lastActivity ?? this.lastActivity,
      hasNewWords: hasNewWords ?? this.hasNewWords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': personKey,
      'name': name,
      'relationship': relationship,
      'symbol': symbol,
      'email': email.trim().toLowerCase(),
      'city': city,
      'country': country,
      'recipientUid': recipientUid,
      'connectionStatus': connectionStatus.name,
      'letterCount': letterCount,
      'memoryCount': memoryCount,
      'createdYear': createdYear,
      'lastActivity': lastActivity,
      'hasNewWords': hasNewWords,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    final recipientUid = _nullableString(map['recipientUid']);

    return Person(
      id: map['id']?.toString().trim() ?? '',
      name: map['name']?.toString().trim() ?? '',
      relationship: map['relationship']?.toString().trim() ?? '',
      symbol: map['symbol']?.toString() ??
          'assets/images/flowers/blossom.png',
      email: map['email']?.toString().trim().toLowerCase() ?? '',
      city: map['city']?.toString().trim() ?? '',
      country: map['country']?.toString().trim() ?? '',
      recipientUid: recipientUid,
      connectionStatus: _connectionStatus(
        map['connectionStatus'],
        recipientUid,
      ),
      letterCount: _int(map['letterCount']),
      memoryCount: _int(map['memoryCount']),
      createdYear: _int(
        map['createdYear'],
        fallback: DateTime.now().year,
      ),
      lastActivity:
          map['lastActivity']?.toString() ?? 'No letters yet',
      hasNewWords: _bool(map['hasNewWords']),
    );
  }

  static ConnectionStatus _connectionStatus(
    dynamic value,
    String? recipientUid,
  ) {
    final text = value?.toString().trim().toLowerCase() ?? '';

    if (text == 'connected' ||
        (recipientUid != null && recipientUid.isNotEmpty)) {
      return ConnectionStatus.connected;
    }

    if (text == 'invited' ||
        text == 'pending' ||
        text == 'invitation_pending') {
      return ConnectionStatus.invited;
    }

    return ConnectionStatus.local;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && other.personKey == personKey;

  @override
  int get hashCode => personKey.hashCode;
}

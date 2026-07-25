import 'delivery_journey.dart';

enum LetterType {
  typed,
  handwritten,
  scanned,
  postcard,
}

enum LetterPageType {
  handwritten,
  scanned,
}

class LetterPage {
  final String id;
  final LetterPageType type;
  final String imagePath;
  final int pageNumber;
  final DateTime createdAt;

  const LetterPage({
    required this.id,
    required this.type,
    required this.imagePath,
    required this.pageNumber,
    required this.createdAt,
  });

  LetterPage copyWith({
    String? id,
    LetterPageType? type,
    String? imagePath,
    int? pageNumber,
    DateTime? createdAt,
  }) {
    return LetterPage(
      id: id ?? this.id,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'imagePath': imagePath,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LetterPage.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString();

    return LetterPage(
      id: json['id']?.toString() ?? '',
      type: LetterPageType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => LetterPageType.scanned,
      ),
      imagePath: json['imagePath']?.toString() ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class Letter {
  final String id;
  final String personKey;
  final String recipientName;
  final String recipientRelationship;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDraft;
  final bool isFavorite;
  final bool isTimeCapsule;
  final DateTime? openDate;

  final String capsuleAccessMode;
  final List<String> authorizedPersonKeys;
  final List<String> authorizedPersonNames;

  final LetterType letterType;
  final List<LetterPage> pages;

  final List<String> photoPaths;
  final String? postcardImagePath;

  /// Null for older letters and unsent drafts.
  final DeliveryJourney? deliveryJourney;

  /// True when this is a recipient-facing copy received from another user.
  final bool isIncoming;
  final String senderName;
  final String? cloudDocumentId;

  const Letter({
    required this.id,
    required this.personKey,
    required this.recipientName,
    required this.recipientRelationship,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.isDraft,
    this.isFavorite = false,
    this.isTimeCapsule = false,
    this.openDate,
    this.capsuleAccessMode = 'onlyMe',
    this.authorizedPersonKeys = const [],
    this.authorizedPersonNames = const [],
    this.letterType = LetterType.typed,
    this.pages = const [],
    this.photoPaths = const [],
    this.postcardImagePath,
    this.deliveryJourney,
    this.isIncoming = false,
    this.senderName = '',
    this.cloudDocumentId,
  });

  bool get canOpen {
    final capsuleReady =
        !isTimeCapsule ||
        openDate == null ||
        !DateTime.now().isBefore(openDate!);

    final deliveryReady =
        deliveryJourney == null || deliveryJourney!.isDelivered;

    return capsuleReady && deliveryReady;
  }

  bool get isTyped => letterType == LetterType.typed;
  bool get isHandwritten => letterType == LetterType.handwritten;
  bool get isScanned => letterType == LetterType.scanned;
  bool get isPostcard => letterType == LetterType.postcard;
  bool get hasPages => pages.isNotEmpty;
  bool get hasMemories => photoPaths.isNotEmpty;

  bool get hasPostalJourney =>
      deliveryJourney?.mode == DeliveryMode.postalJourney;

  bool get isTravelling =>
      hasPostalJourney && !(deliveryJourney?.isDelivered ?? true);

  int get deliveryDaysRemaining =>
      deliveryJourney?.remainingDays ?? 0;

  Letter copyWith({
    String? id,
    String? personKey,
    String? recipientName,
    String? recipientRelationship,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDraft,
    bool? isFavorite,
    bool? isTimeCapsule,
    DateTime? openDate,
    bool clearOpenDate = false,
    String? capsuleAccessMode,
    List<String>? authorizedPersonKeys,
    List<String>? authorizedPersonNames,
    LetterType? letterType,
    List<LetterPage>? pages,
    List<String>? photoPaths,
    String? postcardImagePath,
    bool clearPostcardImage = false,
    DeliveryJourney? deliveryJourney,
    bool clearDeliveryJourney = false,
    bool? isIncoming,
    String? senderName,
    String? cloudDocumentId,
    bool clearCloudDocumentId = false,
  }) {
    return Letter(
      id: id ?? this.id,
      personKey: personKey ?? this.personKey,
      recipientName: recipientName ?? this.recipientName,
      recipientRelationship:
          recipientRelationship ?? this.recipientRelationship,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDraft: isDraft ?? this.isDraft,
      isFavorite: isFavorite ?? this.isFavorite,
      isTimeCapsule: isTimeCapsule ?? this.isTimeCapsule,
      openDate: clearOpenDate ? null : (openDate ?? this.openDate),
      capsuleAccessMode: capsuleAccessMode ?? this.capsuleAccessMode,
      authorizedPersonKeys:
          authorizedPersonKeys ?? this.authorizedPersonKeys,
      authorizedPersonNames:
          authorizedPersonNames ?? this.authorizedPersonNames,
      letterType: letterType ?? this.letterType,
      pages: pages ?? this.pages,
      photoPaths: photoPaths ?? this.photoPaths,
      postcardImagePath: clearPostcardImage
          ? null
          : (postcardImagePath ?? this.postcardImagePath),
      deliveryJourney: clearDeliveryJourney
          ? null
          : (deliveryJourney ?? this.deliveryJourney),
      isIncoming: isIncoming ?? this.isIncoming,
      senderName: senderName ?? this.senderName,
      cloudDocumentId: clearCloudDocumentId
          ? null
          : (cloudDocumentId ?? this.cloudDocumentId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personKey': personKey,
      'recipientName': recipientName,
      'recipientRelationship': recipientRelationship,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDraft': isDraft,
      'isFavorite': isFavorite,
      'isTimeCapsule': isTimeCapsule,
      'openDate': openDate?.toIso8601String(),
      'capsuleAccessMode': capsuleAccessMode,
      'authorizedPersonKeys': authorizedPersonKeys,
      'authorizedPersonNames': authorizedPersonNames,
      'letterType': letterType.name,
      'pages': pages.map((page) => page.toJson()).toList(),
      'photoPaths': photoPaths,
      'postcardImagePath': postcardImagePath,
      'deliveryJourney': deliveryJourney?.toMap(),
      'isIncoming': isIncoming,
      'senderName': senderName,
      'cloudDocumentId': cloudDocumentId,
    };
  }

  factory Letter.fromJson(Map<String, dynamic> json) {
    final rawLetterType = json['letterType']?.toString();
    final rawJourney = json['deliveryJourney'];

    return Letter(
      id: json['id']?.toString() ?? '',
      personKey: json['personKey']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      recipientRelationship:
          json['recipientRelationship']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Letter',
      body: json['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      isDraft: json['isDraft'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isTimeCapsule: json['isTimeCapsule'] as bool? ?? false,
      openDate: DateTime.tryParse(json['openDate']?.toString() ?? ''),
      capsuleAccessMode:
          json['capsuleAccessMode']?.toString() ?? 'onlyMe',
      authorizedPersonKeys:
          (json['authorizedPersonKeys'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      authorizedPersonNames:
          (json['authorizedPersonNames'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      letterType: LetterType.values.firstWhere(
        (value) => value.name == rawLetterType,
        orElse: () => LetterType.typed,
      ),
      pages: (json['pages'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => LetterPage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      photoPaths: (json['photoPaths'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      postcardImagePath: json['postcardImagePath']?.toString(),
      deliveryJourney: rawJourney is Map
          ? DeliveryJourney.fromMap(
              Map<String, dynamic>.from(rawJourney),
            )
          : null,
      isIncoming: json['isIncoming'] as bool? ?? false,
      senderName: json['senderName']?.toString() ?? '',
      cloudDocumentId: json['cloudDocumentId']?.toString(),
    );
  }
}

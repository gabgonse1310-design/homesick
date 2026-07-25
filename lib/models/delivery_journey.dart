enum DeliveryMode {
  instant,
  postalJourney,
}

enum DeliveryStatus {
  preparing,
  collected,
  sorting,
  inTransit,
  destinationCountry,
  outForDelivery,
  delivered,
}

class DeliveryJourney {
  final DeliveryMode mode;
  final String originCountry;
  final String originCity;
  final String destinationCountry;
  final String destinationCity;
  final DateTime sentAt;
  final DateTime estimatedArrival;
  final int estimatedDays;

  const DeliveryJourney({
    required this.mode,
    required this.originCountry,
    required this.originCity,
    required this.destinationCountry,
    required this.destinationCity,
    required this.sentAt,
    required this.estimatedArrival,
    required this.estimatedDays,
  });

  bool get isInstant => mode == DeliveryMode.instant;

  bool get isDelivered =>
      isInstant || !DateTime.now().isBefore(estimatedArrival);

  Duration get remainingDuration {
    if (isDelivered) {
      return Duration.zero;
    }

    return estimatedArrival.difference(DateTime.now());
  }

  int get remainingDays {
    if (isDelivered) {
      return 0;
    }

    final hours = remainingDuration.inHours;
    return (hours / 24).ceil();
  }

  double get progress {
    if (isInstant || isDelivered) {
      return 1;
    }

    final totalSeconds = estimatedArrival.difference(sentAt).inSeconds;

    if (totalSeconds <= 0) {
      return 1;
    }

    final elapsedSeconds = DateTime.now().difference(sentAt).inSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  DeliveryStatus get status {
    if (isDelivered) {
      return DeliveryStatus.delivered;
    }

    final value = progress;

    if (value < 0.08) {
      return DeliveryStatus.preparing;
    }
    if (value < 0.20) {
      return DeliveryStatus.collected;
    }
    if (value < 0.38) {
      return DeliveryStatus.sorting;
    }
    if (value < 0.72) {
      return DeliveryStatus.inTransit;
    }
    if (value < 0.88) {
      return DeliveryStatus.destinationCountry;
    }

    return DeliveryStatus.outForDelivery;
  }

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.preparing:
        return 'Preparing the journey';
      case DeliveryStatus.collected:
        return 'Collected';
      case DeliveryStatus.sorting:
        return 'At the sorting centre';
      case DeliveryStatus.inTransit:
        return 'Travelling';
      case DeliveryStatus.destinationCountry:
        return 'Arrived in the destination country';
      case DeliveryStatus.outForDelivery:
        return 'Out for delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryMode': mode.name,
      'originCountry': originCountry,
      'originCity': originCity,
      'destinationCountry': destinationCountry,
      'destinationCity': destinationCity,
      'sentAt': sentAt.toIso8601String(),
      'estimatedArrival': estimatedArrival.toIso8601String(),
      'estimatedDays': estimatedDays,
    };
  }

  factory DeliveryJourney.fromMap(Map<String, dynamic> map) {
    final modeName = map['deliveryMode']?.toString();

    final mode = DeliveryMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => DeliveryMode.instant,
    );

    final sentAt = _readDateTime(map['sentAt']) ?? DateTime.now();
    final estimatedDays = _readInt(map['estimatedDays']);

    final arrival = _readDateTime(map['estimatedArrival']) ??
        sentAt.add(Duration(days: estimatedDays));

    return DeliveryJourney(
      mode: mode,
      originCountry: map['originCountry']?.toString() ?? '',
      originCity: map['originCity']?.toString() ?? '',
      destinationCountry:
          map['destinationCountry']?.toString() ?? '',
      destinationCity: map['destinationCity']?.toString() ?? '',
      sentAt: sentAt,
      estimatedArrival: arrival,
      estimatedDays: estimatedDays,
    );
  }

  DeliveryJourney copyWith({
    DeliveryMode? mode,
    String? originCountry,
    String? originCity,
    String? destinationCountry,
    String? destinationCity,
    DateTime? sentAt,
    DateTime? estimatedArrival,
    int? estimatedDays,
  }) {
    return DeliveryJourney(
      mode: mode ?? this.mode,
      originCountry: originCountry ?? this.originCountry,
      originCity: originCity ?? this.originCity,
      destinationCountry:
          destinationCountry ?? this.destinationCountry,
      destinationCity: destinationCity ?? this.destinationCity,
      sentAt: sentAt ?? this.sentAt,
      estimatedArrival:
          estimatedArrival ?? this.estimatedArrival,
      estimatedDays: estimatedDays ?? this.estimatedDays,
    );
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PostalJourneyEstimator {
  const PostalJourneyEstimator._();

  static DeliveryJourney instant({
    required String originCountry,
    String originCity = '',
    required String destinationCountry,
    String destinationCity = '',
    DateTime? sentAt,
  }) {
    final now = sentAt ?? DateTime.now();

    return DeliveryJourney(
      mode: DeliveryMode.instant,
      originCountry: originCountry,
      originCity: originCity,
      destinationCountry: destinationCountry,
      destinationCity: destinationCity,
      sentAt: now,
      estimatedArrival: now,
      estimatedDays: 0,
    );
  }

  static DeliveryJourney postal({
    required String originCountry,
    String originCity = '',
    required String destinationCountry,
    String destinationCity = '',
    DateTime? sentAt,
  }) {
    final now = sentAt ?? DateTime.now();

    final days = estimateDays(
      originCountry: originCountry,
      destinationCountry: destinationCountry,
    );

    return DeliveryJourney(
      mode: DeliveryMode.postalJourney,
      originCountry: originCountry,
      originCity: originCity,
      destinationCountry: destinationCountry,
      destinationCity: destinationCity,
      sentAt: now,
      estimatedArrival: now.add(Duration(days: days)),
      estimatedDays: days,
    );
  }

  static int estimateDays({
    required String originCountry,
    required String destinationCountry,
  }) {
    final origin = _normalise(originCountry);
    final destination = _normalise(destinationCountry);

    if (origin.isEmpty || destination.isEmpty) {
      return 10;
    }

    if (origin == destination) {
      return 3;
    }

    final directEstimate = _directRoutes['$origin|$destination'] ??
        _directRoutes['$destination|$origin'];

    if (directEstimate != null) {
      return directEstimate;
    }

    final originRegion = _countryRegion[origin] ?? PostalRegion.other;
    final destinationRegion =
        _countryRegion[destination] ?? PostalRegion.other;

    if (originRegion == destinationRegion) {
      return 6;
    }

    return _regionEstimate(originRegion, destinationRegion);
  }

  static int _regionEstimate(
    PostalRegion origin,
    PostalRegion destination,
  ) {
    final pair = {origin, destination};

    if (pair.contains(PostalRegion.southernAfrica) &&
        pair.contains(PostalRegion.southAmerica)) {
      return 14;
    }

    if (pair.contains(PostalRegion.southernAfrica) &&
        pair.contains(PostalRegion.europe)) {
      return 9;
    }

    if (pair.contains(PostalRegion.southernAfrica) &&
        pair.contains(PostalRegion.northAmerica)) {
      return 11;
    }

    if (pair.contains(PostalRegion.southernAfrica) &&
        pair.contains(PostalRegion.asia)) {
      return 12;
    }

    if (pair.contains(PostalRegion.southernAfrica) &&
        pair.contains(PostalRegion.oceania)) {
      return 13;
    }

    if (pair.contains(PostalRegion.europe) &&
        pair.contains(PostalRegion.southAmerica)) {
      return 10;
    }

    if (pair.contains(PostalRegion.europe) &&
        pair.contains(PostalRegion.northAmerica)) {
      return 8;
    }

    if (pair.contains(PostalRegion.europe) &&
        pair.contains(PostalRegion.asia)) {
      return 10;
    }

    if (pair.contains(PostalRegion.southAmerica) &&
        pair.contains(PostalRegion.northAmerica)) {
      return 9;
    }

    if (pair.contains(PostalRegion.asia) &&
        pair.contains(PostalRegion.oceania)) {
      return 8;
    }

    return 11;
  }

  static String _normalise(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static const Map<String, int> _directRoutes = {
    'south africa|uruguay': 14,
    'south africa|spain': 9,
    'south africa|united kingdom': 8,
    'south africa|namibia': 4,
    'south africa|botswana': 4,
    'south africa|zimbabwe': 5,
    'south africa|mozambique': 5,
    'south africa|argentina': 13,
    'south africa|brazil': 12,
    'south africa|australia': 13,
    'south africa|new zealand': 14,
    'uruguay|argentina': 4,
    'uruguay|brazil': 6,
    'uruguay|spain': 10,
    'uruguay|united states': 10,
  };

  static const Map<String, PostalRegion> _countryRegion = {
    'south africa': PostalRegion.southernAfrica,
    'namibia': PostalRegion.southernAfrica,
    'botswana': PostalRegion.southernAfrica,
    'zimbabwe': PostalRegion.southernAfrica,
    'mozambique': PostalRegion.southernAfrica,
    'lesotho': PostalRegion.southernAfrica,
    'eswatini': PostalRegion.southernAfrica,

    'uruguay': PostalRegion.southAmerica,
    'argentina': PostalRegion.southAmerica,
    'brazil': PostalRegion.southAmerica,
    'chile': PostalRegion.southAmerica,
    'paraguay': PostalRegion.southAmerica,
    'peru': PostalRegion.southAmerica,
    'colombia': PostalRegion.southAmerica,
    'ecuador': PostalRegion.southAmerica,
    'bolivia': PostalRegion.southAmerica,
    'venezuela': PostalRegion.southAmerica,

    'spain': PostalRegion.europe,
    'portugal': PostalRegion.europe,
    'united kingdom': PostalRegion.europe,
    'ireland': PostalRegion.europe,
    'france': PostalRegion.europe,
    'germany': PostalRegion.europe,
    'italy': PostalRegion.europe,
    'netherlands': PostalRegion.europe,
    'belgium': PostalRegion.europe,
    'switzerland': PostalRegion.europe,
    'austria': PostalRegion.europe,
    'sweden': PostalRegion.europe,
    'norway': PostalRegion.europe,
    'denmark': PostalRegion.europe,
    'finland': PostalRegion.europe,
    'poland': PostalRegion.europe,
    'greece': PostalRegion.europe,

    'united states': PostalRegion.northAmerica,
    'canada': PostalRegion.northAmerica,
    'mexico': PostalRegion.northAmerica,

    'china': PostalRegion.asia,
    'japan': PostalRegion.asia,
    'south korea': PostalRegion.asia,
    'india': PostalRegion.asia,
    'singapore': PostalRegion.asia,
    'thailand': PostalRegion.asia,
    'philippines': PostalRegion.asia,
    'indonesia': PostalRegion.asia,

    'australia': PostalRegion.oceania,
    'new zealand': PostalRegion.oceania,
  };
}

enum PostalRegion {
  southernAfrica,
  southAmerica,
  northAmerica,
  europe,
  asia,
  oceania,
  other,
}

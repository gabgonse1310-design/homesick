import 'package:flutter/material.dart';

import '../models/delivery_journey.dart';
import '../theme/app_theme.dart';

class DeliveryMethodScreen extends StatefulWidget {
  final String recipientName;
  final String initialOriginCountry;
  final String initialOriginCity;
  final String initialDestinationCountry;
  final String initialDestinationCity;
  final DeliveryJourney? initialJourney;

  const DeliveryMethodScreen({
    super.key,
    required this.recipientName,
    this.initialOriginCountry = 'South Africa',
    this.initialOriginCity = 'Pretoria',
    this.initialDestinationCountry = '',
    this.initialDestinationCity = '',
    this.initialJourney,
  });

  @override
  State<DeliveryMethodScreen> createState() =>
      _DeliveryMethodScreenState();
}

class _DeliveryMethodScreenState
    extends State<DeliveryMethodScreen> {
  static const List<String> _countries = [
    'South Africa',
    'Uruguay',
    'Argentina',
    'Brazil',
    'Chile',
    'Paraguay',
    'Bolivia',
    'Peru',
    'Colombia',
    'Ecuador',
    'Venezuela',
    'Spain',
    'Portugal',
    'United Kingdom',
    'Ireland',
    'France',
    'Germany',
    'Italy',
    'Netherlands',
    'Belgium',
    'Switzerland',
    'Austria',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
    'Poland',
    'Greece',
    'United States',
    'Canada',
    'Mexico',
    'Namibia',
    'Botswana',
    'Zimbabwe',
    'Mozambique',
    'Lesotho',
    'Eswatini',
    'Australia',
    'New Zealand',
    'China',
    'Japan',
    'South Korea',
    'India',
    'Singapore',
    'Thailand',
    'Philippines',
    'Indonesia',
  ];

  late DeliveryMode _selectedMode;
  late String _originCountry;
  late String _destinationCountry;

  final TextEditingController _originCityController =
      TextEditingController();
  final TextEditingController _destinationCityController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    final journey = widget.initialJourney;

    _selectedMode = journey?.mode ?? DeliveryMode.instant;

    _originCountry = _resolvedCountry(
      journey?.originCountry ?? widget.initialOriginCountry,
      fallback: 'South Africa',
    );

    _destinationCountry = _resolvedCountry(
      journey?.destinationCountry ??
          widget.initialDestinationCountry,
      fallback: 'Uruguay',
    );

    _originCityController.text =
        journey?.originCity ?? widget.initialOriginCity;

    _destinationCityController.text =
        journey?.destinationCity ??
            widget.initialDestinationCity;
  }

  @override
  void dispose() {
    _originCityController.dispose();
    _destinationCityController.dispose();
    super.dispose();
  }

  String _resolvedCountry(
    String value, {
    required String fallback,
  }) {
    final match = _countries.where(
      (country) =>
          country.toLowerCase() == value.trim().toLowerCase(),
    );

    if (match.isNotEmpty) {
      return match.first;
    }

    return fallback;
  }

  DeliveryJourney get _previewJourney {
    final originCity = _originCityController.text.trim();
    final destinationCity =
        _destinationCityController.text.trim();

    if (_selectedMode == DeliveryMode.instant) {
      return PostalJourneyEstimator.instant(
        originCountry: _originCountry,
        originCity: originCity,
        destinationCountry: _destinationCountry,
        destinationCity: destinationCity,
      );
    }

    return PostalJourneyEstimator.postal(
      originCountry: _originCountry,
      originCity: originCity,
      destinationCountry: _destinationCountry,
      destinationCity: destinationCity,
    );
  }

  void _finish() {
    final destinationCity =
        _destinationCityController.text.trim();

    if (_selectedMode == DeliveryMode.postalJourney &&
        destinationCity.isEmpty) {
      _showMessage(
        'Add the destination city before beginning the journey.',
      );
      return;
    }

    Navigator.pop(context, _previewJourney);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _countryFlag(String country) {
    const flags = {
      'South Africa': '🇿🇦',
      'Uruguay': '🇺🇾',
      'Argentina': '🇦🇷',
      'Brazil': '🇧🇷',
      'Chile': '🇨🇱',
      'Paraguay': '🇵🇾',
      'Bolivia': '🇧🇴',
      'Peru': '🇵🇪',
      'Colombia': '🇨🇴',
      'Ecuador': '🇪🇨',
      'Venezuela': '🇻🇪',
      'Spain': '🇪🇸',
      'Portugal': '🇵🇹',
      'United Kingdom': '🇬🇧',
      'Ireland': '🇮🇪',
      'France': '🇫🇷',
      'Germany': '🇩🇪',
      'Italy': '🇮🇹',
      'Netherlands': '🇳🇱',
      'Belgium': '🇧🇪',
      'Switzerland': '🇨🇭',
      'Austria': '🇦🇹',
      'Sweden': '🇸🇪',
      'Norway': '🇳🇴',
      'Denmark': '🇩🇰',
      'Finland': '🇫🇮',
      'Poland': '🇵🇱',
      'Greece': '🇬🇷',
      'United States': '🇺🇸',
      'Canada': '🇨🇦',
      'Mexico': '🇲🇽',
      'Namibia': '🇳🇦',
      'Botswana': '🇧🇼',
      'Zimbabwe': '🇿🇼',
      'Mozambique': '🇲🇿',
      'Lesotho': '🇱🇸',
      'Eswatini': '🇸🇿',
      'Australia': '🇦🇺',
      'New Zealand': '🇳🇿',
      'China': '🇨🇳',
      'Japan': '🇯🇵',
      'South Korea': '🇰🇷',
      'India': '🇮🇳',
      'Singapore': '🇸🇬',
      'Thailand': '🇹🇭',
      'Philippines': '🇵🇭',
      'Indonesia': '🇮🇩',
    };

    return flags[country] ?? '🌍';
  }

  @override
  Widget build(BuildContext context) {
    final journey = _previewJourney;
    final isPostal =
        _selectedMode == DeliveryMode.postalJourney;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Send Your Letter'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'How should these words travel?',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose whether ${widget.recipientName} receives the letter now or waits for it to complete a postal journey.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color: AppColors.softGrey,
                            height: 1.45,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _DeliveryChoiceCard(
                      selected:
                          _selectedMode == DeliveryMode.instant,
                      icon: Icons.bolt_rounded,
                      title: 'Instant',
                      description:
                          'The letter arrives immediately and can be opened now.',
                      onTap: () {
                        setState(() {
                          _selectedMode = DeliveryMode.instant;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _DeliveryChoiceCard(
                      selected: isPostal,
                      icon: Icons.local_post_office_outlined,
                      title: 'Postal Journey',
                      description:
                          'The letter travels gradually and unlocks when it arrives.',
                      onTap: () {
                        setState(() {
                          _selectedMode =
                              DeliveryMode.postalJourney;
                        });
                      },
                    ),
                    if (isPostal) ...[
                      const SizedBox(height: 24),
                      _JourneyAddressCard(
                        title: 'From',
                        flag: _countryFlag(_originCountry),
                        selectedCountry: _originCountry,
                        cityController: _originCityController,
                        countries: _countries,
                        onCountryChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _originCountry = value;
                          });
                        },
                        onCityChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.south_rounded,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _JourneyAddressCard(
                        title: 'To',
                        flag:
                            _countryFlag(_destinationCountry),
                        selectedCountry: _destinationCountry,
                        cityController:
                            _destinationCityController,
                        countries: _countries,
                        onCountryChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _destinationCountry = value;
                          });
                        },
                        onCityChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      _JourneyPreviewCard(
                        originCity:
                            _originCityController.text.trim(),
                        originCountry: _originCountry,
                        destinationCity:
                            _destinationCityController.text.trim(),
                        destinationCountry:
                            _destinationCountry,
                        originFlag:
                            _countryFlag(_originCountry),
                        destinationFlag:
                            _countryFlag(_destinationCountry),
                        estimatedDays: journey.estimatedDays,
                        arrivalDate:
                            _formatDate(journey.estimatedArrival),
                      ),
                    ],
                    if (!isPostal) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius:
                              BorderRadius.circular(24),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 42,
                              color: AppColors.terracotta,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Arrives now',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${widget.recipientName} will be able to open the letter immediately.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.softGrey,
                                    height: 1.4,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.fromLTRB(22, 14, 22, 20),
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finish,
                  icon: Icon(
                    isPostal
                        ? Icons.flight_takeoff_rounded
                        : Icons.mark_email_read_outlined,
                  ),
                  label: Text(
                    isPostal
                        ? 'Begin Journey'
                        : 'Deliver Instantly',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _DeliveryChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.terracotta
                  : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.terracotta.withValues(
                          alpha: 0.12,
                        )
                      : AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.terracotta
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.terracotta,
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: AppColors.softGrey,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected
                    ? AppColors.terracotta
                    : AppColors.softGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyAddressCard extends StatelessWidget {
  final String title;
  final String flag;
  final String selectedCountry;
  final TextEditingController cityController;
  final List<String> countries;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String> onCityChanged;

  const _JourneyAddressCard({
    required this.title,
    required this.flag,
    required this.selectedCountry,
    required this.cityController,
    required this.countries,
    required this.onCountryChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: AppColors.terracotta,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedCountry,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Country',
            ),
            items: countries
                .map(
                  (country) => DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  ),
                )
                .toList(),
            onChanged: onCountryChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cityController,
            textCapitalization: TextCapitalization.words,
            onChanged: onCityChanged,
            decoration: const InputDecoration(
              labelText: 'City',
              hintText: 'For example, Pretoria',
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPreviewCard extends StatelessWidget {
  final String originCity;
  final String originCountry;
  final String destinationCity;
  final String destinationCountry;
  final String originFlag;
  final String destinationFlag;
  final int estimatedDays;
  final String arrivalDate;

  const _JourneyPreviewCard({
    required this.originCity,
    required this.originCountry,
    required this.destinationCity,
    required this.destinationCountry,
    required this.originFlag,
    required this.destinationFlag,
    required this.estimatedDays,
    required this.arrivalDate,
  });

  String _place(String city, String country) {
    if (city.trim().isEmpty) {
      return country;
    }

    return '$city, $country';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Your letter’s journey',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      originFlag,
                      style: const TextStyle(fontSize: 31),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _place(originCity, originCountry),
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppColors.terracotta,
                  size: 30,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      destinationFlag,
                      style: const TextStyle(fontSize: 31),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _place(
                        destinationCity,
                        destinationCountry,
                      ),
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PreviewDetail(
                  label: 'Estimated journey',
                  value: '$estimatedDays days',
                ),
              ),
              Container(
                height: 45,
                width: 1,
                color: AppColors.border,
              ),
              Expanded(
                child: _PreviewDetail(
                  label: 'Estimated arrival',
                  value: arrivalDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Both people will be able to follow the same countdown while the letter travels.',
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.softGrey,
                      height: 1.4,
                    ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PreviewDetail extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.softGrey,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: AppColors.terracotta,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

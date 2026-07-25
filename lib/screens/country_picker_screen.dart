import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CountryOption {
  final String name;
  final String code;

  const CountryOption({
    required this.name,
    required this.code,
  });

  String get flag {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '🌍';

    return String.fromCharCodes(
      upper.codeUnits.map((unit) => unit + 127397),
    );
  }
}

Future<CountryOption?> showCountryPicker(
  BuildContext context, {
  String? selectedCountry,
}) {
  return showModalBottomSheet<CountryOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (_) => _CountryPickerSheet(
      selectedCountry: selectedCountry,
    ),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final String? selectedCountry;

  const _CountryPickerSheet({
    this.selectedCountry,
  });

  @override
  State<_CountryPickerSheet> createState() =>
      _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';

  List<CountryOption> get _filteredCountries {
    final cleanQuery = _query.trim().toLowerCase();

    if (cleanQuery.isEmpty) return countries;

    return countries.where((country) {
      return country.name.toLowerCase().contains(cleanQuery) ||
          country.code.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredCountries;
    final height = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose a country',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search countries',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (value) {
                setState(() => _query = value);
              },
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'No country matches “$_query”.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.softGrey,
                                ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.border.withOpacity(0.65),
                    ),
                    itemBuilder: (context, index) {
                      final country = results[index];
                      final selected =
                          widget.selectedCountry?.trim() == country.name;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 23),
                          ),
                        ),
                        title: Text(country.name),
                        subtitle: Text(country.code),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.terracotta,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.softGrey,
                              ),
                        onTap: () => Navigator.pop(context, country),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

const List<CountryOption> countries = [
  CountryOption(name: 'Afghanistan', code: 'AF'),
  CountryOption(name: 'Albania', code: 'AL'),
  CountryOption(name: 'Algeria', code: 'DZ'),
  CountryOption(name: 'Andorra', code: 'AD'),
  CountryOption(name: 'Angola', code: 'AO'),
  CountryOption(name: 'Antigua and Barbuda', code: 'AG'),
  CountryOption(name: 'Argentina', code: 'AR'),
  CountryOption(name: 'Armenia', code: 'AM'),
  CountryOption(name: 'Australia', code: 'AU'),
  CountryOption(name: 'Austria', code: 'AT'),
  CountryOption(name: 'Azerbaijan', code: 'AZ'),
  CountryOption(name: 'Bahamas', code: 'BS'),
  CountryOption(name: 'Bahrain', code: 'BH'),
  CountryOption(name: 'Bangladesh', code: 'BD'),
  CountryOption(name: 'Barbados', code: 'BB'),
  CountryOption(name: 'Belarus', code: 'BY'),
  CountryOption(name: 'Belgium', code: 'BE'),
  CountryOption(name: 'Belize', code: 'BZ'),
  CountryOption(name: 'Benin', code: 'BJ'),
  CountryOption(name: 'Bhutan', code: 'BT'),
  CountryOption(name: 'Bolivia', code: 'BO'),
  CountryOption(name: 'Bosnia and Herzegovina', code: 'BA'),
  CountryOption(name: 'Botswana', code: 'BW'),
  CountryOption(name: 'Brazil', code: 'BR'),
  CountryOption(name: 'Brunei', code: 'BN'),
  CountryOption(name: 'Bulgaria', code: 'BG'),
  CountryOption(name: 'Burkina Faso', code: 'BF'),
  CountryOption(name: 'Burundi', code: 'BI'),
  CountryOption(name: 'Cabo Verde', code: 'CV'),
  CountryOption(name: 'Cambodia', code: 'KH'),
  CountryOption(name: 'Cameroon', code: 'CM'),
  CountryOption(name: 'Canada', code: 'CA'),
  CountryOption(name: 'Central African Republic', code: 'CF'),
  CountryOption(name: 'Chad', code: 'TD'),
  CountryOption(name: 'Chile', code: 'CL'),
  CountryOption(name: 'China', code: 'CN'),
  CountryOption(name: 'Colombia', code: 'CO'),
  CountryOption(name: 'Comoros', code: 'KM'),
  CountryOption(name: 'Congo', code: 'CG'),
  CountryOption(name: 'Costa Rica', code: 'CR'),
  CountryOption(name: 'Côte d’Ivoire', code: 'CI'),
  CountryOption(name: 'Croatia', code: 'HR'),
  CountryOption(name: 'Cuba', code: 'CU'),
  CountryOption(name: 'Cyprus', code: 'CY'),
  CountryOption(name: 'Czechia', code: 'CZ'),
  CountryOption(name: 'Democratic Republic of the Congo', code: 'CD'),
  CountryOption(name: 'Denmark', code: 'DK'),
  CountryOption(name: 'Djibouti', code: 'DJ'),
  CountryOption(name: 'Dominica', code: 'DM'),
  CountryOption(name: 'Dominican Republic', code: 'DO'),
  CountryOption(name: 'Ecuador', code: 'EC'),
  CountryOption(name: 'Egypt', code: 'EG'),
  CountryOption(name: 'El Salvador', code: 'SV'),
  CountryOption(name: 'Equatorial Guinea', code: 'GQ'),
  CountryOption(name: 'Eritrea', code: 'ER'),
  CountryOption(name: 'Estonia', code: 'EE'),
  CountryOption(name: 'Eswatini', code: 'SZ'),
  CountryOption(name: 'Ethiopia', code: 'ET'),
  CountryOption(name: 'Fiji', code: 'FJ'),
  CountryOption(name: 'Finland', code: 'FI'),
  CountryOption(name: 'France', code: 'FR'),
  CountryOption(name: 'Gabon', code: 'GA'),
  CountryOption(name: 'Gambia', code: 'GM'),
  CountryOption(name: 'Georgia', code: 'GE'),
  CountryOption(name: 'Germany', code: 'DE'),
  CountryOption(name: 'Ghana', code: 'GH'),
  CountryOption(name: 'Greece', code: 'GR'),
  CountryOption(name: 'Grenada', code: 'GD'),
  CountryOption(name: 'Guatemala', code: 'GT'),
  CountryOption(name: 'Guinea', code: 'GN'),
  CountryOption(name: 'Guinea-Bissau', code: 'GW'),
  CountryOption(name: 'Guyana', code: 'GY'),
  CountryOption(name: 'Haiti', code: 'HT'),
  CountryOption(name: 'Honduras', code: 'HN'),
  CountryOption(name: 'Hungary', code: 'HU'),
  CountryOption(name: 'Iceland', code: 'IS'),
  CountryOption(name: 'India', code: 'IN'),
  CountryOption(name: 'Indonesia', code: 'ID'),
  CountryOption(name: 'Iran', code: 'IR'),
  CountryOption(name: 'Iraq', code: 'IQ'),
  CountryOption(name: 'Ireland', code: 'IE'),
  CountryOption(name: 'Israel', code: 'IL'),
  CountryOption(name: 'Italy', code: 'IT'),
  CountryOption(name: 'Jamaica', code: 'JM'),
  CountryOption(name: 'Japan', code: 'JP'),
  CountryOption(name: 'Jordan', code: 'JO'),
  CountryOption(name: 'Kazakhstan', code: 'KZ'),
  CountryOption(name: 'Kenya', code: 'KE'),
  CountryOption(name: 'Kiribati', code: 'KI'),
  CountryOption(name: 'Kuwait', code: 'KW'),
  CountryOption(name: 'Kyrgyzstan', code: 'KG'),
  CountryOption(name: 'Laos', code: 'LA'),
  CountryOption(name: 'Latvia', code: 'LV'),
  CountryOption(name: 'Lebanon', code: 'LB'),
  CountryOption(name: 'Lesotho', code: 'LS'),
  CountryOption(name: 'Liberia', code: 'LR'),
  CountryOption(name: 'Libya', code: 'LY'),
  CountryOption(name: 'Liechtenstein', code: 'LI'),
  CountryOption(name: 'Lithuania', code: 'LT'),
  CountryOption(name: 'Luxembourg', code: 'LU'),
  CountryOption(name: 'Madagascar', code: 'MG'),
  CountryOption(name: 'Malawi', code: 'MW'),
  CountryOption(name: 'Malaysia', code: 'MY'),
  CountryOption(name: 'Maldives', code: 'MV'),
  CountryOption(name: 'Mali', code: 'ML'),
  CountryOption(name: 'Malta', code: 'MT'),
  CountryOption(name: 'Marshall Islands', code: 'MH'),
  CountryOption(name: 'Mauritania', code: 'MR'),
  CountryOption(name: 'Mauritius', code: 'MU'),
  CountryOption(name: 'Mexico', code: 'MX'),
  CountryOption(name: 'Micronesia', code: 'FM'),
  CountryOption(name: 'Moldova', code: 'MD'),
  CountryOption(name: 'Monaco', code: 'MC'),
  CountryOption(name: 'Mongolia', code: 'MN'),
  CountryOption(name: 'Montenegro', code: 'ME'),
  CountryOption(name: 'Morocco', code: 'MA'),
  CountryOption(name: 'Mozambique', code: 'MZ'),
  CountryOption(name: 'Myanmar', code: 'MM'),
  CountryOption(name: 'Namibia', code: 'NA'),
  CountryOption(name: 'Nauru', code: 'NR'),
  CountryOption(name: 'Nepal', code: 'NP'),
  CountryOption(name: 'Netherlands', code: 'NL'),
  CountryOption(name: 'New Zealand', code: 'NZ'),
  CountryOption(name: 'Nicaragua', code: 'NI'),
  CountryOption(name: 'Niger', code: 'NE'),
  CountryOption(name: 'Nigeria', code: 'NG'),
  CountryOption(name: 'North Korea', code: 'KP'),
  CountryOption(name: 'North Macedonia', code: 'MK'),
  CountryOption(name: 'Norway', code: 'NO'),
  CountryOption(name: 'Oman', code: 'OM'),
  CountryOption(name: 'Pakistan', code: 'PK'),
  CountryOption(name: 'Palau', code: 'PW'),
  CountryOption(name: 'Palestine', code: 'PS'),
  CountryOption(name: 'Panama', code: 'PA'),
  CountryOption(name: 'Papua New Guinea', code: 'PG'),
  CountryOption(name: 'Paraguay', code: 'PY'),
  CountryOption(name: 'Peru', code: 'PE'),
  CountryOption(name: 'Philippines', code: 'PH'),
  CountryOption(name: 'Poland', code: 'PL'),
  CountryOption(name: 'Portugal', code: 'PT'),
  CountryOption(name: 'Qatar', code: 'QA'),
  CountryOption(name: 'Romania', code: 'RO'),
  CountryOption(name: 'Russia', code: 'RU'),
  CountryOption(name: 'Rwanda', code: 'RW'),
  CountryOption(name: 'Saint Kitts and Nevis', code: 'KN'),
  CountryOption(name: 'Saint Lucia', code: 'LC'),
  CountryOption(name: 'Saint Vincent and the Grenadines', code: 'VC'),
  CountryOption(name: 'Samoa', code: 'WS'),
  CountryOption(name: 'San Marino', code: 'SM'),
  CountryOption(name: 'São Tomé and Príncipe', code: 'ST'),
  CountryOption(name: 'Saudi Arabia', code: 'SA'),
  CountryOption(name: 'Senegal', code: 'SN'),
  CountryOption(name: 'Serbia', code: 'RS'),
  CountryOption(name: 'Seychelles', code: 'SC'),
  CountryOption(name: 'Sierra Leone', code: 'SL'),
  CountryOption(name: 'Singapore', code: 'SG'),
  CountryOption(name: 'Slovakia', code: 'SK'),
  CountryOption(name: 'Slovenia', code: 'SI'),
  CountryOption(name: 'Solomon Islands', code: 'SB'),
  CountryOption(name: 'Somalia', code: 'SO'),
  CountryOption(name: 'South Africa', code: 'ZA'),
  CountryOption(name: 'South Korea', code: 'KR'),
  CountryOption(name: 'South Sudan', code: 'SS'),
  CountryOption(name: 'Spain', code: 'ES'),
  CountryOption(name: 'Sri Lanka', code: 'LK'),
  CountryOption(name: 'Sudan', code: 'SD'),
  CountryOption(name: 'Suriname', code: 'SR'),
  CountryOption(name: 'Sweden', code: 'SE'),
  CountryOption(name: 'Switzerland', code: 'CH'),
  CountryOption(name: 'Syria', code: 'SY'),
  CountryOption(name: 'Taiwan', code: 'TW'),
  CountryOption(name: 'Tajikistan', code: 'TJ'),
  CountryOption(name: 'Tanzania', code: 'TZ'),
  CountryOption(name: 'Thailand', code: 'TH'),
  CountryOption(name: 'Timor-Leste', code: 'TL'),
  CountryOption(name: 'Togo', code: 'TG'),
  CountryOption(name: 'Tonga', code: 'TO'),
  CountryOption(name: 'Trinidad and Tobago', code: 'TT'),
  CountryOption(name: 'Tunisia', code: 'TN'),
  CountryOption(name: 'Türkiye', code: 'TR'),
  CountryOption(name: 'Turkmenistan', code: 'TM'),
  CountryOption(name: 'Tuvalu', code: 'TV'),
  CountryOption(name: 'Uganda', code: 'UG'),
  CountryOption(name: 'Ukraine', code: 'UA'),
  CountryOption(name: 'United Arab Emirates', code: 'AE'),
  CountryOption(name: 'United Kingdom', code: 'GB'),
  CountryOption(name: 'United States', code: 'US'),
  CountryOption(name: 'Uruguay', code: 'UY'),
  CountryOption(name: 'Uzbekistan', code: 'UZ'),
  CountryOption(name: 'Vanuatu', code: 'VU'),
  CountryOption(name: 'Vatican City', code: 'VA'),
  CountryOption(name: 'Venezuela', code: 'VE'),
  CountryOption(name: 'Vietnam', code: 'VN'),
  CountryOption(name: 'Yemen', code: 'YE'),
  CountryOption(name: 'Zambia', code: 'ZM'),
  CountryOption(name: 'Zimbabwe', code: 'ZW'),
];
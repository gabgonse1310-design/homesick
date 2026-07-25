import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/person.dart';
import '../theme/app_theme.dart';
import 'country_picker_screen.dart';
import '../widgets/botanical_person_icon.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _customRelationshipController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  String? _selectedRelationship;
  String _selectedSymbol = 'assets/images/flowers/blossom.png';
  bool _showCustomRelationship = false;

  final List<String> _relationships = const [
    'Mother',
    'Father',
    'Partner',
    'Husband',
    'Wife',
    'Brother',
    'Sister',
    'Son',
    'Daughter',
    'Grandmother',
    'Grandfather',
    'Aunt',
    'Uncle',
    'Cousin',
    'Best Friend',
    'Friend',
    'Teacher',
    'Mentor',
    'Colleague',
    'Someone Special',
    'Other',
  ];

  final List<BotanicalChoice> _botanicalChoices = const [
    BotanicalChoice(
      name: 'Blossom',
      assetPath: 'assets/images/flowers/blossom.png',
    ),
    BotanicalChoice(
      name: 'Daisy',
      assetPath: 'assets/images/flowers/daisy.png',
    ),
    BotanicalChoice(
      name: 'Eucalyptus',
      assetPath: 'assets/images/flowers/eucalyptus.png',
    ),
    BotanicalChoice(
      name: 'Lavender',
      assetPath: 'assets/images/flowers/lavender.png',
    ),
    BotanicalChoice(
      name: 'Olive',
      assetPath: 'assets/images/flowers/olive.png',
    ),
    BotanicalChoice(
      name: 'Wheat',
      assetPath: 'assets/images/flowers/wheat.png',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _customRelationshipController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String get _relationship {
    if (_showCustomRelationship) {
      return _customRelationshipController.text.trim();
    }

    return _selectedRelationship ?? '';
  }

  Future<void> _pickCountry() async {
    final country = await showCountryPicker(
      context,
      selectedCountry: _countryController.text,
    );

    if (country == null || !mounted) return;

    setState(() {
      _countryController.text = country.name;
    });
  }

  void _savePerson() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final person = Person(
      name: _nameController.text.trim(),
      relationship: _relationship,
      symbol: _selectedSymbol,
      email: _emailController.text.trim().toLowerCase(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      createdYear: DateTime.now().year,
      connectionStatus: ConnectionStatus.local,
      lastActivity: 'No letters yet',
    );

    Navigator.pop(context, person);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';

    if (email.isEmpty) return null;

    final valid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);

    if (!valid) return 'Please enter a valid email address.';

    final currentEmail =
        FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();

    if (currentEmail != null && email == currentEmail) {
      return 'You cannot add your own email address.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Add Someone'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroduction(context),
                const SizedBox(height: 28),
                _sectionTitle(context, 'Their details'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Mum, Ana, Grandpa...',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Please enter their name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRelationship,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                  items: _relationships
                      .map(
                        (relationship) => DropdownMenuItem(
                          value: relationship,
                          child: Text(relationship),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRelationship = value;
                      _showCustomRelationship = value == 'Other';

                      if (!_showCustomRelationship) {
                        _customRelationshipController.clear();
                      }
                    });
                  },
                  validator: (_) {
                    if (_relationship.isEmpty) {
                      return 'Please choose or write a relationship.';
                    }
                    return null;
                  },
                ),
                if (_showCustomRelationship) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customRelationshipController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'Write the relationship',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (value) {
                      if (_showCustomRelationship &&
                          (value ?? '').trim().isEmpty) {
                        return 'Please write the relationship.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 28),
                _sectionTitle(context, 'Connection details'),
                const SizedBox(height: 8),
                Text(
                  'Add an email so Homesick can connect you, send invitations, and deliver letters.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.softGrey,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    hintText: 'Choose a country',
                    prefixIcon: const Icon(Icons.public_rounded),
                    suffixIcon: _countryController.text.trim().isEmpty
                        ? const Icon(Icons.keyboard_arrow_down_rounded)
                        : IconButton(
                            tooltip: 'Clear country',
                            onPressed: () {
                              setState(() {
                                _countryController.clear();
                              });
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onTap: _pickCountry,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City (optional)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 30),
                _buildBotanicalPicker(context),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savePerson,
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: const Text('Create Keepsake'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  Widget _buildIntroduction(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          BotanicalPersonIcon(
            symbol: _selectedSymbol,
            size: 86,
            padding: const EdgeInsets.all(8),
          ),
          const SizedBox(height: 14),
          Text(
            'Who would you like to keep close?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create their keepsake now. You can connect with them through Homesick using their email.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.softGrey,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBotanicalPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Choose their botanical emblem'),
        const SizedBox(height: 8),
        Text(
          'This flower will represent them throughout Homesick.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.softGrey,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _botanicalChoices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final choice = _botanicalChoices[index];
            final selected = choice.assetPath == _selectedSymbol;

            return _BotanicalChoiceCard(
              choice: choice,
              isSelected: selected,
              onTap: () {
                setState(() {
                  _selectedSymbol = choice.assetPath;
                });
              },
            );
          },
        ),
      ],
    );
  }
}

class _BotanicalChoiceCard extends StatelessWidget {
  final BotanicalChoice choice;
  final bool isSelected;
  final VoidCallback onTap;

  const _BotanicalChoiceCard({
    required this.choice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.paper : AppColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.terracotta
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: BotanicalPersonIcon(
                    symbol: choice.assetPath,
                    size: 68,
                    padding: const EdgeInsets.all(5),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                choice.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.terracotta
                          : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BotanicalChoice {
  final String name;
  final String assetPath;

  const BotanicalChoice({
    required this.name,
    required this.assetPath,
  });
}

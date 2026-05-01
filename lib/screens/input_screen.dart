import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/travel_request.dart';
import '../providers/travel_provider.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController();

  bool _visitedBefore = false;

  final List<String> _availablePreferences = [
    'Sehenswürdigkeiten',
    'Restaurants',
    'Nachtleben',
    'Sport',
  ];

  final Set<String> _selectedPreferences = {};

  @override
  void dispose() {
    _destinationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wähle mindestens eine Präferenz aus.'),
        ),
      );
      return;
    }

    final request = TravelRequest(
      destination: _destinationController.text.trim(),
      durationDays: int.parse(_durationController.text.trim()),
      preferences: _selectedPreferences.toList(),
      visitedBefore: _visitedBefore,
    );

    final provider = context.read<TravelProvider>();
    provider.searchPois(request);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelBuddy'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.travel_explore,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plane deine Reise',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'KI-gestützte Reiseempfehlungen',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reiseziel
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Reiseziel',
                  hintText: 'z.B. Barcelona, Spanien',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib ein Reiseziel ein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Aufenthaltsdauer
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aufenthaltsdauer (Tage)',
                  hintText: 'z.B. 7',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib die Aufenthaltsdauer ein.';
                  }
                  final days = int.tryParse(value.trim());
                  if (days == null || days < 1) {
                    return 'Bitte gib eine gültige Anzahl an Tagen ein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Schon besucht?
              SwitchListTile(
                title: const Text('Warst du schon einmal dort?'),
                subtitle: Text(
                  _visitedBefore
                      ? 'Ja – zeige mir versteckte Geheimtipps!'
                      : 'Nein – zeige mir die Highlights!',
                ),
                value: _visitedBefore,
                onChanged: (value) {
                  setState(() => _visitedBefore = value);
                },
              ),
              const SizedBox(height: 16),

              // Präferenzen
              Text(
                'Was interessiert dich?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availablePreferences.map((pref) {
                  final isSelected = _selectedPreferences.contains(pref);
                  return FilterChip(
                    label: Text(pref),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPreferences.add(pref);
                        } else {
                          _selectedPreferences.remove(pref);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submit Button
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.search),
                label: const Text('Reise planen'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

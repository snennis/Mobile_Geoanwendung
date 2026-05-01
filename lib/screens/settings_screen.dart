import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostController = TextEditingController(text: AppConfig.ollamaHost);
  final _portController = TextEditingController(
    text: AppConfig.ollamaPort.toString(),
  );
  final _modelController = TextEditingController(text: AppConfig.ollamaModel);

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _save() {
    AppConfig.ollamaHost = _hostController.text.trim();
    AppConfig.ollamaPort = int.tryParse(_portController.text.trim()) ?? 11434;
    AppConfig.ollamaModel = _modelController.text.trim();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Einstellungen gespeichert.')));
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    try {
      final host = _hostController.text.trim().isEmpty
          ? AppConfig.ollamaHost
          : _hostController.text.trim();
      final port =
          int.tryParse(_portController.text.trim()) ?? AppConfig.ollamaPort;
      final url = 'http://$host:$port/api/tags';

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Timeout: Ollama antwortet nicht'),
          );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ollama-Verbindung erfolgreich!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Verbindungsfehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ollama-Verbindung',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: 'Host / IP-Adresse',
              hintText: 'z.B. 192.168.1.100',
              prefixIcon: Icon(Icons.computer),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '11434',
              prefixIcon: Icon(Icons.settings_ethernet),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Modell',
              hintText: 'llama3.2',
              prefixIcon: Icon(Icons.smart_toy),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aktuelle URL: ${AppConfig.ollamaBaseUrl}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text('Darstellung', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Hell'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dunkel'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.settings),
                  ),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (value) {
                  themeProvider.setThemeMode(value.first);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Speichern'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.science),
            label: const Text('Verbindung testen'),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';
import '../models/poi.dart';
import '../models/travel_request.dart';
import 'nominatim_service.dart';

class OllamaService {
  final NominatimService _nominatimService = NominatimService();

  Future<List<Poi>> getPoisForTrip(TravelRequest request) async {
    final prompt = _buildTripPrompt(request);
    final response = await _query(prompt);
    return await _parsePoisFromResponse(response, request.destination);
  }

  Future<List<Poi>> getNearbyPois({
    required double latitude,
    required double longitude,
    required List<String> preferences,
  }) async {
    final prompt = _buildNearbyPrompt(latitude, longitude, preferences);
    final response = await _query(prompt);
    return await _parsePoisFromResponse(response);
  }

  String _buildTripPrompt(TravelRequest request) {
    return '''Du bist ein professioneller Reiseführer und Tourismus-Experte.

Reise-Details:
${request.toYaml()}

---

KATEGORIEN UND DEFINITIONEN:

Sehenswürdigkeiten: Ein besonders markanter, schöner oder historisch bedeutsamer Ort, Bauwerk oder Naturdenkmal, das aufgrund seiner Einmaligkeit für Touristen von großem Interesse ist. Wahrzeichen einer Region. Synonyme: Attraktion, Highlight, Publikumsmagnet, Denkmal.

Restaurants: Eine Speisewirtschaft, die Speisen und Getränke zubereitet und serviert, meist zum Verzehr vor Ort. Von Fast-Food bis Haute Cuisine.

Nachtleben: Nächtliche Vergnügungsbetriebe in Städten mit Aktivitäten wie Barbesuche, Tanzen in Clubs, Konzerte und Kinobesuche.

Sport: Körperliche und mentale Aktivitäten zur Leistungssteigerung, zum Spiel, zur Gesundheit oder zum Wettkampf. Kann Sportplätze oder Sportaktivitäten beinhalten.

---

WICHTIG - Befolge EXAKT diese Regeln:
1. Wähle NUR eine dieser 4 Kategorien: Sehenswürdigkeiten, Restaurants, Nachtleben, Sport
2. Keine Stadtteile, Wohngebiete oder generische Orte
3. Gib VOLLSTÄNDIGE Adresse an: Straße, Nummer, PLZ, Stadt
4. Gib 5-8 POIs zurück
5. Passe Empfehlungen an die Interessen an: ${request.preferences.join(', ')}

---

Antworte AUSSCHLIESSLICH mit JSON. Keine weiteren Texte.
Format:
[
  {
    "name": "Exakter Name",
    "description": "2-3 Sätze warum es sehenswert ist",
    "category": "Sehenswürdigkeiten|Restaurants|Nachtleben|Sport",
    "address": "Vollständige Adresse: Straße Nummer, PLZ Stadt",
    "opening_hours": "Öffnungszeiten oder null",
    "tip": "Praktischer Tipp"
  }
]
''';
  }

  String _buildNearbyPrompt(
    double latitude,
    double longitude,
    List<String> preferences,
  ) {
    final prefsText = preferences.join(', ');
    return '''Du bist ein Reiseführer. Nutzer-Standort:
Lat: $latitude, Lng: $longitude
Interessen: $prefsText

---

KATEGORIEN UND DEFINITIONEN:

Sehenswürdigkeiten: Ein besonders markanter, schöner oder historisch bedeutsamer Ort, Bauwerk oder Naturdenkmal, das aufgrund seiner Einmaligkeit für Touristen von großem Interesse ist. Wahrzeichen einer Region. Synonyme: Attraktion, Highlight, Publikumsmagnet, Denkmal.

Restaurants: Eine Speisewirtschaft, die Speisen und Getränke zubereitet und serviert, meist zum Verzehr vor Ort. Von Fast-Food bis Haute Cuisine.

Nachtleben: Nächtliche Vergnügungsbetriebe in Städten mit Aktivitäten wie Barbesuche, Tanzen in Clubs, Konzerte und Kinobesuche.

Sport: Körperliche und mentale Aktivitäten zur Leistungssteigerung, zum Spiel, zur Gesundheit oder zum Wettkampf. Kann Sportplätze oder Sportaktivitäten beinhalten.

---

RICHTLINIEN:
1. Wähle NUR eine dieser 4 Kategorien: Sehenswürdigkeiten, Restaurants, Nachtleben, Sport
2. Empfehle nur echte POIs im ${AppConfig.nearbyRadiusKm} km Umkreis
3. Gib VOLLSTÄNDIGE Adresse an: Straße, Nummer, PLZ, Stadt
4. POIs müssen zum Standort und den Interessen passen: $prefsText
5. 3-5 Empfehlungen

Antworte NUR JSON:
[
  {
    "name": "Name",
    "description": "2-3 Sätze",
    "category": "Sehenswürdigkeiten|Restaurants|Nachtleben|Sport",
    "address": "Vollständige Adresse: Straße Nummer, PLZ Stadt",
    "opening_hours": "Info oder null",
    "tip": "Tipp"
  }
]
''';
  }

  Future<String> _query(String prompt) async {
    final url = Uri.parse('${AppConfig.ollamaBaseUrl}/api/generate');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': AppConfig.ollamaModel,
        'prompt': prompt,
        'stream': false,
        'options': {'temperature': 0.7},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] as String;
    } else {
      throw Exception(
        'Ollama-Anfrage fehlgeschlagen: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Poi>> _parsePoisFromResponse(
    String response, [
    String? destination,
  ]) async {
    try {
      // Versuche JSON aus der Antwort zu extrahieren
      String jsonStr = response.trim();

      // Falls die Antwort in Markdown-Code-Blöcken eingebettet ist
      final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = codeBlockRegex.firstMatch(jsonStr);
      if (match != null) {
        jsonStr = match.group(1)!.trim();
      }

      // Finde das JSON-Array in der Antwort
      final arrayStart = jsonStr.indexOf('[');
      final arrayEnd = jsonStr.lastIndexOf(']');
      if (arrayStart != -1 && arrayEnd != -1) {
        jsonStr = jsonStr.substring(arrayStart, arrayEnd + 1).trim();
      }

      // Normalisiere häufige Probleme
      jsonStr = jsonStr.replaceAll(r'\"', '"').replaceAll('\\n', '\n');

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<Poi> pois = [];

      // Geocode jede Adresse
      for (final json in jsonList) {
        final address = json['address'] as String?;
        final name = json['name'] as String? ?? '';

        LatLng? coordinates;
        if (address != null && address.isNotEmpty) {
          // Versuche mit vollständiger Adresse zu geocoden
          coordinates = await _nominatimService.geocode(address);

          // Falls das fehlschlägt und wir ein Reiseziel haben, versuche mit Kontext
          if (coordinates == null && destination != null) {
            coordinates = await _nominatimService.geocodeWithContext(
              name,
              destination,
            );
          }
        }

        // Erstelle den POI mit den Koordinaten
        pois.add(
          Poi(
            name: name,
            description: json['description'] as String? ?? '',
            category: json['category'] as String? ?? 'Sonstiges',
            coordinates: coordinates,
            address: address,
            openingHours: json['opening_hours'] as String?,
            tip: json['tip'] as String?,
          ),
        );
      }

      return pois;
    } catch (e) {
      throw Exception('Fehler beim Parsen der KI-Antwort: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:yaml/yaml.dart';
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
6. Gib für jeden POI die GPS-Koordinaten (latitude, longitude) an - so genau wie möglich!

KEINE erfundenen Kategorien. KEINE Stadtteile als POIs.
Beispiel für eine FALSCHE Kategorie: "Kultur", "Architektur", "Natur"

---

Antworte AUSSCHLIESSLICH im YAML-Format. Keine weiteren Texte, keine Erklärungen.
Format:

pois:
  - name: "Exakter Name des POI"
    description: "2-3 Sätze warum es sehenswert ist"
    category: "Sehenswürdigkeiten"
    address: "Straße Nummer, PLZ Stadt"
    latitude: 48.1374
    longitude: 11.5755
    opening_hours: "Mo-So 9-18 Uhr"
    tip: "Praktischer Tipp für Besucher"
  - name: "Zweiter POI"
    description: "Beschreibung"
    category: "Restaurants"
    address: "Adresse"
    latitude: 48.1351
    longitude: 11.5820
    opening_hours: "Di-Sa 18-23 Uhr"
    tip: "Tipp"
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
6. Gib für jeden POI die GPS-Koordinaten (latitude, longitude) an!

KEINE erfundenen Kategorien.

Antworte NUR im YAML-Format:

pois:
  - name: "Name"
    description: "2-3 Sätze"
    category: "Sehenswürdigkeiten"
    address: "Straße Nummer, PLZ Stadt"
    latitude: 48.1374
    longitude: 11.5755
    opening_hours: "Info oder null"
    tip: "Tipp"
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
      // Versuche zuerst YAML-Parsing
      List<Poi> pois = _tryParseYaml(response);

      // Fallback: JSON-Parsing falls YAML fehlschlägt
      if (pois.isEmpty) {
        pois = _tryParseJson(response);
      }

      if (pois.isEmpty) {
        throw Exception('Keine POIs in der Antwort gefunden.');
      }

      // Vergleichendes Geocoding: Nominatim-Koordinaten parallel ermitteln
      final List<Poi> geocodedPois = [];
      for (final poi in pois) {
        LatLng? nominatimCoords;

        // Nominatim-Geocoding für den Vergleich
        if (poi.address != null && poi.address!.isNotEmpty) {
          nominatimCoords = await _nominatimService.geocode(poi.address!);
          if (nominatimCoords == null && destination != null) {
            nominatimCoords = await _nominatimService.geocodeWithContext(
              poi.name,
              destination,
            );
          }
        } else if (destination != null) {
          nominatimCoords = await _nominatimService.geocodeWithContext(
            poi.name,
            destination,
          );
        }

        geocodedPois.add(poi.copyWith(nominatimCoordinates: nominatimCoords));
      }

      return geocodedPois;
    } catch (e) {
      throw Exception('Fehler beim Parsen der KI-Antwort: $e');
    }
  }

  /// YAML-Antwort parsen
  List<Poi> _tryParseYaml(String response) {
    try {
      String yamlStr = response.trim();

      // Entferne Markdown-Code-Blöcke
      final codeBlockRegex = RegExp(r'```(?:ya?ml)?\s*([\s\S]*?)\s*```');
      final match = codeBlockRegex.firstMatch(yamlStr);
      if (match != null) {
        yamlStr = match.group(1)!.trim();
      }

      final parsed = loadYaml(yamlStr);
      if (parsed is! YamlMap) return [];

      final poisList = parsed['pois'];
      if (poisList is! YamlList) return [];

      return poisList.map<Poi>((item) {
        final map = Map<String, dynamic>.from(item as YamlMap);
        return Poi.fromYamlMap(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// JSON-Fallback-Parsing
  List<Poi> _tryParseJson(String response) {
    try {
      String jsonStr = response.trim();

      // Entferne Markdown-Code-Blöcke
      final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = codeBlockRegex.firstMatch(jsonStr);
      if (match != null) {
        jsonStr = match.group(1)!.trim();
      }

      // Finde JSON-Array
      final arrayStart = jsonStr.indexOf('[');
      final arrayEnd = jsonStr.lastIndexOf(']');
      if (arrayStart == -1 || arrayEnd == -1) return [];
      jsonStr = jsonStr.substring(arrayStart, arrayEnd + 1).trim();

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map<Poi>((json) => Poi.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

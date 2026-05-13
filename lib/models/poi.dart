import 'package:latlong2/latlong.dart';

/// Quelle der Geocoding-Koordinaten
enum GeocodingSource { nominatim, llm }

class Poi {
  final String name;
  final String description;
  final String category;
  final LatLng? nominatimCoordinates;
  final LatLng? llmCoordinates;
  final String? address;
  final String? openingHours;
  final String? tip;

  Poi({
    required this.name,
    required this.description,
    required this.category,
    this.nominatimCoordinates,
    this.llmCoordinates,
    this.address,
    this.openingHours,
    this.tip,
  });

  /// Primäre Koordinaten (Nominatim bevorzugt, Fallback LLM)
  LatLng? get coordinates => nominatimCoordinates ?? llmCoordinates;

  /// Prüft ob beide Geocoding-Quellen verfügbar sind
  bool get hasBothCoordinates =>
      nominatimCoordinates != null && llmCoordinates != null;

  /// Berechnet Abstand zwischen Nominatim und LLM-Koordinaten in Metern
  double? get geocodingDifferenceMeters {
    if (!hasBothCoordinates) return null;
    const distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      nominatimCoordinates!,
      llmCoordinates!,
    );
  }

  Poi copyWith({LatLng? nominatimCoordinates, LatLng? llmCoordinates}) {
    return Poi(
      name: name,
      description: description,
      category: category,
      nominatimCoordinates: nominatimCoordinates ?? this.nominatimCoordinates,
      llmCoordinates: llmCoordinates ?? this.llmCoordinates,
      address: address,
      openingHours: openingHours,
      tip: tip,
    );
  }

  factory Poi.fromYamlMap(Map<String, dynamic> map) {
    LatLng? llmCoords;
    if (map['latitude'] != null && map['longitude'] != null) {
      try {
        llmCoords = LatLng(
          double.parse(map['latitude'].toString()),
          double.parse(map['longitude'].toString()),
        );
      } catch (_) {
        llmCoords = null;
      }
    }

    return Poi(
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Sonstiges',
      llmCoordinates: llmCoords,
      address: map['address']?.toString(),
      openingHours: map['opening_hours']?.toString(),
      tip: map['tip']?.toString(),
    );
  }

  factory Poi.fromJson(Map<String, dynamic> json) {
    LatLng? llmCoords;
    if (json['latitude'] != null && json['longitude'] != null) {
      try {
        llmCoords = LatLng(
          double.parse(json['latitude'].toString()),
          double.parse(json['longitude'].toString()),
        );
      } catch (_) {
        llmCoords = null;
      }
    }

    return Poi(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Sonstiges',
      llmCoordinates: llmCoords,
      address: json['address'],
      openingHours: json['opening_hours'],
      tip: json['tip'],
    );
  }
}

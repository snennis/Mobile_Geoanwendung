import 'package:latlong2/latlong.dart';

class Poi {
  final String name;
  final String description;
  final String category;
  final LatLng? coordinates;
  final String? address;
  final String? openingHours;
  final String? tip;

  Poi({
    required this.name,
    required this.description,
    required this.category,
    this.coordinates,
    this.address,
    this.openingHours,
    this.tip,
  });

  Poi copyWith({LatLng? coordinates}) {
    return Poi(
      name: name,
      description: description,
      category: category,
      coordinates: coordinates ?? this.coordinates,
      address: address,
      openingHours: openingHours,
      tip: tip,
    );
  }

  factory Poi.fromJson(Map<String, dynamic> json) {
    LatLng? coords;
    // Versuche Koordinaten aus JSON zu extrahieren
    if (json['latitude'] != null && json['longitude'] != null) {
      try {
        coords = LatLng(
          double.parse(json['latitude'].toString()),
          double.parse(json['longitude'].toString()),
        );
      } catch (e) {
        coords = null;
      }
    }

    return Poi(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Sonstiges',
      coordinates: coords,
      address: json['address'],
      openingHours: json['opening_hours'],
      tip: json['tip'],
    );
  }
}

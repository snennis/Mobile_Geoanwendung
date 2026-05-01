import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

part 'poi_hive.g.dart';

@HiveType(typeId: 0)
class PoiHive {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String? address;

  @HiveField(4)
  final String? openingHours;

  @HiveField(5)
  final String? tip;

  @HiveField(6)
  final double? latitude;

  @HiveField(7)
  final double? longitude;

  PoiHive({
    required this.name,
    required this.description,
    required this.category,
    this.address,
    this.openingHours,
    this.tip,
    this.latitude,
    this.longitude,
  });

  LatLng? get coordinates {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }
}

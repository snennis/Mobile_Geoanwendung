import 'package:hive_flutter/hive_flutter.dart';
import '../models/poi.dart';
import '../models/poi_hive.dart';

class StorageService {
  static const String _tripsBoxName = 'trips';
  static const String _favoritesBoxName = 'favorites';

  Future<void> initializeHive() async {
    await Hive.initFlutter();
    await Hive.openBox(_tripsBoxName);
    await Hive.openBox<PoiHive>(_favoritesBoxName);
  }

  // Trip speichern
  Future<void> saveTripWithPois({
    required String destination,
    required int durationDays,
    required List<String> preferences,
    required List<Poi> pois,
  }) async {
    final box = Hive.box(_tripsBoxName);
    final tripKey = '${destination}_${DateTime.now().millisecondsSinceEpoch}';

    final trip = {
      'destination': destination,
      'duration': durationDays,
      'preferences': preferences,
      'date': DateTime.now().toString(),
      'poisCount': pois.length,
    };

    await box.put(tripKey, trip);

    // POIs als Favoriten speichern
    final favBox = Hive.box<PoiHive>(_favoritesBoxName);
    for (final poi in pois) {
      final poiHive = PoiHive(
        name: poi.name,
        description: poi.description,
        category: poi.category,
        address: poi.address,
        openingHours: poi.openingHours,
        tip: poi.tip,
        latitude: poi.coordinates?.latitude,
        longitude: poi.coordinates?.longitude,
      );
      await favBox.put('${tripKey}_${poi.name}', poiHive);
    }
  }

  // Trips auflisten
  List<Map<String, dynamic>> getTrips() {
    final box = Hive.box(_tripsBoxName);
    return box.values.cast<Map<String, dynamic>>().toList().reversed.toList();
  }

  // Favoriten abrufen
  List<PoiHive> getFavorites() {
    final box = Hive.box<PoiHive>(_favoritesBoxName);
    return box.values.toList();
  }

  // Lieblings-POI hinzufügen
  Future<void> addFavorite(Poi poi) async {
    final box = Hive.box<PoiHive>(_favoritesBoxName);
    final poiHive = PoiHive(
      name: poi.name,
      description: poi.description,
      category: poi.category,
      address: poi.address,
      openingHours: poi.openingHours,
      tip: poi.tip,
      latitude: poi.coordinates?.latitude,
      longitude: poi.coordinates?.longitude,
    );
    await box.put(poi.name, poiHive);
  }

  // Favorit löschen
  Future<void> removeFavorite(String poiName) async {
    final box = Hive.box<PoiHive>(_favoritesBoxName);
    await box.delete(poiName);
  }

  // Trip löschen
  Future<void> deleteTrip(String tripKey) async {
    final box = Hive.box(_tripsBoxName);
    await box.delete(tripKey);
  }
}

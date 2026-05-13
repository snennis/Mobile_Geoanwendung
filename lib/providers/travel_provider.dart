import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/poi.dart';
import '../models/travel_request.dart';
import '../services/ollama_service.dart';
import '../services/location_service.dart';

/// Welche Geocoding-Quelle auf der Karte angezeigt wird
enum GeocodingDisplayMode { nominatim, llm, both }

class TravelProvider extends ChangeNotifier {
  final OllamaService _ollamaService = OllamaService();
  final LocationService _locationService = LocationService();

  List<Poi> _pois = [];
  List<Poi> _nearbyPois = [];
  LatLng? _userLocation;
  bool _isLoading = false;
  String? _error;
  String? _currentDestination;
  List<String> _currentPreferences = [];
  String _loadingStatus = '';
  Set<String> _visibleCategories = {};
  GeocodingDisplayMode _geocodingDisplayMode = GeocodingDisplayMode.both;

  List<Poi> get pois => _filteredPois;
  List<Poi> get _filteredPois {
    if (_visibleCategories.isEmpty) return _pois;
    return _pois.where((p) => _visibleCategories.contains(p.category)).toList();
  }

  List<Poi> get allPois => _pois;
  List<Poi> get nearbyPois => _nearbyPois;
  LatLng? get userLocation => _userLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentDestination => _currentDestination;
  String get loadingStatus => _loadingStatus;
  Set<String> get visibleCategories => _visibleCategories;
  Set<String> get allCategories => _pois.map((p) => p.category).toSet();
  GeocodingDisplayMode get geocodingDisplayMode => _geocodingDisplayMode;

  /// Anzahl POIs mit beiden Geocoding-Quellen
  int get poisWithBothCoords => _pois.where((p) => p.hasBothCoordinates).length;

  /// Durchschnittlicher Abstand zwischen Nominatim und LLM in Metern
  double? get averageGeocodingDifference {
    final diffs = _pois
        .where((p) => p.hasBothCoordinates)
        .map((p) => p.geocodingDifferenceMeters!)
        .toList();
    if (diffs.isEmpty) return null;
    return diffs.reduce((a, b) => a + b) / diffs.length;
  }

  void setGeocodingDisplayMode(GeocodingDisplayMode mode) {
    _geocodingDisplayMode = mode;
    notifyListeners();
  }

  Future<void> searchPois(TravelRequest request) async {
    _isLoading = true;
    _error = null;
    _currentDestination = request.destination;
    _currentPreferences = request.preferences;
    _loadingStatus = 'Verbindung zu Ollama...';
    notifyListeners();

    try {
      _loadingStatus = 'POIs werden generiert (YAML + LLM-Geocoding)...';
      notifyListeners();
      final pois = await _ollamaService.getPoisForTrip(request);

      _loadingStatus = 'Vergleichendes Geocoding abgeschlossen.';
      notifyListeners();

      // Filter: mindestens eine Koordinatenquelle muss vorhanden sein
      final poisWithCoords = pois.where((p) => p.coordinates != null).toList();

      _pois = poisWithCoords;
      _visibleCategories = _pois.map((p) => p.category).toSet();
      _geocodingDisplayMode = GeocodingDisplayMode.both;
      _loadingStatus = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loadingStatus = '';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserLocation() async {
    try {
      _userLocation = await _locationService.getCurrentLocation();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchNearbyPois() async {
    _isLoading = true;
    _error = null;
    _loadingStatus = 'Standort wird ermittelt...';
    notifyListeners();

    try {
      _userLocation = await _locationService.getCurrentLocation();

      if (_userLocation == null) {
        throw Exception('Standort konnte nicht ermittelt werden.');
      }

      _loadingStatus = 'Nahegelegene Orte werden gesucht...';
      notifyListeners();
      final pois = await _ollamaService.getNearbyPois(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        preferences: _currentPreferences.isEmpty
            ? ['Sehenswürdigkeiten', 'Restaurants', 'Kultur']
            : _currentPreferences,
      );

      _loadingStatus = 'Standorte werden validiert...';
      notifyListeners();
      final poisWithCoords = pois.where((p) => p.coordinates != null).toList();

      _nearbyPois = poisWithCoords;
      _loadingStatus = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loadingStatus = '';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (_visibleCategories.contains(category)) {
      _visibleCategories.remove(category);
    } else {
      _visibleCategories.add(category);
    }
    notifyListeners();
  }

  void resetCategoryFilter() {
    _visibleCategories = _pois.map((p) => p.category).toSet();
    notifyListeners();
  }
}

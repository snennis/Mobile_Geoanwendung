import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/poi.dart';
import '../providers/travel_provider.dart';
import '../widgets/poi_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _showNearbyPois = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.currentDestination ?? 'Karte'),
            actions: [
              // Filter Button
              if (provider.allCategories.isNotEmpty)
                IconButton(
                  icon: Badge(
                    label: Text(provider.visibleCategories.length.toString()),
                    child: const Icon(Icons.filter_list),
                  ),
                  tooltip: 'Kategorien filtern',
                  onPressed: () => _showCategoryFilter(provider),
                ),
              // Toggle: Trip POIs / Nearby POIs
              if (provider.nearbyPois.isNotEmpty)
                IconButton(
                  icon: Icon(_showNearbyPois ? Icons.map : Icons.near_me),
                  tooltip: _showNearbyPois
                      ? 'Reise-POIs anzeigen'
                      : 'Nearby-POIs anzeigen',
                  onPressed: () {
                    setState(() => _showNearbyPois = !_showNearbyPois);
                  },
                ),
            ],
          ),
          body: Stack(
            children: [
              _buildMap(provider),

              // Loading Overlay
              if (provider.isLoading)
                Container(
                  color: Colors.black.withAlpha(100),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            if (provider.loadingStatus.isNotEmpty)
                              Text(provider.loadingStatus)
                            else
                              const Text('KI analysiert Reiseziele...'),
                            const SizedBox(height: 4),
                            const Text(
                              'Das kann einen Moment dauern.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Error Banner
              if (provider.error != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: MaterialBanner(
                    content: Text(provider.error!),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                    actions: [
                      TextButton(
                        onPressed: provider.clearError,
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),

              // POI-Legende
              if (!provider.isLoading && _getActivePois(provider).isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildPoiList(provider),
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Standort anzeigen
              FloatingActionButton.small(
                heroTag: 'location',
                onPressed: () => _goToUserLocation(provider),
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              // Nearby POIs suchen
              FloatingActionButton.extended(
                heroTag: 'nearby',
                onPressed: provider.isLoading
                    ? null
                    : () => _searchNearby(provider),
                icon: const Icon(Icons.explore),
                label: const Text('In der Nähe'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(TravelProvider provider) {
    final pois = _getActivePois(provider);

    // Mittelpunkt berechnen
    LatLng center = const LatLng(48.137154, 11.576124); // Default: München
    double zoom = 5.0;

    if (pois.isNotEmpty) {
      final poisWithCoords = pois.where((p) => p.coordinates != null).toList();
      if (poisWithCoords.isNotEmpty) {
        // Berechne Bounding Box
        double minLat = poisWithCoords.first.coordinates!.latitude;
        double maxLat = minLat;
        double minLng = poisWithCoords.first.coordinates!.longitude;
        double maxLng = minLng;

        for (final poi in poisWithCoords) {
          minLat = math.min(minLat, poi.coordinates!.latitude);
          maxLat = math.max(maxLat, poi.coordinates!.latitude);
          minLng = math.min(minLng, poi.coordinates!.longitude);
          maxLng = math.max(maxLng, poi.coordinates!.longitude);
        }

        // Mittelpunkt der Bounding Box
        center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

        // Zoom basierend auf Bounding Box
        final latDelta = maxLat - minLat;
        final lngDelta = maxLng - minLng;
        final delta = math.max(latDelta, lngDelta);

        if (delta < 0.01) {
          zoom = 15.0;
        } else if (delta < 0.05) {
          zoom = 13.0;
        } else if (delta < 0.1) {
          zoom = 12.0;
        } else if (delta < 0.5) {
          zoom = 10.0;
        } else {
          zoom = 8.0;
        }

        // Auto-zoom nach erstem Laden
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(center, zoom);
        });
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.travelbuddy.travel_buddy',
        ),
        // User Location Marker
        if (provider.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: provider.userLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(100),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        // POI Markers
        MarkerLayer(
          markers: pois
              .where((poi) => poi.coordinates != null)
              .map((poi) => _buildPoiMarker(poi))
              .toList(),
        ),
      ],
    );
  }

  Marker _buildPoiMarker(Poi poi) {
    return Marker(
      point: poi.coordinates!,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showPoiDetail(poi),
        child: Container(
          decoration: BoxDecoration(
            color: _getCategoryColor(poi.category),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getCategoryIcon(poi.category),
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showPoiDetail(Poi poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PoiDetailSheet(poi: poi),
    );
  }

  Widget _buildPoiList(TravelProvider provider) {
    final pois = _getActivePois(provider);
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pois.length,
        itemBuilder: (context, index) {
          final poi = pois[index];
          return GestureDetector(
            onTap: () {
              if (poi.coordinates != null) {
                _mapController.move(poi.coordinates!, 15);
              }
              _showPoiDetail(poi);
            },
            child: Card(
              margin: const EdgeInsets.only(right: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(poi.category),
                      color: _getCategoryColor(poi.category),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          poi.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          poi.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Poi> _getActivePois(TravelProvider provider) {
    return _showNearbyPois ? provider.nearbyPois : provider.pois;
  }

  void _showCategoryFilter(TravelProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategorien filtern'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...provider.allCategories.map((category) {
                final isSelected = provider.visibleCategories.contains(
                  category,
                );
                return CheckboxListTile(
                  title: Text(category),
                  value: isSelected,
                  onChanged: (_) => provider.toggleCategory(category),
                );
              }),
              const Divider(),
              TextButton(
                onPressed: () => provider.resetCategoryFilter(),
                child: const Text('Alle anzeigen'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  Future<void> _goToUserLocation(TravelProvider provider) async {
    await provider.updateUserLocation();
    if (provider.userLocation != null) {
      _mapController.move(provider.userLocation!, 15);
    }
  }

  Future<void> _searchNearby(TravelProvider provider) async {
    await provider.searchNearbyPois();
    setState(() => _showNearbyPois = true);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sehenswürdigkeiten':
        return Colors.teal;
      case 'restaurants':
        return Colors.orange;
      case 'nachtleben':
        return Colors.indigo;
      case 'sport':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sehenswürdigkeiten':
        return Icons.location_city;
      case 'restaurants':
        return Icons.restaurant;
      case 'nachtleben':
        return Icons.nightlife;
      case 'sport':
        return Icons.sports;
      default:
        return Icons.place;
    }
  }
}

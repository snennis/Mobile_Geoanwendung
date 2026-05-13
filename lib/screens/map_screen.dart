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
  bool _showLegend = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.currentDestination ?? 'Karte'),
            actions: [
              // Geocoding-Modus-Umschalter
              PopupMenuButton<GeocodingDisplayMode>(
                icon: const Icon(Icons.compare_arrows),
                tooltip: 'Geocoding-Vergleich',
                onSelected: provider.setGeocodingDisplayMode,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: GeocodingDisplayMode.both,
                    child: ListTile(
                      leading: const Icon(Icons.compare),
                      title: const Text('Beide anzeigen'),
                      trailing:
                          provider.geocodingDisplayMode ==
                              GeocodingDisplayMode.both
                          ? const Icon(Icons.check, size: 18)
                          : null,
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: GeocodingDisplayMode.nominatim,
                    child: ListTile(
                      leading: Icon(Icons.map, color: Colors.blue[700]),
                      title: const Text('Nur Nominatim'),
                      trailing:
                          provider.geocodingDisplayMode ==
                              GeocodingDisplayMode.nominatim
                          ? const Icon(Icons.check, size: 18)
                          : null,
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: GeocodingDisplayMode.llm,
                    child: ListTile(
                      leading: Icon(
                        Icons.smart_toy,
                        color: Colors.deepOrange[700],
                      ),
                      title: const Text('Nur Llama 3.2'),
                      trailing:
                          provider.geocodingDisplayMode ==
                              GeocodingDisplayMode.llm
                          ? const Icon(Icons.check, size: 18)
                          : null,
                      dense: true,
                    ),
                  ),
                ],
              ),
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

              // Geocoding-Legende
              if (!provider.isLoading &&
                  _getActivePois(provider).isNotEmpty &&
                  _showLegend)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildGeocodingLegend(provider),
                ),

              // POI-Liste unten
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
              // Legende ein/aus
              FloatingActionButton.small(
                heroTag: 'legend',
                onPressed: () => setState(() => _showLegend = !_showLegend),
                child: Icon(
                  _showLegend
                      ? Icons.legend_toggle
                      : Icons.legend_toggle_outlined,
                ),
              ),
              const SizedBox(height: 8),
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

  /// Legende für den Geocoding-Vergleich
  Widget _buildGeocodingLegend(TravelProvider provider) {
    final avgDiff = provider.averageGeocodingDifference;
    final bothCount = provider.poisWithBothCoords;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.compare_arrows, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Geocoding-Vergleich',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _legendRow(
              Colors.blue[700]!,
              Icons.map,
              'Nominatim (OSM)',
              isSquare: false,
            ),
            const SizedBox(height: 3),
            _legendRow(
              Colors.deepOrange[700]!,
              Icons.smart_toy,
              'Llama 3.2 (LLM)',
              isSquare: true,
            ),
            if (provider.geocodingDisplayMode == GeocodingDisplayMode.both) ...[
              const SizedBox(height: 3),
              _legendRow(
                Colors.grey,
                Icons.linear_scale,
                'Verbindungslinie',
                isSquare: false,
              ),
            ],
            const Divider(height: 12),
            Text(
              'Vergleich: $bothCount/${provider.pois.length} POIs',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (avgDiff != null)
              Text(
                'Ø Abweichung: ${_formatDistance(avgDiff)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(
    Color color,
    IconData icon,
    String label, {
    required bool isSquare,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isSquare ? BorderRadius.circular(3) : null,
          ),
          child: Icon(icon, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildMap(TravelProvider provider) {
    final pois = _getActivePois(provider);
    final displayMode = provider.geocodingDisplayMode;

    // Mittelpunkt berechnen
    LatLng center = const LatLng(48.137154, 11.576124);
    double zoom = 5.0;

    if (pois.isNotEmpty) {
      final poisWithCoords = pois.where((p) => p.coordinates != null).toList();
      if (poisWithCoords.isNotEmpty) {
        double minLat = poisWithCoords.first.coordinates!.latitude;
        double maxLat = minLat;
        double minLng = poisWithCoords.first.coordinates!.longitude;
        double maxLng = minLng;

        for (final poi in poisWithCoords) {
          final coords = _getAllVisibleCoords(poi, displayMode);
          for (final c in coords) {
            minLat = math.min(minLat, c.latitude);
            maxLat = math.max(maxLat, c.latitude);
            minLng = math.min(minLng, c.longitude);
            maxLng = math.max(maxLng, c.longitude);
          }
        }

        center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(center, zoom);
        });
      }
    }

    // Verbindungslinien zwischen Nominatim und LLM-Markern
    final List<Polyline> connectionLines = [];
    if (displayMode == GeocodingDisplayMode.both) {
      for (final poi in pois) {
        if (poi.hasBothCoordinates) {
          connectionLines.add(
            Polyline(
              points: [poi.nominatimCoordinates!, poi.llmCoordinates!],
              color: Colors.grey.withAlpha(180),
              strokeWidth: 2,
              pattern: const StrokePattern.dotted(),
            ),
          );
        }
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
        // Verbindungslinien
        if (connectionLines.isNotEmpty)
          PolylineLayer(polylines: connectionLines),
        // POI Markers
        MarkerLayer(markers: _buildAllMarkers(pois, displayMode)),
      ],
    );
  }

  /// Sammelt alle sichtbaren Koordinaten eines POI
  List<LatLng> _getAllVisibleCoords(Poi poi, GeocodingDisplayMode mode) {
    final coords = <LatLng>[];
    if (mode == GeocodingDisplayMode.nominatim ||
        mode == GeocodingDisplayMode.both) {
      if (poi.nominatimCoordinates != null) {
        coords.add(poi.nominatimCoordinates!);
      }
    }
    if (mode == GeocodingDisplayMode.llm || mode == GeocodingDisplayMode.both) {
      if (poi.llmCoordinates != null) {
        coords.add(poi.llmCoordinates!);
      }
    }
    // Fallback: falls im gewählten Modus keine Koordinaten vorhanden
    if (coords.isEmpty && poi.coordinates != null) {
      coords.add(poi.coordinates!);
    }
    return coords;
  }

  /// Erstellt alle Marker je nach Display-Modus
  List<Marker> _buildAllMarkers(
    List<Poi> pois,
    GeocodingDisplayMode displayMode,
  ) {
    final markers = <Marker>[];

    for (final poi in pois) {
      switch (displayMode) {
        case GeocodingDisplayMode.nominatim:
          if (poi.nominatimCoordinates != null) {
            markers.add(_buildNominatimMarker(poi));
          }
          break;
        case GeocodingDisplayMode.llm:
          if (poi.llmCoordinates != null) {
            markers.add(_buildLlmMarker(poi));
          }
          break;
        case GeocodingDisplayMode.both:
          if (poi.nominatimCoordinates != null) {
            markers.add(_buildNominatimMarker(poi));
          }
          if (poi.llmCoordinates != null) {
            markers.add(_buildLlmMarker(poi));
          }
          // Falls nur eine Quelle vorhanden, zeige mit Standard-Marker
          if (poi.nominatimCoordinates == null &&
              poi.llmCoordinates == null &&
              poi.coordinates != null) {
            markers.add(_buildFallbackMarker(poi));
          }
          break;
      }
    }

    return markers;
  }

  /// Nominatim-Marker (rund, blau)
  Marker _buildNominatimMarker(Poi poi) {
    return Marker(
      point: poi.nominatimCoordinates!,
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => _showPoiDetail(poi),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[700],
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
            size: 18,
          ),
        ),
      ),
    );
  }

  /// LLM-Marker (Quadrat, orange)
  Marker _buildLlmMarker(Poi poi) {
    return Marker(
      point: poi.llmCoordinates!,
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => _showPoiDetail(poi),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepOrange[700],
            borderRadius: BorderRadius.circular(6),
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
            size: 18,
          ),
        ),
      ),
    );
  }

  /// Fallback-Marker wenn nur eine unbekannte Quelle
  Marker _buildFallbackMarker(Poi poi) {
    return Marker(
      point: poi.coordinates!,
      width: 36,
      height: 36,
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
            size: 18,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              poi.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (poi.hasBothCoordinates) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.compare_arrows,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
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

import 'package:flutter/material.dart';
import '../models/poi.dart';

class PoiDetailSheet extends StatelessWidget {
  final Poi poi;

  const PoiDetailSheet({super.key, required this.poi});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'restaurants':
        return Icons.restaurant;
      case 'museum':
      case 'museen':
        return Icons.museum;
      case 'natur':
        return Icons.park;
      case 'strand':
      case 'strände':
        return Icons.beach_access;
      case 'shopping':
      case 'markt':
        return Icons.shopping_bag;
      case 'nachtleben':
        return Icons.nightlife;
      case 'sport':
        return Icons.sports;
      case 'kultur':
        return Icons.theater_comedy;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kategorie Chip
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(poi.category),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(poi.category),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                poi.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Beschreibung
              Text(
                poi.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),

              // Adresse
              if (poi.address != null) ...[
                _buildInfoRow(
                  context,
                  Icons.location_on_outlined,
                  'Adresse',
                  poi.address!,
                ),
                const SizedBox(height: 12),
              ],

              // Öffnungszeiten
              if (poi.openingHours != null) ...[
                _buildInfoRow(
                  context,
                  Icons.access_time,
                  'Öffnungszeiten',
                  poi.openingHours!,
                ),
                const SizedBox(height: 12),
              ],

              // Tipp
              if (poi.tip != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insider-Tipp',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                poi.tip!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Koordinaten
              if (poi.coordinates != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.my_location,
                  'Koordinaten',
                  '${poi.coordinates!.latitude.toStringAsFixed(4)}, '
                      '${poi.coordinates!.longitude.toStringAsFixed(4)}',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

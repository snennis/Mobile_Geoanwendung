class TravelRequest {
  final String destination;
  final int durationDays;
  final List<String> preferences;
  final bool visitedBefore;

  TravelRequest({
    required this.destination,
    required this.durationDays,
    required this.preferences,
    required this.visitedBefore,
  });

  String toYaml() {
    final prefsYaml = preferences.map((p) => '  - $p').join('\n');
    return '''
reiseziel: $destination
aufenthaltsdauer_tage: $durationDays
praeferenzen:
$prefsYaml
schon_besucht: $visitedBefore
''';
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<LatLng?> geocode(String query) async {
    final url = Uri.parse(
      '$_baseUrl/search',
    ).replace(queryParameters: {'q': query, 'format': 'json', 'limit': '1'});

    final response = await http.get(
      url,
      headers: {'User-Agent': 'TravelBuddy/1.0'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> results = jsonDecode(response.body);
      if (results.isNotEmpty) {
        final lat = double.parse(results[0]['lat']);
        final lon = double.parse(results[0]['lon']);
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  Future<LatLng?> geocodeWithContext(String name, String destination) async {
    // Versuche zuerst mit dem Ortsnamen + Reiseziel (für besseren Kontext)
    var result = await geocode('$name, $destination');
    if (result != null) return result;

    // Zweiter Versuch: nur Reiseziel verwenden (für Städtenamen)
    result = await geocode(destination);
    if (result != null) return result;

    // Letzter Versuch: nur Ortsname
    return geocode(name);
  }
}

# TravelBuddy

TravelBuddy ist eine Flutter-App zur KI-gestuetzten Reiseplanung. Die App generiert passende Points of Interest (POIs) fuer ein Reiseziel, zeigt sie auf einer interaktiven OpenStreetMap-Karte an und vergleicht dabei Koordinaten aus zwei Quellen: Nominatim und einem lokal angebundenen LLM ueber Ollama.

## Funktionen

- Onboarding fuer die wichtigsten App-Funktionen
- Reiseplanung mit Ziel, Aufenthaltsdauer, Interessen und Erstbesuch-Status
- KI-generierte POI-Empfehlungen in den Kategorien:
  - Sehenswuerdigkeiten
  - Restaurants
  - Nachtleben
  - Sport
- Kartenansicht mit `flutter_map` und OpenStreetMap-Tiles
- Geocoding-Vergleich zwischen Nominatim und Llama 3.2
- Filter nach POI-Kategorien
- Detailansicht fuer POIs mit Beschreibung, Adresse, Oeffnungszeiten und Tipp
- Suche nach POIs in der Naehe des aktuellen Standorts
- Hell-, Dunkel- und System-Theme
- Konfigurierbare Ollama-Verbindung in den App-Einstellungen

## Tech-Stack

- Flutter / Dart
- Provider fuer State Management
- flutter_map und latlong2 fuer die Kartenansicht
- Geolocator und permission_handler fuer Standortzugriff
- Ollama als lokale LLM-Schnittstelle
- Nominatim fuer OpenStreetMap-Geocoding

## Voraussetzungen

- Flutter SDK mit Dart `^3.10.4`
- Android Studio oder Xcode fuer Emulatoren bzw. Geraete
- Lokale Ollama-Installation
- Ollama-Modell `llama3.2`

Ollama starten und Modell bereitstellen:

```bash
ollama serve
ollama pull llama3.2
```

Standardmaessig erwartet die App Ollama unter:

```text
http://localhost:11434
```

Auf einem physischen Smartphone muss statt `localhost` die IP-Adresse des Rechners eingetragen werden, auf dem Ollama laeuft. Das geht in der App ueber `Einstellungen -> Ollama-Verbindung`.

## Installation

Abhaengigkeiten installieren:

```bash
flutter pub get
```

App starten:

```bash
flutter run
```

Optional kann die App direkt fuer eine Zielplattform gebaut werden:

```bash
flutter build apk
flutter build ios
```

## Nutzung

1. App starten und Onboarding abschliessen.
2. In den Einstellungen Host, Port und Modell fuer Ollama pruefen.
3. Reiseziel, Aufenthaltsdauer und Interessen auswaehlen.
4. `Reise planen` antippen.
5. POIs auf der Karte ansehen, Kategorien filtern oder den Geocoding-Vergleich umschalten.
6. Mit `In der Naehe` koennen zusaetzliche POIs rund um den aktuellen Standort gesucht werden.

## Datenquellen und Hinweise

Die POI-Vorschlaege werden durch das konfigurierte Ollama-Modell erzeugt. Nominatim wird zusaetzlich genutzt, um Adressen zu geocodieren und die LLM-Koordinaten auf der Karte vergleichbar zu machen.

Die App benoetigt fuer die Nearby-Suche Standortberechtigungen. Ohne aktivierte Standortdienste bleibt die normale Reiseplanung weiterhin nutzbar.

## Projektstruktur

```text
lib/
  config/       App-Konfiguration fuer Ollama und Nearby-Radius
  models/       Datenmodelle fuer Reiseanfragen und POIs
  providers/    State Management fuer Reisen und Theme
  screens/      Onboarding, Eingabe, Karte und Einstellungen
  services/     Ollama-, Nominatim- und Standort-Service
  widgets/      Wiederverwendbare UI-Komponenten
```

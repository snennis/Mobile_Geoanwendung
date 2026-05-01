class AppConfig {
  static String ollamaHost = 'localhost';
  static int ollamaPort = 11434;
  static String ollamaModel = 'llama3.2';

  static String get ollamaBaseUrl => 'http://$ollamaHost:$ollamaPort';

  static const double nearbyRadiusKm = 2.0;
}

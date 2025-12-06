/// API Constants for Arc Badminton Backend
class ApiConstants {
  ApiConstants._();

  /// Base URL for the API server
  static const String baseUrl = 'https://kevin-maladapted-instinctively.ngrok-free.dev';

  /// API endpoints
  static const String healthCheck = '/health';
  static const String courts = '/api/courts';
  static const String nearbyCourts = '/api/courts/nearby';

  /// Court availability endpoint pattern: /api/courts/:courtId/availability
  static String courtAvailability(String courtId) =>
      '/api/courts/$courtId/availability';

  /// Map tiles endpoint pattern: /api/map-tiles/{z}/{x}/{y}.pbf
  static String mapTilesUrl(int z, int x, int y) =>
      '$baseUrl/api/map-tiles/$z/$x/$y.pbf';

  /// Map tiles template URL for Mapbox
  static const String mapTilesTemplate =
      '$baseUrl/api/map-tiles/{z}/{x}/{y}.pbf';
}

/// API Constants for Smatch Badminton Backend
class ApiConstants {
  ApiConstants._();

  /// Base URL for the API server
  /// Set via --dart-define=API_BASE_URL=https://your-api-url.com
  /// Default is localhost for development - MUST be configured for production
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// WebSocket URL for the API server
  static String get wsUrl {
    // Convert https:// to wss:// or http:// to ws://
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
    return 'wss://${baseUrl.replaceFirst(RegExp(r'^https?://'), '')}';
  }

  /// API endpoints
  static const String healthCheck = '/health';
  static const String courts = '/api/courts';
  static const String nearbyCourts = '/api/courts/nearby';

  /// Search endpoints
  static const String searchAutocomplete = '/api/search/autocomplete';
  static const String searchCourts = '/api/search/courts';

  /// Booking endpoints
  static const String bookings = '/api/bookings';

  /// Payment endpoints
  static const String paymentsCreate = '/api/payments/create';
  static const String payments = '/api/payments';

  /// Get payment by ID
  static String paymentById(String id) => '/api/payments/$id';

  /// Get payment status
  static String paymentStatus(String id) => '/api/payments/$id/status';

  /// Get booking by ID
  static String bookingById(String id) => '/api/bookings/$id';

  /// Get payment for booking
  static String bookingPayment(String bookingId) => '/api/bookings/$bookingId/payment';

  /// WebSocket endpoint for payment updates
  static String get wsPayments => '$wsUrl/ws/payments';

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

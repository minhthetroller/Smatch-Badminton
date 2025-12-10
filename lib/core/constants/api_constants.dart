import '../config/env.dart';

/// API Constants for Smatch Badminton Backend
class ApiConstants {
  ApiConstants._();

  /// Base URL for the API server loaded from environment
  static String get baseUrl => Env.apiBaseUrl;

  /// WebSocket URL for the API server
  static String get wsUrl {
    final url = baseUrl;
    // Convert https:// to wss:// or http:// to ws://
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'wss://');
    } else if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'ws://');
    }
    return 'wss://${url.replaceFirst(RegExp(r'^https?://'), '')}';
  }

  /// API endpoints
  static const String healthCheck = '/health';
  static const String courts = '/api/courts';
  static const String nearbyCourts = '/api/courts/nearby';

  /// Auth endpoints
  static const String authVerify = '/api/auth/verify';
  static const String authAnonymous = '/api/auth/anonymous';
  static const String authConvert = '/api/auth/convert';
  static const String authMe = '/api/auth/me';
  static const String authMeBookings = '/api/auth/me/bookings';
  static const String authUsernameCheck = '/api/auth/username/check';
  static const String authUsernameLookup = '/api/auth/username/lookup';
  static const String authLinkBookings = '/api/auth/link-bookings';
  static const String authDeleteAccount = '/api/auth/account';

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
  static String get mapTilesTemplate =>
      '$baseUrl/api/map-tiles/{z}/{x}/{y}.pbf';
}

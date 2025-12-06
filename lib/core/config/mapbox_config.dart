/// Mapbox configuration
///
/// **IMPORTANT**: You need to set your Mapbox access token before running the app.
///
/// Get your token from: https://account.mapbox.com/access-tokens/
///
/// ## How to set the token:
///
/// ### Option 1: Run with dart-define (recommended)
/// ```bash
/// flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here
/// ```
///
/// ### Option 2: Set directly in this file (development only)
/// Change the `_defaultToken` value below.
class MapboxConfig {
  MapboxConfig._();

  // TODO: Replace with your Mapbox public access token for development
  // Get your token from https://account.mapbox.com/access-tokens/
  static const String _defaultToken = 'DEFAULT_TOKEN';

  /// Mapbox public access token
  static const String accessToken = String.fromEnvironment(
    'DEFAULT_TOKEN',
    defaultValue: 'pk.eyJ1IjoibnRtMTEwNSIsImEiOiJjbWlmaXRyNmowNDUyM2VwanJzZW04NzBpIn0.Amqbl3Er-JjNERTNbl21lA',
  );

  /// Check if access token is configured
  static bool get isConfigured =>
      accessToken.isNotEmpty &&
      accessToken.startsWith('pk.') &&
      accessToken.length > 50;
}

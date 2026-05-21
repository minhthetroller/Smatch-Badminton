import 'env.dart';

/// Mapbox configuration
///
/// **IMPORTANT**: You need to set your Mapbox access token before running the app.
///
/// Get your token from: https://account.mapbox.com/access-tokens/
///
/// ## How to set the token:
///
/// 1. Copy `.env.example` to `.env`
/// 2. Add your Mapbox token: `MAPBOX_ACCESS_TOKEN=pk.your_token_here`
/// 3. Run `dart run build_runner build --delete-conflicting-outputs`
class MapboxConfig {
  MapboxConfig._();

  /// Mapbox public access token loaded from environment
  static String get accessToken => Env.mapboxAccessToken;

  /// Check if access token is configured
  static bool get isConfigured =>
      accessToken.isNotEmpty &&
      accessToken.startsWith('pk.') &&
      accessToken.length > 50;
}

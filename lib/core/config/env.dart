import 'package:envied/envied.dart';

part 'env.g.dart';

/// Environment configuration using envied
/// 
/// This file reads from `.env` at build time and generates `env.g.dart`.
/// 
/// ## Setup:
/// 1. Copy `.env.example` to `.env`
/// 2. Fill in your values in `.env`
/// 3. Run `dart run build_runner build --delete-conflicting-outputs`
/// 
/// ## Important:
/// - Never commit `.env` to version control
/// - The generated `env.g.dart` contains obfuscated values
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  /// Mapbox public access token
  /// Get your token from: https://account.mapbox.com/access-tokens/
  @EnviedField(varName: 'MAPBOX_ACCESS_TOKEN', defaultValue: '')
  static String mapboxAccessToken = _Env.mapboxAccessToken;

  /// API base URL for the backend server
  @EnviedField(varName: 'API_BASE_URL', defaultValue: 'http://localhost:3000')
  static String apiBaseUrl = _Env.apiBaseUrl;
}


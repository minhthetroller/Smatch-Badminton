import '../config/env.dart';

/// Helper class for transforming image URLs to use backend S3 proxy
///
/// Transforms LocalStack S3 URLs to use the backend's S3 proxy endpoint,
/// which is accessible via ngrok in development.
///
/// Example transformations:
/// - Input:  http://localhost:4566/smatch-photos/users/123/profile.jpg
/// - Output: https://your-ngrok-url.ngrok.io/api/s3-proxy/smatch-photos/users/123/profile.jpg
class ImageUrlHelper {
  static final RegExp _localS3Pattern = RegExp(
    r'^http://(localhost|127\.0\.0\.1|localstack|s3\.localhost\.localstack\.cloud):4566/',
  );
  static const String _s3ProxyPath = '/api/s3-proxy/';

  /// Headers required for loading images through ngrok proxy.
  /// ngrok free tier shows an interstitial page unless this header is present.
  static Map<String, String> get imageHeaders {
    final baseUrl = Env.apiBaseUrl;
    if (baseUrl.contains('ngrok')) {
      return {'ngrok-skip-browser-warning': 'true'};
    }
    return {};
  }

  /// Transform S3 image URL to use backend proxy
  ///
  /// If the URL contains a LocalStack S3 host, it replaces it with the API
  /// base URL and adds the /api/s3-proxy/ path.
  ///
  /// Otherwise, returns the URL unchanged.
  static String transformImageUrl(String url) {
    final match = _localS3Pattern.firstMatch(url);
    if (match != null) {
      // Extract the bucket and key from the LocalStack URL.
      final path = url.substring(match.end);

      // Construct proxied URL through backend
      // Format: https://api-base-url/api/s3-proxy/bucket/key/path
      return '${Env.apiBaseUrl}$_s3ProxyPath$path';
    }

    // If already using proxy path or external URL, return as-is
    return url;
  }

  /// Transform a list of image URLs
  static List<String> transformImageUrls(List<String> urls) {
    return urls.map((url) => transformImageUrl(url)).toList();
  }
}

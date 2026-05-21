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
  static const String _s3ProxyPath = '/api/s3-proxy/';
  static const int _localStackPort = 4566;
  static const Set<String> _localStackHosts = {
    'localhost',
    '127.0.0.1',
    'localstack',
    's3.localhost.localstack.cloud',
  };
  static const String _virtualHostedSuffix =
      '.s3.localhost.localstack.cloud';

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
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'http' ||
        uri.port != _localStackPort ||
        !_isLocalStackHost(uri.host)) {
      return url;
    }

    final path = _localStackProxyPath(uri);
    if (path.isEmpty) return url;

    final baseUrl = Env.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return '$baseUrl$_s3ProxyPath$path';
  }

  /// Transform a list of image URLs
  static List<String> transformImageUrls(List<String> urls) {
    return urls.map((url) => transformImageUrl(url)).toList();
  }

  static bool _isLocalStackHost(String host) {
    return _localStackHosts.contains(host) ||
        host.endsWith(_virtualHostedSuffix);
  }

  static String _localStackProxyPath(Uri uri) {
    final path = uri.pathSegments.join('/');

    if (uri.host.endsWith(_virtualHostedSuffix) &&
        uri.host != 's3.localhost.localstack.cloud') {
      final bucket = uri.host.substring(
        0,
        uri.host.length - _virtualHostedSuffix.length,
      );
      return [bucket, if (path.isNotEmpty) path].join('/');
    }

    return path;
  }
}

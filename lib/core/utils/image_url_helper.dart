import '../config/env.dart';

/// Helper class for transforming image URLs for local development
///
/// In local development the backend stores images in LocalStack S3 and
/// returns URLs like `http://localhost:4566/<bucket>/<key>`. LocalStack S3
/// is directly reachable from the app, so these URLs are returned unchanged.
///
/// Real AWS S3 URLs (`https://<bucket>.s3.amazonaws.com/<key>`) cannot be
/// resolved in local development, so they are routed through the backend's
/// S3 proxy at `/api/s3-proxy/` when one is available. If the backend does
/// not expose an S3 proxy, the URLs are still returned transformed and will
/// simply fail to load — the backend should be configured to return
/// directly reachable URLs instead.
class ImageUrlHelper {
  /// Virtual-hosted-style: `https://<bucket>.s3.amazonaws.com/<key>`
  static final RegExp _virtualHostedS3Pattern = RegExp(
    r'^https://([a-z0-9][a-z0-9.\-]*)\.s3(?:\.[a-z0-9-]+)?\.amazonaws\.com/',
  );

  /// Path-style: `https://s3.amazonaws.com/<bucket>/<key>`
  static final RegExp _pathStyleS3Pattern = RegExp(
    r'^https://s3(?:\.[a-z0-9-]+)?\.amazonaws\.com/',
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

  /// Transform an image URL for the current environment.
  ///
  /// LocalStack S3 URLs (`http://localhost:4566/...`) are returned unchanged
  /// because LocalStack is directly reachable in local development.
  ///
  /// Real AWS S3 URLs (virtual-hosted and path-style) are routed through the
  /// backend's S3 proxy at `/api/s3-proxy/` since the S3 hostname is not
  /// resolvable in local development.
  ///
  /// URLs already using the proxy path or external CDN URLs are returned
  /// unchanged.
  static String transformImageUrl(String url) {
    // Virtual-hosted-style S3 — bucket is in the host, path is <key>
    final vhostMatch = _virtualHostedS3Pattern.firstMatch(url);
    if (vhostMatch != null) {
      final bucket = vhostMatch.group(1)!;
      final key = url.substring(vhostMatch.end);
      return '${Env.apiBaseUrl}$_s3ProxyPath$bucket/$key';
    }

    // Path-style S3 — bucket is the first segment of the path
    final pathMatch = _pathStyleS3Pattern.firstMatch(url);
    if (pathMatch != null) {
      final path = url.substring(pathMatch.end);
      return '${Env.apiBaseUrl}$_s3ProxyPath$path';
    }

    // LocalStack S3, already-proxied URLs, and external URLs are returned as-is
    return url;
  }

  /// Transform a list of image URLs
  static List<String> transformImageUrls(List<String> urls) {
    return urls.map((url) => transformImageUrl(url)).toList();
  }
}

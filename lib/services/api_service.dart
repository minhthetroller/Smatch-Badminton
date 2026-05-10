import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/api_constants.dart';

/// Exception thrown when API request fails
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Base API service for making HTTP requests
class ApiService {
  final http.Client _client;
  final String baseUrl;
  
  /// Global auth token - set by AuthViewModel on login
  static String? _globalAuthToken;
  
  /// Set the global auth token (call this after authentication)
  static void setGlobalAuthToken(String? token) {
    _globalAuthToken = token;
  }
  
  /// Get the current global auth token
  static String? get globalAuthToken => _globalAuthToken;

  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? ApiConstants.baseUrl;

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
      );

      final response = await _client.get(uri, headers: _defaultHeaders);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.post(
        uri,
        headers: _defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.put(
        uri,
        headers: _defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final request = http.Request('DELETE', uri);
      request.headers.addAll(_defaultHeaders);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  // ==================== Authenticated Requests ====================

  /// GET request with authentication
  Future<Map<String, dynamic>> getWithAuth(
    String endpoint, {
    required String authToken,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
      );

      final response = await _client.get(
        uri,
        headers: _authHeaders(authToken),
      );

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  /// POST request with authentication
  Future<Map<String, dynamic>> postWithAuth(
    String endpoint, {
    required String authToken,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.post(
        uri,
        headers: _authHeaders(authToken),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  /// PUT request with authentication
  Future<Map<String, dynamic>> putWithAuth(
    String endpoint, {
    required String authToken,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.put(
        uri,
        headers: _authHeaders(authToken),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  /// DELETE request with authentication
  Future<Map<String, dynamic>> deleteWithAuth(
    String endpoint, {
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.delete(
        uri,
        headers: _authHeaders(authToken),
      );

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  // ==================== Multipart Requests ====================

  /// POST multipart request with authentication and retry logic
  /// 
  /// Parameters:
  /// - [endpoint]: API endpoint
  /// - [authToken]: Authentication token
  /// - [fields]: Form fields (key-value pairs)
  /// - [files]: Files to upload (field name -> file)
  /// - [maxRetries]: Number of retry attempts (default: 3)
  /// - [retryDelay]: Delay between retries in milliseconds (default: 1000)
  /// 
  /// Returns the parsed JSON response
  Future<Map<String, dynamic>> postMultipartWithAuth(
    String endpoint, {
    required String authToken,
    Map<String, String>? fields,
    Map<String, File>? files,
    int maxRetries = 3,
    int retryDelay = 1000,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint');
        final request = http.MultipartRequest('POST', uri);

        // Add headers (no Content-Type, let the client set it with boundary)
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          // ngrok free tier requires this header to bypass interstitial page
          if (baseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
        });

        // Add fields
        if (fields != null) {
          request.fields.addAll(fields);
        }

        // Add files
        if (files != null) {
          for (final entry in files.entries) {
            final file = entry.value;
            final filename = file.path.split('/').last;
            
            // Determine content type based on file extension
            String mimeType = 'image/jpeg';
            if (filename.toLowerCase().endsWith('.png')) {
              mimeType = 'image/png';
            } else if (filename.toLowerCase().endsWith('.webp')) {
              mimeType = 'image/webp';
            }

            final multipartFile = await http.MultipartFile.fromPath(
              entry.key,
              file.path,
              contentType: MediaType.parse(mimeType),
              filename: filename,
            );

            request.files.add(multipartFile);
          }
        }

        // Send request
        final streamedResponse = await _client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        return _handleResponse(response);
      } on SocketException {
        attempt++;
        if (attempt >= maxRetries) {
          throw ApiException('No internet connection');
        }
        await Future.delayed(Duration(milliseconds: retryDelay * attempt));
      } catch (e) {
        // HTTP errors (ApiException with statusCode) should not be retried
        if (e is ApiException) rethrow;
        attempt++;
        if (attempt >= maxRetries) {
          throw ApiException('Request failed after $maxRetries attempts: ${e.toString()}');
        }
        await Future.delayed(Duration(milliseconds: retryDelay * attempt));
      }
    }

    throw ApiException('Request failed after $maxRetries attempts');
  }

  /// POST multipart request with multiple files for the same field
  /// Useful for uploading multiple images to a single field (e.g., images[])
  Future<Map<String, dynamic>> postMultipartWithAuthMultipleFiles(
    String endpoint, {
    required String authToken,
    Map<String, String>? fields,
    String? filesFieldName,
    List<File>? files,
    int maxRetries = 3,
    int retryDelay = 1000,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint');
        final request = http.MultipartRequest('POST', uri);

        // Add headers
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          // ngrok free tier requires this header to bypass interstitial page
          if (baseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
        });

        // Add fields
        if (fields != null) {
          request.fields.addAll(fields);
        }

        // Add multiple files
        if (files != null && files.isNotEmpty && filesFieldName != null) {
          for (final file in files) {
            final filename = file.path.split('/').last;
            
            // Determine content type
            String mimeType = 'image/jpeg';
            if (filename.toLowerCase().endsWith('.png')) {
              mimeType = 'image/png';
            } else if (filename.toLowerCase().endsWith('.webp')) {
              mimeType = 'image/webp';
            }

            final multipartFile = await http.MultipartFile.fromPath(
              filesFieldName,
              file.path,
              contentType: MediaType.parse(mimeType),
              filename: filename,
            );

            request.files.add(multipartFile);
          }
        }

        // Send request
        final streamedResponse = await _client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        return _handleResponse(response);
      } on SocketException {
        attempt++;
        if (attempt >= maxRetries) {
          throw ApiException('No internet connection after $maxRetries attempts');
        }
        await Future.delayed(Duration(milliseconds: retryDelay * attempt));
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          if (e is ApiException) rethrow;
          throw ApiException('Request failed after $maxRetries attempts: ${e.toString()}');
        }
        await Future.delayed(Duration(milliseconds: retryDelay * attempt));
      }
    }
    
    throw ApiException('Request failed after $maxRetries attempts');
  }

  /// Default headers
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // ngrok free tier requires this header to bypass interstitial page
    if (baseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
  };

  /// Headers with authentication
  Map<String, String> _authHeaders(String authToken) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $authToken',
    // ngrok free tier requires this header to bypass interstitial page
    if (baseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
  };

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final errorMessage = body['error']?['message'] ?? 'Unknown error occurred';
    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  /// Dispose client
  void dispose() {
    _client.close();
  }
}

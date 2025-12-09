import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.delete(uri, headers: _defaultHeaders);

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

  /// Default headers
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers with authentication
  Map<String, String> _authHeaders(String authToken) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $authToken',
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

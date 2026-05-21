import '../core/constants/api_constants.dart';
import '../models/availability.dart';
import '../models/court.dart';
import '../models/api_response.dart';
import '../models/search_suggestion.dart';
import 'api_service.dart';

/// Service for court-related API calls
class CourtService {
  final ApiService _apiService;

  CourtService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Get all courts with pagination
  Future<ApiResponse<List<Court>>> getCourts({
    int page = 1,
    int limit = 10,
    String? district,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (district != null && district.isNotEmpty) {
      queryParams['district'] = district;
    }

    final response = await _apiService.get(
      ApiConstants.courts,
      queryParams: queryParams,
    );

    return ApiResponse.fromJson(
      response,
      (data) => (data as List)
          .map((item) => Court.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get court by ID
  Future<ApiResponse<Court>> getCourtById(String id) async {
    final response = await _apiService.get('${ApiConstants.courts}/$id');

    return ApiResponse.fromJson(
      response,
      (data) => Court.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Find nearby courts
  Future<ApiResponse<List<Court>>> getNearbyCourts({
    required double latitude,
    required double longitude,
    double radius = 5,
    bool radiusIsMeters = false,
  }) async {
    // Backend nearby endpoint expects meters, while app callers typically
    // provide kilometers (e.g., 5 => 5km).
    final radiusMeters = radiusIsMeters ? radius : radius * 1000;

    final response = await _apiService.get(
      ApiConstants.nearbyCourts,
      queryParams: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radiusMeters.toStringAsFixed(0),
      },
    );

    return ApiResponse.fromJson(
      response,
      (data) => (data as List)
          .map((item) => Court.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Create a new court
  Future<ApiResponse<Court>> createCourt(Court court) async {
    final response = await _apiService.post(
      ApiConstants.courts,
      body: court.toJson(),
    );

    return ApiResponse.fromJson(
      response,
      (data) => Court.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update a court
  Future<ApiResponse<Court>> updateCourt(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiService.put(
      '${ApiConstants.courts}/$id',
      body: updates,
    );

    return ApiResponse.fromJson(
      response,
      (data) => Court.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Delete a court
  Future<ApiResponse<void>> deleteCourt(String id) async {
    final response = await _apiService.delete('${ApiConstants.courts}/$id');

    return ApiResponse.fromJson(response, null);
  }

  /// Get court availability for a specific date
  Future<ApiResponse<CourtAvailability>> getCourtAvailability({
    required String courtId,
    required String date,
  }) async {
    final response = await _apiService.get(
      ApiConstants.courtAvailability(courtId),
      queryParams: {'date': date},
    );

    return ApiResponse.fromJson(
      response,
      (data) => CourtAvailability.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get autocomplete suggestions for search query
  /// Supports Vietnamese diacritics - searches both accented and unaccented text
  /// When includeDetails is true, response includes address and coordinates
  Future<ApiResponse<List<SearchSuggestion>>> getAutocomplete({
    required String query,
    int limit = 10,
    bool includeDetails = true,
  }) async {
    // API requires minimum 2 characters
    if (query.length < 2) {
      return ApiResponse(success: true, data: []);
    }

    final response = await _apiService.get(
      ApiConstants.searchAutocomplete,
      queryParams: {
        'q': query,
        'limit': limit.toString(),
        'includeDetails': includeDetails.toString(),
      },
    );

    return ApiResponse.fromJson(response, (data) {
      final suggestions = data['suggestions'] as List?;
      if (suggestions == null) return <SearchSuggestion>[];
      return suggestions
          .map(
            (item) => SearchSuggestion.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Dispose service
  void dispose() {
    _apiService.dispose();
  }
}

import '../core/constants/api_constants.dart';
import '../models/court.dart';
import '../models/api_response.dart';
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
  }) async {
    final response = await _apiService.get(
      ApiConstants.nearbyCourts,
      queryParams: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
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

  /// Dispose service
  void dispose() {
    _apiService.dispose();
  }
}

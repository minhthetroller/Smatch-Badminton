import '../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/match.dart';
import 'api_service.dart';
import 'dart:io';

/// Service for match-related API calls
class MatchService {
  final ApiService _apiService;

  MatchService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get the current auth token
  String? get _authToken => ApiService.globalAuthToken;

  /// Throw exception if no auth token is available
  void _requireAuth() {
    if (_authToken == null) {
      throw ApiException('Authorization header required', statusCode: 401);
    }
  }

  /// Get all matches with pagination and filters
  Future<ApiResponse<List<MatchWithDetails>>> getMatches({
    int page = 1,
    int limit = 10,
    String? courtId,
    SkillLevel? skillLevel,
    PlayerFormat? playerFormat,
    MatchStatus? status,
    String? date,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (courtId != null) queryParams['courtId'] = courtId;
    if (skillLevel != null) queryParams['skillLevel'] = skillLevel.value;
    if (playerFormat != null) queryParams['playerFormat'] = playerFormat.value;
    if (status != null) queryParams['status'] = status.value;
    if (date != null) queryParams['date'] = date;
    if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
    if (dateTo != null) queryParams['dateTo'] = dateTo;

    final response = await _apiService.get(
      ApiConstants.matches,
      queryParams: queryParams,
    );

    return ApiResponse.fromJson(
      response,
      (data) => (data as List)
          .map((item) => MatchWithDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get matches hosted by current user
  Future<ApiResponse<List<MatchWithDetails>>> getHostedMatches({
    MatchStatus? status,
    bool includeExpired = false,
  }) async {
    _requireAuth();
    
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status.value;
    if (includeExpired) queryParams['includeExpired'] = 'true';

    final response = await _apiService.getWithAuth(
      ApiConstants.matchesHosted,
      authToken: _authToken!,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    return ApiResponse.fromJson(
      response,
      (data) => (data as List)
          .map((item) => MatchWithDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get matches joined by current user
  Future<ApiResponse<List<MatchWithDetails>>> getJoinedMatches({
    bool includeExpired = false,
  }) async {
    _requireAuth();
    
    final queryParams = <String, String>{};
    if (includeExpired) queryParams['includeExpired'] = 'true';
    
    final response = await _apiService.getWithAuth(
      ApiConstants.matchesJoined,
      authToken: _authToken!,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    return ApiResponse.fromJson(
      response,
      (data) => (data as List)
          .map((item) => MatchWithDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get match by ID
  /// Uses auth token if available to get currentUserStatus
  Future<ApiResponse<MatchWithDetails>> getMatchById(String id) async {
    final Map<String, dynamic> response;
    
    // Use authenticated request if token is available
    // This enables the API to return currentUserStatus for the user
    if (_authToken != null) {
      response = await _apiService.getWithAuth(
        ApiConstants.matchById(id),
        authToken: _authToken!,
      );
    } else {
      response = await _apiService.get(ApiConstants.matchById(id));
    }

    return ApiResponse.fromJson(
      response,
      (data) => MatchWithDetails.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Create a new match
  Future<ApiResponse<MatchWithDetails>> createMatch(
      CreateMatchRequest request) async {
    _requireAuth();
    
    final response = await _apiService.postWithAuth(
      ApiConstants.matches,
      authToken: _authToken!,
      body: request.toJson(),
    );

    return ApiResponse.fromJson(
      response,
      (data) => MatchWithDetails.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Upload a single image file and return its public S3 URL
  Future<String> _uploadImage(File image) async {
    final response = await _apiService.postMultipartWithAuth(
      ApiConstants.matchImageUpload,
      authToken: _authToken!,
      files: {'image': image},
    );
    final data = response['data'];
    if (data is Map<String, dynamic> && data['url'] is String) {
      return data['url'] as String;
    }
    throw ApiException('Image upload failed: unexpected response format');
  }

  /// Create a new match, uploading images first then posting JSON
  Future<ApiResponse<MatchWithDetails>> createMatchWithImages(
    CreateMatchRequest request,
    List<File> images,
  ) async {
    _requireAuth();

    final imageUrls = <String>[];
    for (final image in images) {
      final url = await _uploadImage(image);
      imageUrls.add(url);
    }

    final requestWithImages = CreateMatchRequest(
      courtId: request.courtId,
      title: request.title,
      description: request.description,
      images: imageUrls.isNotEmpty ? imageUrls : null,
      skillLevel: request.skillLevel,
      shuttleType: request.shuttleType,
      playerFormat: request.playerFormat,
      date: request.date,
      startTime: request.startTime,
      endTime: request.endTime,
      isPrivate: request.isPrivate,
      price: request.price,
      slotsNeeded: request.slotsNeeded,
    );

    final response = await _apiService.postWithAuth(
      ApiConstants.matches,
      authToken: _authToken!,
      body: requestWithImages.toJson(),
    );

    return ApiResponse.fromJson(
      response,
      (data) => MatchWithDetails.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update a match
  Future<ApiResponse<MatchWithDetails>> updateMatch(
    String id,
    UpdateMatchRequest request,
  ) async {
    _requireAuth();
    
    final response = await _apiService.putWithAuth(
      ApiConstants.matchById(id),
      authToken: _authToken!,
      body: request.toJson(),
    );

    return ApiResponse.fromJson(
      response,
      (data) => MatchWithDetails.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Cancel (delete) a match
  Future<ApiResponse<void>> cancelMatch(String id) async {
    _requireAuth();
    
    final response = await _apiService.deleteWithAuth(
      ApiConstants.matchById(id),
      authToken: _authToken!,
    );
    return ApiResponse.fromJson(response, null);
  }

  /// Join a match
  Future<ApiResponse<MatchPlayer>> joinMatch(
    String matchId, {
    JoinMatchRequest? request,
  }) async {
    _requireAuth();
    
    final response = await _apiService.postWithAuth(
      ApiConstants.matchJoin(matchId),
      authToken: _authToken!,
      body: request?.toJson(),
    );

    return ApiResponse.fromJson(
      response,
      (data) => MatchPlayer.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Leave a match
  Future<ApiResponse<void>> leaveMatch(String matchId) async {
    _requireAuth();
    
    final response = await _apiService.deleteWithAuth(
      ApiConstants.matchLeave(matchId),
      authToken: _authToken!,
    );
    return ApiResponse.fromJson(response, null);
  }

  /// Get join requests for a match (host only)
  /// Optional status filter: PENDING, ACCEPTED, REJECTED, PENDING_PAYMENT
  Future<ApiResponse<List<MatchPlayer>>> getJoinRequests(
    String matchId, {
    MatchPlayerStatus? status,
  }) async {
    _requireAuth();
    
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status.value;

    final response = await _apiService.getWithAuth(
      ApiConstants.matchJoinRequests(matchId),
      authToken: _authToken!,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    return ApiResponse.fromJson(
      response,
      (data) => (data as List)
          .map((item) => MatchPlayer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Respond to a join request (accept/reject)
  Future<ApiResponse<MatchPlayer>> respondToJoinRequest(
    String matchId,
    String playerId,
    RespondToJoinRequest request,
  ) async {
    _requireAuth();
    
    final response = await _apiService.postWithAuth(
      ApiConstants.matchRespondToRequest(matchId, playerId),
      authToken: _authToken!,
      body: request.toJson(),
    );

    return ApiResponse.fromJson(
      response,
      (data) => MatchPlayer.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Create payment for joining a match (ZaloPay)
  /// Returns payment details with QR code for scanning
  Future<ApiResponse<MatchPaymentResponse>> createMatchJoinPayment(
    String matchId,
  ) async {
    _requireAuth();
    
    final response = await _apiService.postWithAuth(
      ApiConstants.matchPayment(matchId),
      authToken: _authToken!,
    );

    return ApiResponse.fromJson(
      response,
      (data) => MatchPaymentResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Query match payment status from ZaloPay
  Future<ApiResponse<PaymentStatusQueryResponse>> queryMatchPaymentStatus(
    String matchId,
    String paymentId,
  ) async {
    _requireAuth();
    
    final response = await _apiService.getWithAuth(
      ApiConstants.matchPaymentStatus(matchId, paymentId),
      authToken: _authToken!,
    );

    return ApiResponse.fromJson(
      response,
      (data) => PaymentStatusQueryResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}

import '../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/match.dart';
import 'api_service.dart';

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
  }) async {
    _requireAuth();
    
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status.value;

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
  Future<ApiResponse<List<MatchWithDetails>>> getJoinedMatches() async {
    _requireAuth();
    
    final response = await _apiService.getWithAuth(
      ApiConstants.matchesJoined,
      authToken: _authToken!,
    );

    return ApiResponse.fromJson(
      response,
      (data) => (data as List)
          .map((item) => MatchWithDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get match by ID
  Future<ApiResponse<MatchWithDetails>> getMatchById(String id) async {
    final response = await _apiService.get(ApiConstants.matchById(id));

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

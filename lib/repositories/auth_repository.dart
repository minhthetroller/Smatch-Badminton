import '../core/constants/api_constants.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Repository for authentication-related API calls
class AuthRepository {
  final ApiService _apiService;

  AuthRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Verify Firebase token and create/get user
  /// Used for Google, Facebook, and Email/Password login
  Future<AuthResponse> verifyToken({
    required String idToken,
    UpdateProfileRequest? profile,
  }) async {
    final body = <String, dynamic>{
      'idToken': idToken,
    };
    if (profile != null) {
      body['profile'] = profile.toJson();
    }

    final response = await _apiService.post(
      ApiConstants.authVerify,
      body: body,
    );
    return AuthResponse.fromJson(response);
  }

  /// Create or get anonymous user session
  Future<AuthResponse> createAnonymous({required String firebaseUid}) async {
    final response = await _apiService.post(
      ApiConstants.authAnonymous,
      body: {'firebaseUid': firebaseUid},
    );
    return AuthResponse.fromJson(response);
  }

  /// Convert anonymous user to registered user
  /// Requires authenticated anonymous user (auth token in header)
  Future<ConvertResponse> convertAnonymous({
    required String authToken,
    String? newFirebaseUid,
    required UserAuthProvider provider,
    String? email,
    String? username,
    UpdateProfileRequest? profile,
  }) async {
    final body = <String, dynamic>{
      'provider': provider.value,
    };
    if (newFirebaseUid != null) body['newFirebaseUid'] = newFirebaseUid;
    if (email != null) body['email'] = email;
    if (username != null) body['username'] = username;
    if (profile != null) body['profile'] = profile.toJson();

    final response = await _apiService.postWithAuth(
      ApiConstants.authConvert,
      authToken: authToken,
      body: body,
    );
    return ConvertResponse.fromJson(response);
  }

  /// Get current user profile
  Future<UserProfile> getProfile({required String authToken}) async {
    final response = await _apiService.getWithAuth(
      ApiConstants.authMe,
      authToken: authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Update user profile
  Future<UserProfile> updateProfile({
    required String authToken,
    required UpdateProfileRequest request,
  }) async {
    final response = await _apiService.putWithAuth(
      ApiConstants.authMe,
      authToken: authToken,
      body: request.toJson(),
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Get user's booking history
  Future<BookingHistoryResponse> getBookingHistory({
    required String authToken,
    int page = 1,
    int limit = 10,
    BookingStatus? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) {
      queryParams['status'] = status.value;
    }

    final response = await _apiService.getWithAuth(
      ApiConstants.authMeBookings,
      authToken: authToken,
      queryParams: queryParams,
    );
    return BookingHistoryResponse.fromJson(response);
  }

  /// Check if username is available
  Future<UsernameAvailabilityResponse> checkUsername(String username) async {
    final response = await _apiService.post(
      ApiConstants.authUsernameCheck,
      body: {'username': username},
    );
    return UsernameAvailabilityResponse.fromJson(response);
  }

  /// Lookup email by username (for username-based login)
  Future<UsernameLookupResponse> lookupUsername(String username) async {
    final response = await _apiService.post(
      ApiConstants.authUsernameLookup,
      body: {'username': username},
    );
    return UsernameLookupResponse.fromJson(response);
  }

  /// Link existing bookings to user account
  Future<LinkBookingsResponse> linkBookings({
    required String authToken,
    String? phoneNumber,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (email != null) body['email'] = email;

    final response = await _apiService.postWithAuth(
      ApiConstants.authLinkBookings,
      authToken: authToken,
      body: body,
    );
    return LinkBookingsResponse.fromJson(response);
  }

  /// Delete user account
  Future<void> deleteAccount({required String authToken}) async {
    await _apiService.deleteWithAuth(
      ApiConstants.authDeleteAccount,
      authToken: authToken,
    );
  }
}


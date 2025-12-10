import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Authentication state
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// ViewModel for managing authentication state
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final AuthRepository _authRepository;

  AuthViewModel({
    AuthService? authService,
    AuthRepository? authRepository,
  })  : _authService = authService ?? AuthService(),
        _authRepository = authRepository ?? AuthRepository();

  // State
  AuthState _state = AuthState.initial;
  UserProfile? _user;
  String? _errorMessage;
  bool _isInitialized = false;
  StreamSubscription<User?>? _authStateSubscription;

  // Getters
  AuthState get state => _state;
  UserProfile? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;
  bool get isLoading => _state == AuthState.loading;

  /// Get current Firebase user
  User? get firebaseUser => _authService.currentUser;

  /// Get current auth token for API calls
  Future<String?> getAuthToken() async {
    return await _authService.getIdToken();
  }

  /// Initialize authentication - call this on app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    _state = AuthState.loading;
    notifyListeners();

    try {
      // Listen to auth state changes
      _authStateSubscription = _authService.authStateChanges.listen(
        _onAuthStateChanged,
        onError: (error) {
          debugPrint('Auth state stream error: $error');
        },
      );

      // Check if user is already signed in
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        try {
          await _syncUserWithBackend(currentUser);
        } catch (e) {
          // If sync fails for any reason, start fresh with anonymous user
          // This handles cases where Firebase user exists locally but was deleted from backend
          debugPrint('Failed to sync existing user, creating new anonymous user: $e');
          try {
            await _authService.signOut();
            await _signInAnonymously();
          } catch (e2) {
            debugPrint('Failed to recover from sync error: $e2');
            _state = AuthState.error;
            _errorMessage = 'Authentication initialization failed';
          }
        }
      } else {
        // No Firebase user - create anonymous user
        await _signInAnonymously();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize auth: $e');
      _state = AuthState.error;
      _errorMessage = e.toString();
      _isInitialized = true;
    }

    notifyListeners();
  }

  /// Handle auth state changes from Firebase
  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
    // Don't auto-sync on every state change - it's handled by specific methods
  }

  /// Sign in anonymously (used on first app launch)
  Future<void> _signInAnonymously() async {
    try {
      final credential = await _authService.signInAnonymously();
      final firebaseUser = credential.user;

      if (firebaseUser != null) {
        // Register anonymous user with backend
        final response = await _authRepository.createAnonymous(
          firebaseUid: firebaseUser.uid,
        );
        _user = response.user;
        _state = AuthState.authenticated;
        
        // Set global auth token for API calls
        final token = await firebaseUser.getIdToken();
        ApiService.setGlobalAuthToken(token);
      }
    } catch (e) {
      debugPrint('Failed to sign in anonymously: $e');
      _state = AuthState.error;
      _errorMessage = e.toString();
    }
  }

  /// Sync Firebase user with backend
  Future<void> _syncUserWithBackend(User firebaseUser) async {
    try {
      final token = await firebaseUser.getIdToken();
      if (token == null) {
        throw Exception('Failed to get ID token');
      }

      if (firebaseUser.isAnonymous) {
        // For anonymous users, use the anonymous endpoint
        final response = await _authRepository.createAnonymous(
          firebaseUid: firebaseUser.uid,
        );
        _user = response.user;
      } else {
        // For authenticated users, verify with backend
        final response = await _authRepository.verifyToken(idToken: token);
        _user = response.user;
      }

      _state = AuthState.authenticated;
      
      // Set global auth token for API calls
      ApiService.setGlobalAuthToken(token);
    } catch (e) {
      // Check for 401 error (user token invalid or user not found in backend)
      // This happens when app data is cleared or backend DB is reset but Firebase user persists
      final is401 = (e is ApiException && e.statusCode == 401) || 
                    e.toString().contains('401'); // Fallback check

      if (is401) {
        debugPrint('User token invalid (401), resetting to anonymous user...');
        // Sign out the invalid cached Firebase user
        await _authService.signOut();
        // Create a fresh anonymous user
        await _signInAnonymously();
        return;
      }

      debugPrint('Failed to sync user with backend: $e');
      
      // Try to get profile if verification fails for other reasons (user might already exist)
      try {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          _user = await _authRepository.getProfile(authToken: token);
          _state = AuthState.authenticated;
          // Set global auth token
          ApiService.setGlobalAuthToken(token);
        }
      } catch (e2) {
        debugPrint('Failed to get profile, creating new anonymous user: $e2');
        // If all else fails, sign out and create fresh anonymous user
        await _authService.signOut();
        await _signInAnonymously();
      }
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Get Google Credential first (triggers UI once)
      final credential = await _authService.getGoogleCredential();
      
      User? firebaseUser;
      final wasAnonymous = _authService.isAnonymous;

      if (wasAnonymous && _authService.currentUser != null) {
        // Try to link first
        try {
          // Get the anonymous token BEFORE linking (required for /api/auth/convert)
          final anonymousToken = await _authService.getIdToken();
          if (anonymousToken == null) {
            throw AuthException('Failed to get anonymous token');
          }

          final userCredential = await _authService.linkWithCredential(credential);
          firebaseUser = userCredential.user;

          if (firebaseUser != null) {
            try {
              // Convert anonymous to registered on backend using the OLD anonymous token
              final response = await _authRepository.convertAnonymous(
                authToken: anonymousToken,
                newFirebaseUid: firebaseUser.uid,
                provider: UserAuthProvider.google,
                email: firebaseUser.email,
              );
              _user = response.user;
              debugPrint('Successfully converted anonymous to Google user');
            } catch (e) {
              debugPrint('Failed to convert anonymous user, falling back to verify: $e');
              // Continue to standard verification
            }
          }
        } catch (e) {
          // Handle credential already in use (account exists)
          final isCredentialInUse = (e is FirebaseAuthException && e.code == 'credential-already-in-use') ||
                                   (e is AuthException && e.code == 'credential-already-in-use');

          if (isCredentialInUse) {
            debugPrint('Credential already in use - switching to existing account');
            // Sign out of anonymous account
            await _authService.signOut();
            // Sign in with the SAME credential (no UI prompt)
            final userCredential = await _authService.signInWithCredential(credential);
            firebaseUser = userCredential.user;
          } else {
            rethrow;
          }
        }
      } else {
        // Regular sign in
        final userCredential = await _authService.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      }

      if (firebaseUser != null) {
        // Force refresh token to clear any cached anonymous data
        await firebaseUser.reload();
        final token = await firebaseUser.getIdToken(true);
        
        if (token != null) {
          try {
            // If we haven't set _user yet (e.g. regular sign in or conversion failed)
            if (_user == null) {
              final response = await _authRepository.verifyToken(idToken: token);
              _user = response.user;
            }
            
            _state = AuthState.authenticated;
            ApiService.setGlobalAuthToken(token);
            notifyListeners();
            return true;
          } catch (e) {
            // If verify fails, try to sync with backend (handles new users)
            debugPrint('Verify token failed, attempting to sync: $e');
            await _syncUserWithBackend(firebaseUser);
            if (_state == AuthState.authenticated) {
              notifyListeners();
              return true;
            }
            rethrow;
          }
        }
      }

      throw AuthException('Failed to sign in with Google');
    } catch (e) {
      debugPrint('Google sign in failed: $e');
      _state = _user != null ? AuthState.authenticated : AuthState.error;
      _errorMessage = e is AuthException ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Get Facebook Credential first (triggers UI once)
      final credential = await _authService.getFacebookCredential();
      
      User? firebaseUser;
      final wasAnonymous = _authService.isAnonymous;

      if (wasAnonymous && _authService.currentUser != null) {
        // Try to link first
        try {
          // Get the anonymous token BEFORE linking
          final anonymousToken = await _authService.getIdToken();
          if (anonymousToken == null) {
            throw AuthException('Failed to get anonymous token');
          }

          final userCredential = await _authService.linkWithCredential(credential);
          firebaseUser = userCredential.user;

          if (firebaseUser != null) {
            try {
              // Convert anonymous to registered on backend using the OLD anonymous token
              final response = await _authRepository.convertAnonymous(
                authToken: anonymousToken,
                newFirebaseUid: firebaseUser.uid,
                provider: UserAuthProvider.facebook,
                email: firebaseUser.email,
              );
              _user = response.user;
              debugPrint('Successfully converted anonymous to Facebook user');
            } catch (e) {
              debugPrint('Failed to convert anonymous user, falling back to verify: $e');
              // Continue to standard verification
            }
          }
        } catch (e) {
          // Handle credential already in use (account exists)
          final isCredentialInUse = (e is FirebaseAuthException && e.code == 'credential-already-in-use') ||
                                   (e is AuthException && e.code == 'credential-already-in-use');

          if (isCredentialInUse) {
            debugPrint('Credential already in use - switching to existing account');
            // Sign out of anonymous account
            await _authService.signOut();
            // Sign in with the SAME credential (no UI prompt)
            final userCredential = await _authService.signInWithCredential(credential);
            firebaseUser = userCredential.user;
          } else {
            rethrow;
          }
        }
      } else {
        // Regular sign in
        final userCredential = await _authService.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      }

      if (firebaseUser != null) {
        // Force refresh token to clear any cached anonymous data
        await firebaseUser.reload();
        final token = await firebaseUser.getIdToken(true);
        
        if (token != null) {
          try {
            // If we haven't set _user yet (e.g. regular sign in or conversion failed)
            if (_user == null) {
              final response = await _authRepository.verifyToken(idToken: token);
              _user = response.user;
            }
            
            _state = AuthState.authenticated;
            ApiService.setGlobalAuthToken(token);
            notifyListeners();
            return true;
          } catch (e) {
            // If verify fails, try to sync with backend (handles new users)
            debugPrint('Verify token failed, attempting to sync: $e');
            await _syncUserWithBackend(firebaseUser);
            if (_state == AuthState.authenticated) {
              notifyListeners();
              return true;
            }
            rethrow;
          }
        }
      }

      throw AuthException('Failed to sign in with Facebook');
    } catch (e) {
      debugPrint('Facebook sign in failed: $e');
      _state = _user != null ? AuthState.authenticated : AuthState.error;
      _errorMessage = e is AuthException ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;

      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          final response = await _authRepository.verifyToken(idToken: token);
          _user = response.user;
          _state = AuthState.authenticated;
          
          // Set global auth token
          ApiService.setGlobalAuthToken(token);
          
          notifyListeners();
          return true;
        }
      }

      throw AuthException('Failed to sign in');
    } catch (e) {
      debugPrint('Email sign in failed: $e');
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
      _errorMessage = e is AuthException ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign in with username and password
  Future<bool> signInWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Lookup email for username
      final lookupResponse = await _authRepository.lookupUsername(username);
      final email = lookupResponse.email;

      // Sign in with the email
      return await signInWithEmailPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Username sign in failed: $e');
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final wasAnonymous = _authService.isAnonymous;

      if (wasAnonymous && _authService.currentUser != null) {
        // Get the anonymous token BEFORE linking
        final anonymousToken = await _authService.getIdToken();
        if (anonymousToken == null) {
          throw AuthException('Failed to get anonymous token');
        }

        // Link email/password to anonymous user
        final credential = await _authService.linkWithEmailPassword(
          email: email,
          password: password,
        );
        final firebaseUser = credential.user;

        if (firebaseUser != null) {
          // Convert anonymous to registered on backend using the OLD anonymous token
          final response = await _authRepository.convertAnonymous(
            authToken: anonymousToken,
            newFirebaseUid: firebaseUser.uid,
            provider: UserAuthProvider.password,
            email: email,
            username: username,
            profile: UpdateProfileRequest(
              firstName: firstName,
              lastName: lastName,
            ),
          );
          _user = response.user;
          _state = AuthState.authenticated;
          
          // Force reload Firebase user to clear anonymous cache
          await firebaseUser.reload();
          // Get fresh token after reload
          final newToken = await firebaseUser.getIdToken(true);
          ApiService.setGlobalAuthToken(newToken);
          
          debugPrint('Successfully converted anonymous to email/password user');
          notifyListeners();
          return true;
        }
      } else {
        // Create new account (non-anonymous user)
        final credential = await _authService.createUserWithEmailPassword(
          email: email,
          password: password,
        );
        final firebaseUser = credential.user;

        if (firebaseUser != null) {
          final token = await firebaseUser.getIdToken();
          if (token != null) {
            final response = await _authRepository.verifyToken(
              idToken: token,
              profile: UpdateProfileRequest(
                username: username,
                firstName: firstName,
                lastName: lastName,
              ),
            );
            _user = response.user;
            _state = AuthState.authenticated;
            
            // Set global auth token
            ApiService.setGlobalAuthToken(token);
            
            notifyListeners();
            return true;
          }
        }
      }

      throw AuthException('Failed to create account');
    } catch (e) {
      debugPrint('Sign up failed: $e');
      _state = _user != null ? AuthState.authenticated : AuthState.error;
      _errorMessage = e is AuthException ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if username is available
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final response = await _authRepository.checkUsername(username);
      return response.available;
    } catch (e) {
      debugPrint('Username check failed: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(UpdateProfileRequest request) async {
    if (!isAuthenticated) return false;

    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await getAuthToken();
      if (token == null) throw AuthException('Not authenticated');

      _user = await _authRepository.updateProfile(
        authToken: token,
        request: request,
      );
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update profile failed: $e');
      _state = AuthState.authenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get booking history
  /// Returns empty response if user has no bookings
  /// Returns null only on actual errors
  Future<BookingHistoryResponse?> getBookingHistory({
    int page = 1,
    int limit = 10,
    BookingStatus? status,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) return null;

      return await _authRepository.getBookingHistory(
        authToken: token,
        page: page,
        limit: limit,
        status: status,
      );
    } catch (e) {
      // Check if it's a 404 (no bookings found)
      final is404 = (e is ApiException && e.statusCode == 404) || 
                    e.toString().contains('404');
      
      if (is404) {
        debugPrint('No bookings found for user');
        // Return empty response instead of null
        return BookingHistoryResponse(
          bookings: [],
          pagination: BookingPagination(
            page: page,
            limit: limit,
            total: 0,
            totalPages: 0,
          ),
        );
      }
      
      debugPrint('Failed to get booking history: $e');
      return null;
    }
  }

  /// Link existing bookings to account
  Future<int> linkExistingBookings({
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) return 0;

      final response = await _authRepository.linkBookings(
        authToken: token,
        phoneNumber: phoneNumber,
        email: email,
      );
      return response.linkedCount;
    } catch (e) {
      debugPrint('Failed to link bookings: $e');
      return 0;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      debugPrint('Password reset failed: $e');
      _errorMessage = e is AuthException ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authService.signOut();
      
      // Clear global auth token
      ApiService.setGlobalAuthToken(null);

      // Create a new anonymous user after sign out
      await _signInAnonymously();
    } catch (e) {
      debugPrint('Sign out failed: $e');
      _state = AuthState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    if (!isAuthenticated || isAnonymous) return false;

    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await getAuthToken();
      if (token != null) {
        // Delete from backend first
        await _authRepository.deleteAccount(authToken: token);
      }

      // Then delete Firebase account
      await _authService.deleteAccount();

      // Create new anonymous user
      await _signInAnonymously();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete account failed: $e');
      _state = AuthState.authenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh user profile from backend
  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;

    try {
      final token = await getAuthToken();
      if (token != null) {
        _user = await _authRepository.getProfile(authToken: token);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}


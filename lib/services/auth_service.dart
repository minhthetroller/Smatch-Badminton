import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';

  /// Create AuthException from FirebaseAuthException
  factory AuthException.fromFirebase(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email';
        break;
      case 'wrong-password':
        message = 'Incorrect password';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email';
        break;
      case 'invalid-email':
        message = 'Invalid email address';
        break;
      case 'weak-password':
        message = 'Password is too weak';
        break;
      case 'user-disabled':
        message = 'This account has been disabled';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later';
        break;
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled';
        break;
      case 'account-exists-with-different-credential':
        message = 'An account already exists with a different sign-in method';
        break;
      case 'invalid-credential':
        message = 'Invalid credentials. Please try again';
        break;
      case 'credential-already-in-use':
        message = 'This credential is already associated with a different account';
        break;
      default:
        message = e.message ?? 'An authentication error occurred';
    }
    return AuthException(message, code: e.code);
  }
}

/// Service for handling Firebase authentication operations
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  /// Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Check if current user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current user's ID token for API authentication
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await currentUser?.getIdToken(forceRefresh);
  }

  /// Get Google credential
  Future<AuthCredential> getGoogleCredential() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to get Google credential: $e');
    }
  }

  /// Get Facebook credential
  Future<AuthCredential> getFacebookCredential() async {
    try {
      final LoginResult loginResult = await _facebookAuth.login();

      if (loginResult.status == LoginStatus.cancelled) {
        throw AuthException('Facebook sign-in was cancelled');
      }

      if (loginResult.status != LoginStatus.success) {
        throw AuthException(
            'Facebook sign-in failed: ${loginResult.message ?? "Unknown error"}');
      }

      return FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to get Facebook credential: $e');
    }
  }

  /// Sign in with credential
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to sign in with credential: $e');
    }
  }

  /// Link with credential
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    try {
      return await currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to link credential: $e');
    }
  }

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _firebaseAuth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to sign in anonymously: $e');
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in with Google: $e');
    }
  }

  /// Sign in with Facebook
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await _facebookAuth.login();

      if (loginResult.status == LoginStatus.cancelled) {
        throw AuthException('Facebook sign-in was cancelled');
      }

      if (loginResult.status != LoginStatus.success) {
        throw AuthException(
            'Facebook sign-in failed: ${loginResult.message ?? "Unknown error"}');
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

      // Sign in to Firebase with the Facebook credential
      return await _firebaseAuth.signInWithCredential(facebookAuthCredential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in with Facebook: $e');
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to sign in: $e');
    }
  }

  /// Create account with email and password
  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to create account: $e');
    }
  }

  /// Link anonymous account with Google
  Future<UserCredential> linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to link with Google: $e');
    }
  }

  /// Link anonymous account with Facebook
  Future<UserCredential> linkWithFacebook() async {
    try {
      final LoginResult loginResult = await _facebookAuth.login();

      if (loginResult.status == LoginStatus.cancelled) {
        throw AuthException('Facebook sign-in was cancelled');
      }

      if (loginResult.status != LoginStatus.success) {
        throw AuthException(
            'Facebook sign-in failed: ${loginResult.message ?? "Unknown error"}');
      }

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

      return await currentUser!.linkWithCredential(facebookAuthCredential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to link with Facebook: $e');
    }
  }

  /// Link anonymous account with email/password
  Future<UserCredential> linkWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      return await currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to link with email/password: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e');
    }
  }

  /// Update user's display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await currentUser?.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to update display name: $e');
    }
  }

  /// Update user's photo URL
  Future<void> updatePhotoUrl(String photoUrl) async {
    try {
      await currentUser?.updatePhotoURL(photoUrl);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to update photo URL: $e');
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Facebook
      await _facebookAuth.logOut();

      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Still try to sign out from Firebase even if social sign out fails
      await _firebaseAuth.signOut();
    }
  }

  /// Delete the current user's account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  /// Re-authenticate user (required before sensitive operations)
  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException('Failed to re-authenticate: $e');
    }
  }
}


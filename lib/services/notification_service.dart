import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import 'api_service.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  // Background messages are handled by the system notification tray
}

/// Service for handling push notifications via FCM
class NotificationService {
  final FirebaseMessaging _messaging;
  final ApiService _apiService;
  
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  
  /// Stream controller for notification events that UI can listen to
  final _notificationController = StreamController<RemoteMessage>.broadcast();
  
  /// Stream of notification messages for UI handling
  Stream<RemoteMessage> get notificationStream => _notificationController.stream;
  
  /// Current FCM token
  String? _currentToken;
  
  /// Callback when notification is tapped
  void Function(RemoteMessage message)? onNotificationTap;

  NotificationService({
    FirebaseMessaging? messaging,
    ApiService? apiService,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _apiService = apiService ?? ApiService();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Request permission for iOS
    await _requestPermission();
    
    // Set up foreground message handling
    _setupForegroundHandler();
    
    // Set up notification opened app handler
    _setupNotificationOpenedHandler();
    
    // Check if app was opened from a notification
    await _checkInitialMessage();
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Set up foreground message handler
  void _setupForegroundHandler() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _notificationController.add(message);
    });
  }

  /// Set up handler for when user taps on notification
  void _setupNotificationOpenedHandler() {
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened app: ${message.notification?.title}');
      onNotificationTap?.call(message);
    });
  }

  /// Check if app was opened from a notification (cold start)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.notification?.title}');
      // Delay to allow app to initialize before handling
      Future.delayed(const Duration(milliseconds: 500), () {
        onNotificationTap?.call(initialMessage);
      });
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      debugPrint('FCM Token: $_currentToken');
      return _currentToken;
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Register FCM token with backend
  Future<bool> registerToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('No FCM token available to register');
        return false;
      }

      await _apiService.post(
        ApiConstants.authFcmToken,
        body: {'token': token},
      );
      
      debugPrint('FCM token registered successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token from backend
  Future<bool> unregisterToken() async {
    try {
      final token = _currentToken ?? await getToken();
      if (token == null) {
        debugPrint('No FCM token available to unregister');
        return false;
      }

      await _apiService.delete(
        ApiConstants.authFcmToken,
        body: {'token': token},
      );
      
      debugPrint('FCM token unregistered successfully');
      _currentToken = null;
      return true;
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
      return false;
    }
  }

  /// Listen to token refresh and re-register
  void listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      _currentToken = newToken;
      // Re-register the new token
      await registerToken();
    });
  }

  /// Dispose of resources
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _notificationController.close();
  }
}

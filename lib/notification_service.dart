import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';

class NotificationService {
  // Singleton pattern implementation
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  void initialize() {
    if (!kIsWeb) {
      // Only initialize OneSignal on mobile platforms
      try {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize("e2715d8a-cf44-4523-8078-dbe2285a792b");
        // Request notification permissions
        OneSignal.Notifications.requestPermission(true);

        // Add this to debug subscription status
        _logSubscriptionStatus();
      } catch (e) {
        print("Error initializing OneSignal: $e");
      }
    }
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault(); // Prevent default notification display
      event.notification.display(); // Manually display the notification
    });
  }

  Future<void> _logSubscriptionStatus() async {
    try {
      final subscription = await OneSignal.User.pushSubscription;
      print("OneSignal subscription status: ${subscription.optedIn}");
      print("OneSignal Player ID: ${subscription.id ?? 'Not available yet'}");
    } catch (e) {
      print("Error checking subscription status: $e");
    }
  }

  Future<void> setExternalUserId(String userId) async {
    if (!kIsWeb) {
      try {
        // For newer versions of OneSignal
        await OneSignal.login(userId);

        // Wait a moment and check if we have a player ID now
        await Future.delayed(Duration(seconds: 2));
        final subscription = await OneSignal.User.pushSubscription;
        if (subscription.id != null) {
          print(
              "Successfully set player ID for user $userId: ${subscription.id}");
          // Also send the player ID to your backend here
          await _sendPlayerIdToBackend(userId, subscription.id!);
        } else {
          print(
              "Warning: Player ID still not available after login for user $userId");
        }
      } catch (e) {
        print("Error setting external user ID: $e");
      }
    }
  }

  Future<void> _sendPlayerIdToBackend(String userId, String playerId) async {
    // Implement the logic to send the player ID to your backend
    // This should mimic the functionality in AuthRemoteDataSourceImpl.sendPlayerIdToBackend
    try {
      final client = http.Client();
      final authDataSource = AuthRemoteDataSourceImpl(client: client);
      authDataSource.sendPlayerIdToBackend(userId);
      client.close();
    } catch (e) {
      print("Error sending player ID to backend: $e");
    }
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/platform_helper.dart';
import '../../utils/permission_handler.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );
  }

  Future<bool> areNotificationsEnabled() async {
    // First check user preference
    final prefs = await SharedPreferences.getInstance();
    final userPreference = prefs.getBool('notifications_enabled');

    // If user has explicitly disabled notifications in the app, return false
    if (userPreference == false) {
      return false;
    }

    // Use permission_handler to check status for Android
    if (!await _isIOS()) {
      return await NotificationPermissionHandler.checkNotificationPermission();
    }

    // For iOS
    return await checkPermissionStatus();
  }

  Future<bool> checkPermissionStatus() async {
    // This is a simplified version. For a complete implementation, you'd need to handle
    // each platform specifically with appropriate plugins.

    // For iOS
    if (await _isIOS()) {
      final iOS = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final settings = await iOS?.getNotificationAppLaunchDetails();
      return settings?.didNotificationLaunchApp ?? false;
    }

    // For Android
    else {
      final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Check if notifications are enabled
      bool areEnabled = false;
      try {
        // This method is available in newer versions of the plugin
        areEnabled = await android?.areNotificationsEnabled() ?? false;
      } catch (e) {
        // Fallback for older versions - assume enabled
        areEnabled = true;
      }
      return areEnabled;
    }
  }

  Future<bool> requestPermissions() async {
    bool permissionGranted = false;

    // For iOS
    if (await _isIOS()) {
      final iOS = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      permissionGranted = await iOS?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    // For Android - use permission_handler
    else {
      permissionGranted = await NotificationPermissionHandler.requestNotificationPermission();
    }

    return permissionGranted;
  }

  Future<void> disableNotifications() async {
    // We can't programmatically revoke permissions, but we can store user preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', false);
  }

  Future<void> enableNotifications() async {
    await requestPermissions();
  }

  // Helper to determine platform
  Future<bool> _isIOS() async {
    return PlatformHelper.isIOS;
  }

  // Example method to show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Check if notifications are enabled before showing
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      return;
    }

    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
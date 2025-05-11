import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionHandler {
  // Request notification permission using permission_handler package
  static Future<bool> requestNotificationPermission() async {
    // For Android 13 (API 33) and above, we need to request the notification permission
    final status = await Permission.notification.request();

    // Store the user preference
    final prefs = await SharedPreferences.getInstance();
    final isGranted = status.isGranted;
    await prefs.setBool('notifications_enabled', isGranted);

    return isGranted;
  }

  // Check if notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    // First check user preference
    final prefs = await SharedPreferences.getInstance();
    final userPreference = prefs.getBool('notifications_enabled');

    // If user has explicitly disabled notifications in the app, return false
    if (userPreference == false) {
      return false;
    }

    // Check current permission status
    final permissionStatus = await Permission.notification.status;
    return permissionStatus.isGranted;
  }

  // Show dialog to explain why we need notification permission
  static Future<bool> showNotificationPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission'),
        content: const Text(
            'We need your permission to send you notifications. '
                'Would you like to enable notifications?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('DENY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ALLOW'),
          ),
        ],
      ),
    );

    // If user agrees, request permission
    if (result == true) {
      return await requestNotificationPermission();
    }

    // If user denies in our dialog, store this preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', false);

    return false;
  }
}
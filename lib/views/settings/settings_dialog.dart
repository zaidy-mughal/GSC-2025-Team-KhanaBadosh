import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/notification_service.dart';
import '../../utils/permission_handler.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onClose;
  final Function(int) onNavigateToSettings;

  const SettingsDialog({
    super.key,
    required this.onClose,
    required this.onNavigateToSettings,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _appVersion = '';
  bool _notificationsEnabled = true; // State variable for notifications
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _loadNotificationPreference();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
        });
      }
    } catch (e) {
      // Only set fallback if we don't already have a version
      if (mounted) {
        setState(() {
          _appVersion = 'Unable to get version';
        });
      }
    }
  }

  Future<void> _loadNotificationPreference() async {
    if (mounted) {
      final enabled = await _notificationService.areNotificationsEnabled();
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleNotifications() async {
    final newState = !_notificationsEnabled;

    if (newState) {
      // For Android, show a dialog explaining why we need permission first
      if (Theme.of(context).platform == TargetPlatform.android) {
        await NotificationPermissionHandler.showNotificationPermissionDialog(context);
      } else {
        // For iOS, just enable notifications directly
        await _notificationService.enableNotifications();
      }
    } else {
      // Disable notifications
      await _notificationService.disableNotifications();
    }

    // Update UI with current state
    if (mounted) {
      final enabled = await _notificationService.areNotificationsEnabled();
      setState(() {
        _notificationsEnabled = enabled;
      });
    }

    // Example: Show a test notification if enabled
    if (_notificationsEnabled) {
      // Show a test notification to confirm it's working
      // Comment this out in production code
      await _showTestNotification();
    }
  }

  Future<void> _showTestNotification() async {
    await _notificationService.showNotification(
      id: 0,
      title: 'Notifications Enabled',
      body: 'You will now receive notifications from the app.',
    );
  }

  // Safe navigation helper - ensures we don't mess up the navigation stack
  void _safeNavigate(int pageIndex) {
    // First close dialog
    widget.onNavigateToSettings(pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 12),

            // Settings options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Theme toggle with sun/moon icon
                  _buildSettingItem(
                    context,
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    colors: colors,
                    trailing: Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: colors.primary,
                      inactiveThumbColor: colors.primary.withOpacity(0.5),
                      thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                            (Set<WidgetState> states) {
                          return Icon(
                            themeProvider.themeMode == ThemeMode.light
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 16.0,
                            color: states.contains(WidgetState.selected)
                                ? colors.onPrimary
                                : colors.onPrimary.withOpacity(0.5),
                          );
                        },
                      ),
                    ),
                  ),

                  // Notifications with bell/crossed bell icon
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    colors: colors,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        _toggleNotifications();
                      },
                      activeColor: colors.primary,
                      inactiveThumbColor: colors.primary.withOpacity(0.5),
                      thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                            (Set<WidgetState> states) {
                          return Icon(
                            _notificationsEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            size: 16.0,
                            color: states.contains(WidgetState.selected)
                                ? colors.onPrimary
                                : colors.onPrimary.withOpacity(0.5),
                          );
                        },
                      ),
                    ),
                  ),

                  // Feedback
                  _buildSettingItem(
                    context,
                    icon: Icons.feedback,
                    title: 'Feedback',
                    colors: colors,
                    onTap: () {
                      widget.onClose();
                      // Navigate to feedback screen or show feedback dialog
                    },
                  ),

                  // Privacy Policy
                  _buildSettingItem(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    colors: colors,
                    onTap: () {
                      widget.onClose();
                      // Navigate to privacy policy screen
                    },
                  ),

                  // Terms & Conditions
                  _buildSettingItem(
                    context,
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    colors: colors,
                    onTap: () {
                      widget.onClose();
                      // Navigate to terms screen
                    },
                  ),

                  // Settings
                  _buildSettingItem(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    colors: colors,
                    onTap: () {
                      // Use our safe navigation helper
                      _safeNavigate(5); // Index 5 for settings
                    },
                  ),

                  // Support
                  _buildSettingItem(
                    context,
                    icon: Icons.support,
                    title: 'Support',
                    colors: colors,
                    onTap: () {
                      widget.onClose();
                      // Navigate to support screen
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App version at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _appVersion.isNotEmpty ? 'App Version $_appVersion' : 'Loading version...',
                style: TextStyle(
                  color: colors.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required ColorScheme colors,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16.0),
            Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
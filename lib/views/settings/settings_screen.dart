import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/theme_provider.dart';
import '../auth/login_screen.dart';

// Add the ColorBrightness extension from dashboard
extension ColorBrightness on Color {
  Color brighten(int amount) {
    return Color.fromARGB(
      alpha,
      (red + amount).clamp(0, 255),
      (green + amount).clamp(0, 255),
      (blue + amount).clamp(0, 255),
    );
  }

  Color darken(int amount) {
    return Color.fromARGB(
      alpha,
      (red - amount).clamp(0, 255),
      (green - amount).clamp(0, 255),
      (blue - amount).clamp(0, 255),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    // Add debug print to trace initialization
    debugPrint('SettingsScreen initialized');
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
          debugPrint('App version set to: $_appVersion');
        });
      }
    } catch (e) {
      debugPrint('Error getting package info: $e');
      if (mounted) {
        setState(() {
          _appVersion = '3.1.5'; // Fallback to match the image
        });
      }
    }
  }

  // Add new method to clear cache data
  Future<void> _clearAppCache() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear application directory cache
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.listSync().forEach((entity) {
          if (entity is File) {
            entity.deleteSync();
          } else if (entity is Directory) {
            entity.deleteSync(recursive: true);
          }
        });
      }

      // Clear application documents directory if needed
      // Only use this if you're storing user-specific data here
      /*
      final appDocDir = await getApplicationDocumentsDirectory();
      // Be careful with this - you might want to only delete specific files
      // Consider keeping app settings or other non-user data
      */

      debugPrint('App cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  void _signOut() async {
    try {
      // First clear the cache
      await _clearAppCache();

      // Then sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // You might want to show an error message to the user here
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shadowColor: colorScheme.shadow.withOpacity(0.7),
      // Make sure we're calculating colors correctly in dark mode
      color: Theme.of(context).brightness == Brightness.light
          ? colorScheme.surface.brighten(10)
          : colorScheme.surface.brighten(15),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Add debug print to track rendering
    debugPrint('Building SettingsScreen with brightness: ${Theme.of(context).brightness}');

    // Check if we're in a valid context
    if (!mounted) {
      debugPrint('SettingsScreen not mounted');
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                // Theme Mode
                _buildSettingItem(
                  icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  title: 'Theme Mode',
                  iconColor: colorScheme.primary,
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: colorScheme.primary,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.2)),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                // About Us
                _buildSettingItem(
                  icon: Icons.info,
                  title: 'About Us',
                  iconColor: Colors.blue,
                  onTap: () {
                    // Navigate to about screen
                    debugPrint('About Us tapped');
                  },
                ),

                // Terms & Conditions
                _buildSettingItem(
                  icon: Icons.description,
                  title: 'Terms & Conditions',
                  iconColor: Colors.orange,
                  onTap: () {
                    // Navigate to terms screen
                    debugPrint('Terms tapped');
                  },
                ),

                // Privacy Policy
                _buildSettingItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  iconColor: Colors.green,
                  onTap: () {
                    // Navigate to privacy policy screen
                    debugPrint('Privacy Policy tapped');
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.2)),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                // Logout from this Device
                _buildSettingItem(
                  icon: Icons.logout,
                  title: 'Logout from this Device',
                  iconColor: Colors.red,
                  onTap: () {
                    debugPrint('Logout from this device tapped');
                    _signOut();
                  },
                ),

                const SizedBox(height: 20),

                // App Version at bottom
                Center(
                  child: Text(
                    'App Version $_appVersion',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
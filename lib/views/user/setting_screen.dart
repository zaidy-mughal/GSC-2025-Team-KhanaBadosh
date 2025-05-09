import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/theme_toggle.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  bool isLoading = false;

  void _signOut() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // App Theme Section
          _buildSectionHeader(context, 'Appearance'),
          // _buildThemeSelector(context, themeProvider),

          const SizedBox(height: 16),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildAccountTile(context),

          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          _buildNotificationTiles(context),

          const SizedBox(height: 16),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildAboutTiles(context),

          const SizedBox(height: 24),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.errorContainer,
                foregroundColor: colors.onErrorContainer,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }

  // Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
  //   final colors = Theme.of(context).colorScheme;
  //
  //   return Card(
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  //     elevation: 0,
  //     color: colors.surface,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //       side: BorderSide(color: colors.outline.withOpacity(0.2)),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(4.0),
  //       child: Column(
  //         children: [
  //           RadioListTile<ThemeMode>(
  //             title: Row(
  //               children: [
  //                 Icon(Icons.light_mode, color: colors.primary),
  //                 const SizedBox(width: 12),
  //                 const Text('Light Mode'),
  //               ],
  //             ),
  //             value: ThemeMode.light,
  //             groupValue: themeProvider.themeMode,
  //             onChanged: (ThemeMode? value) {
  //               if (value != null) {
  //                 themeProvider.setThemeMode(value);
  //               }
  //             },
  //             activeColor: colors.primary,
  //           ),
  //           RadioListTile<ThemeMode>(
  //             title: Row(
  //               children: [
  //                 Icon(Icons.dark_mode, color: colors.primary),
  //                 const SizedBox(width: 12),
  //                 const Text('Dark Mode'),
  //               ],
  //             ),
  //             value: ThemeMode.dark,
  //             groupValue: themeProvider.themeMode,
  //             onChanged: (ThemeMode? value) {
  //               if (value != null) {
  //                 themeProvider.setThemeMode(value);
  //               }
  //             },
  //             activeColor: colors.primary,
  //           ),
  //           RadioListTile<ThemeMode>(
  //             title: Row(
  //               children: [
  //                 Icon(Icons.phone_android, color: colors.primary),
  //                 const SizedBox(width: 12),
  //                 const Text('System Default'),
  //               ],
  //             ),
  //             value: ThemeMode.system,
  //             groupValue: themeProvider.themeMode,
  //             onChanged: (ThemeMode? value) {
  //               if (value != null) {
  //                 themeProvider.setThemeMode(value);
  //               }
  //             },
  //             activeColor: colors.primary,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildAccountTile(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(Icons.person, color: colors.primary),
        title: const Text('Edit Profile'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurfaceVariant),
        onTap: () {
          Navigator.pushNamed(context, '/edit-profile');
        },
      ),
    );
  }

  Widget _buildNotificationTiles(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.notifications_active, color: colors.primary),
            title: const Text('Push Notifications'),
            value: true, // This would come from a provider or preference service
            onChanged: (bool value) {
              // Implementation would update preferences
            },
            activeColor: colors.primary,
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.email, color: colors.primary),
            title: const Text('Email Notifications'),
            value: false, // This would come from a provider or preference service
            onChanged: (bool value) {
              // Implementation would update preferences
            },
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTiles(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info, color: colors.primary),
            title: const Text('App Version'),
            trailing: const Text('1.0.0', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          ListTile(
            leading: Icon(Icons.policy, color: colors.primary),
            title: const Text('Privacy Policy'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurfaceVariant),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          ListTile(
            leading: Icon(Icons.description, color: colors.primary),
            title: const Text('Terms of Service'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurfaceVariant),
            onTap: () {
              // Navigate to terms of service
            },
          ),
        ],
      ),
    );
  }
}
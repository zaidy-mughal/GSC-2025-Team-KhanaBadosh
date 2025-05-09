import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailScreen({
    super.key,
    required this.userData,
  });

  Widget infoRow(String label, String? value, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not set',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.onSurface.withOpacity(0.2)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          userData['display_name'] ?? 'User Details',
          style: TextStyle(color: colors.onPrimary),
        ),
        backgroundColor: colors.primary,
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with image
            Container(
              width: double.infinity,
              color: colors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Hero(
                    tag: 'user-avatar-${userData['user_id']}',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: colors.primary.withOpacity(0.3),
                      backgroundImage: userData['profile_image_url'] != null &&
                          userData['profile_image_url'].isNotEmpty
                          ? NetworkImage(userData['profile_image_url'])
                          : null,
                      child: userData['profile_image_url'] == null ||
                          userData['profile_image_url'].isEmpty
                          ? Icon(
                        Icons.person,
                        size: 60,
                        color: colors.primary,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData['display_name'] ?? 'No Display Name',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // User information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      infoRow("Name", userData['name'], colors),
                      infoRow("Age", userData['age']?.toString(), colors),
                      infoRow("Gender", userData['gender'], colors),
                      infoRow("Address", userData['address'], colors),
                      infoRow("City", userData['city'], colors),
                      infoRow("Region", userData['region'], colors),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
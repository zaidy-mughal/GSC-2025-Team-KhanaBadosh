import '../auth/complete_profile_screen.dart';
import 'package:flutter/material.dart';
import 'edit_user_details_screen.dart';

class UserDetailScreen extends StatefulWidget { // Changed to StatefulWidget
  final Map<String, dynamic> userData;

  const UserDetailScreen({
    super.key,
    required this.userData,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
  }

  Widget infoRow(String label, String? value, ColorScheme colors, {bool multiLine = false}) {
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
            maxLines: multiLine ? 5 : 1,
            overflow: multiLine ? TextOverflow.ellipsis : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.onSurface.withOpacity(0.2)),
        ],
      ),
    );
  }

  String _formatAddress() {
    final address = _userData['address'];
    final city = _userData['city'];
    final region = _userData['region'];

    if (address == null && city == null && region == null) {
      return 'Not set';
    }

    List<String> addressParts = [];

    if (address != null && address.isNotEmpty) {
      addressParts.add(address);
    }

    if (city != null && city.isNotEmpty) {
      addressParts.add(city);
    }

    if (region != null && region.isNotEmpty) {
      addressParts.add(region);
    }

    return addressParts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary.withOpacity(0.1),
        iconTheme: IconThemeData(color: colors.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: colors.primary),
            onPressed: () async {
              // Navigate to edit screen and await result
              final updatedData = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserDetailsScreen(userData: _userData),
                ),
              );

              // Update the UI if data was changed
              if (updatedData != null) {
                setState(() {
                  // Merge the updated data with existing data
                  _userData = {
                    ..._userData,
                    ...updatedData,
                  };
                });
              }
            },
          ),
        ],
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
                    tag: 'user-avatar-${_userData['user_id']}',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: colors.primary.withOpacity(0.3),
                      backgroundImage: _userData['profile_image_url'] != null &&
                          _userData['profile_image_url'].isNotEmpty
                          ? NetworkImage(_userData['profile_image_url']) as ImageProvider<Object>
                          : null,
                      child: _userData['profile_image_url'] == null ||
                          _userData['profile_image_url'].isEmpty
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
                    _userData['display_name'] ?? 'No Display Name',
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
                color: colors.surface.brighten(10),
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
                      infoRow("Name", _userData['name']?.toString(), colors),
                      infoRow("Email", _userData['email']?.toString(), colors),
                      infoRow("Phone Number", _userData['number']?.toString(), colors),
                      infoRow("Age", _userData['age']?.toString(), colors),
                      infoRow("Gender", _userData['gender']?.toString(), colors),
                      infoRow("Address", _formatAddress(), colors, multiLine: true),
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
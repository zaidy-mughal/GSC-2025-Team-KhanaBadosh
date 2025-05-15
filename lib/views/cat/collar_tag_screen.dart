import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Add the color brightness extension just like in cat_dashboard.dart
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

class CollarTagScreen extends StatefulWidget {
  final Map<String, dynamic> cat;
  final Future<void> Function() onRefresh;

  const CollarTagScreen({
    super.key,
    required this.cat,
    required this.onRefresh,
  });

  @override
  State<CollarTagScreen> createState() => _CollarTagScreenState();
}

class _CollarTagScreenState extends State<CollarTagScreen> {
  bool _hasQrTag = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Check if the cat already has a QR tag
    _checkExistingTag();
  }

  void _checkExistingTag() {
    // Check if the cat already has a QR tag
    setState(() {
      _hasQrTag = widget.cat['has_qr_tag'] ?? false;
    });
  }

  // Updated method to fetch address from Supabase profiles table using user_id
  Future<Map<String, String>> _getUserAddress() async {
    try {
      // Get user_id from the cat object - handle both String and int types
      final userId = widget.cat['user_id'];

      // Debug the user ID to understand its type and value
      debugPrint('User ID type: ${userId.runtimeType}, value: $userId');

      // Query the profiles table in Supabase for the user with matching user_id
      final response = await _supabase
          .from('profiles')
          .select('address, city, region')
          .eq('user_id', userId)  // Supabase will handle the type conversion
          .single();

      // Extract the address information from the response
      return {
        'address': response['address'] ?? 'No address available',
        'city': response['city'] ?? 'No city available',
        'region': response['region'] ?? 'No region available'
      };
    } catch (error) {
      // Handle any errors (e.g., user not found, network issues)
      debugPrint('Error fetching user address: $error');
      // Return default values if there's an error
      return {
        'address': 'Address not found',
        'city': 'City not found',
        'region': 'Region not found'
      };
    }
  }

  Future<void> _updateCatQrTagStatus(bool tagStatus) async {
    try {
      // Update the cat's has_qr_tag field in Supabase
      await _supabase
          .from('cats')
          .update({'has_qr_tag': tagStatus})
          .eq('id', widget.cat['id']);

      // Update local state
      setState(() {
        _hasQrTag = tagStatus;
      });

      // Call the parent's refresh function to update the cat data everywhere
      await widget.onRefresh();

      debugPrint('Successfully updated cat QR tag status to $tagStatus');
    } catch (error) {
      debugPrint('Error updating cat QR tag status: $error');
      // Show error dialog if update fails
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Error'),
            content: const Text('Failed to update your cat\'s QR tag status. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _deleteQrTag() async {
    // Show confirmation dialog
    final bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
            'Are you sure you want to delete this QR tag? This will mark your tag as inactive. You will need to purchase a new tag if your cat needs one.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    // If user didn't confirm, exit the method
    if (!confirmed) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Simulate process
    Timer(const Duration(seconds: 1), () {
      Navigator.pop(context); // Close loading dialog

      // Update cat's has_qr_tag to false in Supabase
      _updateCatQrTagStatus(false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR tag has been deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _showFeaturesDialog() {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'QR Tag Features',
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureDialogItem(
                icon: Icons.person,
                title: 'Quick Contact Info',
                description: 'Anyone who finds your cat can scan the QR code with our app to access your contact information.',
              ),
              const Divider(),
              _buildFeatureDialogItem(
                icon: Icons.qr_code_scanner,
                title: 'In-App Scanner',
                description: 'Works exclusively with our app\'s built-in QR scanner for enhanced security.',
              ),
              const Divider(),
              _buildFeatureDialogItem(
                icon: Icons.water_drop,
                title: 'Waterproof',
                description: 'Durable and waterproof design perfect for active cats.',
              ),
              const Divider(),
              _buildFeatureDialogItem(
                icon: Icons.security,
                title: 'Privacy Protection',
                description: 'Your personal information is only shared with the finder when they scan the code.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDialogItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _purchaseTag() async {
    // Get address from user profile using Supabase
    final Map<String, String> profileAddress = await _getUserAddress();

    // Format the full address
    final String address = profileAddress['address'] ?? 'No address available';
    final String city = profileAddress['city'] ?? 'No city available';
    final String region = profileAddress['region'] ?? 'No region available';
    final String fullAddress = '$address, $city, $region';

    // First show confirmation dialog WITH address
    final bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Purchase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to purchase a QR tag for your cat? This will be a one-time charge of PKR 4,149.72.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Delivery Address:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(fullAddress),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ) ?? false;

    // If user didn't confirm, exit the method
    if (!confirmed) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Simulate purchase process
    Timer(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog

      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Purchase Successful!'),
            content: const Text(
              'Your QR Tag has been ordered and will arrive within 3-5 business days.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Update cat's has_qr_tag to true in Supabase
                  _updateCatQrTagStatus(true);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  // New method to build QR Code section when has_qr_tag is true
  Widget _buildQrCodeSection() {
    final colors = Theme.of(context).colorScheme;

    // Create payload with only selected cat information
    final Map<String, dynamic> qrPayload = {
      'id': widget.cat['id'],
      'user_id': widget.cat['user_id'],
      'note': 'To view this cat and its owner details please download our app Paw Protect'
    };

    // Convert payload to JSON string
    final String qrData = qrPayload.toString();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Code card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colors.primary.withOpacity(0.5),
                width: 1,
              ),
            ),
            // Apply the brightening effect like in cat_dashboard
            color: colors.surface.brighten(10),
            child: Column(
              children: [
                // QR code image
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surface.brighten(15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your Cat\'s QR Code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // QR Code details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This QR code contains your cat\'s ID and your user ID. When scanned with the Paw Protect app, it allows finders to contact you if your cat is lost.',
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info about scanning
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Apply the brightening effect
            color: colors.surface.brighten(5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'When someone scans this QR code with the Paw Protect app, they\'ll be able to see your contact information and send you a notification that your cat has been found.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Manage button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Open tag management dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Manage QR Tag'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Features'),
                          onTap: () {
                            Navigator.pop(context);
                            // Show features dialog
                            _showFeaturesDialog();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.red),
                          title: const Text(
                            'Delete QR Code',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteQrTag();
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surface.brighten(12),
                foregroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colors.primary,
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                'Manage Tag',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Add space at the bottom
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildTagManagementSection() {
    final colors = Theme.of(context).colorScheme;
    const double tagPrice = 4149.72;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag preview card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colors.primary.withOpacity(0.5),
                width: 1,
              ),
            ),
            // Apply the brightening effect like in cat_dashboard
            color: colors.surface.brighten(10),
            child: Column(
              children: [
                // Tag image
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 80,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'QR Tag',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tag details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'When scanned within our app, this QR code links to your cat\'s profile with your contact information.',
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _hasQrTag
                          ? const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Text(
                            'PKR ${tagPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'One-time purchase',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Features section
          Text(
            'Features:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.person,
            title: 'Quick Contact Info',
            description: 'Anyone who finds your cat can scan the QR code with our app to access your contact information.',
          ),
          _buildFeatureItem(
            icon: Icons.qr_code_scanner,
            title: 'In-App Scanner',
            description: 'Works exclusively with our app\'s built-in QR scanner for enhanced security.',
          ),
          _buildFeatureItem(
            icon: Icons.water_drop,
            title: 'Waterproof',
            description: 'Durable and waterproof design perfect for active cats.',
          ),

          const SizedBox(height: 32),

          // Buy button or manage button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _hasQrTag
                  ? () {
                // Open tag management dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Manage QR Tag'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Contact Information'),
                          onTap: () {
                            Navigator.pop(context);
                            // Add navigation to edit contact info
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Features'),
                          onTap: () {
                            Navigator.pop(context);
                            // Show features dialog
                            _showFeaturesDialog();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.red),
                          title: const Text(
                            'Delete QR Code',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteQrTag();
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
                  : _purchaseTag,
              style: ElevatedButton.styleFrom(
                // Apply brightening effect to button background
                backgroundColor: _hasQrTag ? colors.surface.brighten(12) : colors.primary,
                foregroundColor: _hasQrTag ? colors.primary : colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colors.primary,
                    width: _hasQrTag ? 1 : 0,
                  ),
                ),
              ),
              child: Text(
                _hasQrTag ? 'Manage Tag' : 'Buy Now - PKR ${tagPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Add space at the bottom
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      // Apply brightening effect to feature cards
      color: colors.surface.brighten(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: _hasQrTag ? _buildQrCodeSection() : _buildTagManagementSection(),
    );
  }
}
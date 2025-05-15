import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// Extension to adjust color brightness
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

class ViewQRFoundScreen extends StatefulWidget {
  final int catId;
  final String userId;

  const ViewQRFoundScreen({
    super.key,
    required this.catId,
    required this.userId,
  });

  @override
  State<ViewQRFoundScreen> createState() => _ViewQRFoundScreenState();
}

class _ViewQRFoundScreenState extends State<ViewQRFoundScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _catData;
  Map<String, dynamic>? _ownerData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch cat data
      final catResponse = await _supabase
          .from('cats')
          .select('*')
          .eq('id', widget.catId)
          .single();

      _catData = catResponse;

      // If cat exists, fetch owner profile
      if (_catData != null) {
        final ownerResponse = await _supabase
            .from('profiles')
            .select('user_id, name, display_name, address, city, region, profile_image_url, email, number')
            .eq('user_id', widget.userId)
            .single();

        _ownerData = ownerResponse;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load pet information: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Helper method to format the pet's status message and color
  Map<String, dynamic> _getPetStatusInfo() {
    if (_catData == null) {
      return {
        'text': 'UNKNOWN',
        'color': Colors.grey,
        'icon': Icons.help_outline,
      };
    }

    // Check if pet is reported lost
    if (_catData!['status'] != null && _catData!['status'] == true) {
      return {
        'text': 'LOST',
        'color': Colors.red,
        'icon': Icons.error_outline,
      };
    } else {
      return {
        'text': 'REGISTERED',
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      };
    }
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

  // Method to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Ensure the phone number is properly formatted
    String formattedNumber = phoneNumber.trim();

    if (phoneNumber.length == 10 && phoneNumber[0] != '0') {
      phoneNumber = '0$phoneNumber';
      formattedNumber = phoneNumber.trim();
    }

    // Create the Uri for launching the phone app
    final Uri phoneUri = Uri(scheme: 'tel', path: formattedNumber);

    try {
      // Launch URL with forceSafariVC: false and universalLinksOnly: false
      // to ensure it opens in the phone app
      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call: $formattedNumber')),
        );
      }
    }
  }

  // Convert numeric phone number to string
  String? _getPhoneNumberAsString() {
    if (_ownerData?['number'] == null) return null;
    return _ownerData!['number'].toString();
  }

  // Get formatted address
  String? _getFormattedAddress() {
    if (_ownerData == null) return null;

    final List<String> addressParts = [];

    if (_ownerData!['address'] != null && _ownerData!['address'].toString().isNotEmpty) {
      addressParts.add(_ownerData!['address'].toString());
    }

    if (_ownerData!['city'] != null && _ownerData!['city'].toString().isNotEmpty) {
      addressParts.add(_ownerData!['city'].toString());
    }

    if (_ownerData!['region'] != null && _ownerData!['region'].toString().isNotEmpty) {
      addressParts.add(_ownerData!['region'].toString());
    }

    return addressParts.isEmpty ? null : addressParts.join(', ');
  }

  // Format reported lost date
  String _formatLostDate() {
    if (_catData?['reported_lost_at'] == null) return 'Unknown';

    final lostDate = DateTime.parse(_catData!['reported_lost_at']);
    final now = DateTime.now();
    final difference = now.difference(lostDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusInfo = _getPetStatusInfo();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary.withOpacity(0.1),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading pet information...',
                style: TextStyle(color: colors.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: colors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              // Pet profile header with image
              Container(
                width: double.infinity,
                color: colors.primary.withOpacity(0.1),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Pet image with fallback icon
                    Hero(
                      tag: 'cat_${widget.catId}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: _catData?['image_url'] != null && _catData!['image_url'].isNotEmpty
                            ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _catData!['image_url'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(color: colors.primary),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.pets,
                              size: 60,
                              color: colors.primary,
                            ),
                          ),
                        )
                            : Icon(
                          Icons.pets,
                          size: 60,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusInfo['color'],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusInfo['icon'], color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            statusInfo['text'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pet name
                    Text(
                      _catData?['name'] ?? 'Unknown Pet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),

                    // Show missing timeframe if pet is lost
                    if (_catData?['status'] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, size: 18, color: colors.error),
                            const SizedBox(width: 6),
                            Text(
                              'Missing since ${_formatLostDate()}',
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Contact options if pet is lost
              if (_catData?['status'] == true)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Have you found this pet?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Call owner button with direct phone call
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Get phone number as string
                                final String? phoneNumber = _getPhoneNumberAsString();
                                if (phoneNumber != null && phoneNumber.isNotEmpty) {
                                  // Make the call directly
                                  _makePhoneCall(phoneNumber);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Phone number not available')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call Owner'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Pet details card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  color: Theme.of(context).brightness == Brightness.light
                      ? colors.surface.brighten(10)
                      : colors.surface.brighten(15),
                  shadowColor: colors.shadow.withOpacity(0.7),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pet Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        infoRow('Name', _catData?['name'], colors),
                        infoRow('Breed', _catData?['breed'], colors),
                        infoRow(
                            'Age',
                            _catData?['age'] != null
                                ? '${_catData!['age']} ${int.parse(_catData!['age'].toString()) == 1 ? 'year' : 'years'} old'
                                : null,
                            colors
                        ),
                        infoRow('Gender', _catData?['gender'], colors),
                        infoRow('Color', _catData?['color'], colors),

                        // Show last seen location only if pet is lost
                        if (_catData?['status'] == true && _catData?['last_seen_loc'] != null)
                          infoRow('Last Seen', _catData!['last_seen_loc'], colors, multiLine: true),

                        if (_catData?['description'] != null && _catData!['description'].toString().isNotEmpty)
                          infoRow('Description', _catData!['description'], colors, multiLine: true),
                      ],
                    ),
                  ),
                ),
              ),

              // Owner information card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  color: Theme.of(context).brightness == Brightness.light
                      ? colors.surface.brighten(10)
                      : colors.surface.brighten(15),
                  shadowColor: colors.shadow.withOpacity(0.7),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_ownerData != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Owner image and name row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: colors.primary.withOpacity(0.3),
                                    backgroundImage: _ownerData?['profile_image_url'] != null && _ownerData?['profile_image_url'].isNotEmpty
                                        ? NetworkImage(_ownerData!['profile_image_url'])
                                        : null,
                                    child: _ownerData?['profile_image_url'] == null || _ownerData?['profile_image_url'].isEmpty
                                        ? Icon(Icons.person, size: 40, color: colors.primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _ownerData?['display_name'] ?? 'Unknown',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: colors.onSurface,
                                          ),
                                        ),
                                        if (_ownerData?['name'] != null && _ownerData?['name'] != _ownerData?['display_name'])
                                          Text(
                                            '@${_ownerData!['name']}',
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
                              const SizedBox(height: 16),

                              // Owner details - only show contact info if pet is lost
                              if (_catData?['status'] == true) ...[
                                infoRow('Email', _ownerData?['email'], colors),
                                infoRow('Phone', _getPhoneNumberAsString(), colors),
                                infoRow('Address', _getFormattedAddress(), colors, multiLine: true),
                              ] else ...[
                                // If pet is not lost, show limited info
                                Text(
                                  'This pet is registered and has not been reported lost.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colors.primary,
                                  ),
                                ),
                              ]
                            ],
                          )
                        else
                          Center(
                            child: Text(
                              'No owner information available',
                              style: TextStyle(color: colors.onSurface.withOpacity(0.7)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Safety notice
              if (_catData?['status'] == true)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _catData?['status'] == true
                                ? 'If you found this pet, please contact the owner directly. Ensure your own safety when arranging a meet-up.'
                                : '',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
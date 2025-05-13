import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';  // For phone call functionality

class LostCatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cat;

  const LostCatDetailScreen({
    super.key,
    required this.cat,
  });

  @override
  State<LostCatDetailScreen> createState() => _LostCatDetailScreenState();
}

class _LostCatDetailScreenState extends State<LostCatDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _ownerData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOwnerData();
  }

  Future<void> _fetchOwnerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch the owner data using the user_id from the cat
      final String? userId = widget.cat['user_id'];

      if (userId == null) {
        throw Exception('Cat has no associated user ID');
      }

      final response = await _supabase
          .from('profiles')
          .select('user_id, name, display_name, address, city, region, profile_image_url, email, number')
          .eq('user_id', userId)
          .single();

      setState(() {
        _ownerData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load owner information: ${e.toString()}';
        _isLoading = false;
      });
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

  // Improved method to make phone call
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

  String _formatLostDate() {
    if (widget.cat['reported_lost_at'] == null) return 'Unknown';

    final lostDate = DateTime.parse(widget.cat['reported_lost_at']);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary.withOpacity(0.1),
        iconTheme: IconThemeData(color: colors.primary),
        // Share button removed as requested
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cat profile header with image
            Container(
              width: double.infinity,
              color: colors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Cat image with fallback icon
                  Hero(
                    tag: 'lost_cat_${widget.cat['id']}',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: widget.cat['image_url'] != null && widget.cat['image_url'].isNotEmpty
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.cat['image_url'],
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
                      color: colors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'LOST',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cat name
                  Text(
                    widget.cat['name'] ?? 'Unknown Cat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),

                  // Missing timeframe
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

            // Contact options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have you seen this cat?',
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

            // Cat details card
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
                        'Cat Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      infoRow('Name', widget.cat['name'], colors),
                      infoRow('Breed', widget.cat['breed'], colors),
                      infoRow(
                          'Age',
                          widget.cat['age'] != null
                              ? '${widget.cat['age']} ${int.parse(widget.cat['age'].toString()) == 1 ? 'year' : 'years'} old'
                              : null,
                          colors
                      ),
                      infoRow('Gender', widget.cat['gender'], colors),
                      infoRow('Color', widget.cat['color'], colors),
                      infoRow('Last Seen', widget.cat['last_seen_location'], colors, multiLine: true),
                      if (widget.cat['description'] != null && widget.cat['description'].toString().isNotEmpty)
                        infoRow('Description', widget.cat['description'], colors, multiLine: true),
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
                color: colors.surface,
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

                      // Show loading indicator while fetching owner data
                      if (_isLoading)
                        Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: colors.primary),
                              const SizedBox(height: 12),
                              Text(
                                'Loading owner information...',
                                style: TextStyle(color: colors.onSurface.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        )
                      else if (_errorMessage != null)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, color: colors.error, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Could not load owner information',
                                style: TextStyle(color: colors.error),
                              ),
                              TextButton(
                                onPressed: _fetchOwnerData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (_ownerData != null)
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

                              // Owner details
                              infoRow('Email', _ownerData?['email'], colors),
                              infoRow('Phone', _getPhoneNumberAsString(), colors),

                              // Combined address fields
                              infoRow('Address', _getFormattedAddress(), colors, multiLine: true),
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
                        'If you find this cat, please contact the owner directly. Ensure your own safety when arranging a meet-up.',
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
    );
  }
}
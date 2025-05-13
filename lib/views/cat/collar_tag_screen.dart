import 'package:flutter/material.dart';
import 'dart:async';

class CollarTagScreen extends StatefulWidget {
  final Map<String, dynamic> cat;

  const CollarTagScreen({
    Key? key,
    required this.cat,
  }) : super(key: key);

  @override
  State<CollarTagScreen> createState() => _CollarTagScreenState();
}

class _CollarTagScreenState extends State<CollarTagScreen> with SingleTickerProviderStateMixin {
  bool _hasQrTag = false;
  bool _hasGpsTag = false;
  int _selectedTagIndex = 0;
  final PageController _pageController = PageController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Check if the cat already has tags (this would come from your database)
    _checkExistingTags();
  }

  void _checkExistingTags() {
    // Simulate checking if the cat already has tags
    // In a real app, you would fetch this from your database
    setState(() {
      _hasQrTag = widget.cat['has_qr_tag'] ?? false;
      _hasGpsTag = widget.cat['has_gps_tag'] ?? false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTagSelected(int index) {
    setState(() {
      _selectedTagIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedTagIndex = index;
      _tabController.animateTo(index);
    });
  }

  void _purchaseTag(String tagType) {
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

      // Show confirmation
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Purchase Successful!'),
            content: Text(
              tagType == 'qr'
                  ? 'Your QR Tag has been ordered and will arrive within 3-5 business days.'
                  : 'Your GPS Tag has been ordered and will arrive within 3-5 business days.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    if (tagType == 'qr') {
                      _hasQrTag = true;
                    } else {
                      _hasGpsTag = true;
                    }
                  });
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildTagManagementSection(String tagType) {
    final colors = Theme.of(context).colorScheme;
    final bool hasTag = tagType == 'qr' ? _hasQrTag : _hasGpsTag;
    final String tagName = tagType == 'qr' ? 'QR Tag' : 'GPS Tag';
    final String tagDescription = tagType == 'qr'
        ? 'When scanned, this QR code links to your cat\'s profile with your contact information.'
        : 'Tracks your cat\'s location in real-time, similar to an AirTag.';
    final IconData tagIcon = tagType == 'qr' ? Icons.qr_code : Icons.location_on;
    final double tagPrice = tagType == 'qr' ? 14.99 : 29.99;

    return SingleChildScrollView(
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
                        tagIcon,
                        size: 80,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tagName,
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
                        tagDescription,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      hasTag
                          ? Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
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
                            '\$${tagPrice.toStringAsFixed(2)}',
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
            icon: tagType == 'qr' ? Icons.person : Icons.location_searching,
            title: tagType == 'qr' ? 'Quick Contact Info' : 'Real-time Location',
            description: tagType == 'qr'
                ? 'Anyone who finds your cat can instantly access your contact information.'
                : 'Track your cat\'s location in real-time through the app.',
          ),
          _buildFeatureItem(
            icon: tagType == 'qr' ? Icons.qr_code_scanner : Icons.battery_alert,
            title: tagType == 'qr' ? 'Scannable QR Code' : 'Battery Alerts',
            description: tagType == 'qr'
                ? 'Works with any smartphone QR scanner.'
                : 'Receive notifications when the battery is getting low.',
          ),
          _buildFeatureItem(
            icon: tagType == 'qr' ? Icons.water_drop : Icons.history,
            title: tagType == 'qr' ? 'Waterproof' : 'Location History',
            description: tagType == 'qr'
                ? 'Durable and waterproof design.'
                : 'View your cat\'s movement patterns over time.',
          ),

          const SizedBox(height: 32),

          // Buy button or manage button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: hasTag
                  ? () {
                // Open tag management dialog or navigate to management screen
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Manage $tagName'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tagType == 'qr')
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Edit Contact Information'),
                            onTap: () {
                              Navigator.pop(context);
                              // Add navigation to edit contact info
                            },
                          ),
                        if (tagType == 'gps')
                          ListTile(
                            leading: const Icon(Icons.map),
                            title: const Text('View Location History'),
                            onTap: () {
                              Navigator.pop(context);
                              // Add navigation to location history
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Get Support'),
                          onTap: () {
                            Navigator.pop(context);
                            // Add navigation to support
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
                  : () => _purchaseTag(tagType),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasTag ? colors.surface : colors.primary,
                foregroundColor: hasTag ? colors.primary : colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colors.primary,
                    width: hasTag ? 1 : 0,
                  ),
                ),
              ),
              child: Text(
                hasTag ? 'Manage Tag' : 'Buy Now - \$${tagPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              onTap: _onTagSelected,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurface.withOpacity(0.6),
              indicatorColor: colors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(
                  text: 'QR Tag',
                  icon: Icon(Icons.qr_code),
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  text: 'GPS Tag',
                  icon: Icon(Icons.location_on),
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),

          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildTagManagementSection('qr'),
                _buildTagManagementSection('gps'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
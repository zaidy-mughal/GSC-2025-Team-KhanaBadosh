import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cat_detail_screen.dart';

class CatDashboard extends StatefulWidget {
  final Map<String, dynamic> cat;
  final Function(int) onNavigateToTab;
  final Function() onRefresh;


  const CatDashboard({
    super.key,
    required this.cat,
    required this.onNavigateToTab,
    required this.onRefresh,
  });

  @override
  State<CatDashboard> createState() => _CatDashboardState();
}

class _CatDashboardState extends State<CatDashboard> with AutomaticKeepAliveClientMixin {
  // Keep this state alive when navigating
  @override
  bool get wantKeepAlive => true;

  // Save a global key for accessing a valid context

  void _showSellCatDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Transfer Cat Ownership',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Enter new owner\'s email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final email = emailController.text.trim().toLowerCase();
                        if (email.isEmpty) return;

                        // Close the dialog before async operation
                        Navigator.of(dialogContext).pop();

                        // Store context for later use
                        final currentContext = context;

                        // Execute the transfer process
                        _processCatTransfer(email, currentContext);
                      },
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Separate method to handle the async operations
  Future<void> _processCatTransfer(String email, BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;

      // Get the user ID by email
      final response = await supabase
          .from('profiles')
          .select('user_id')
          .eq('email', email)
          .single();

      final toUserId = response['user_id'];
      debugPrint('User ID: $toUserId');

      final payload = {
        'cat_id': widget.cat['id'],
        'to_user_id': toUserId,
      };

      // Check if widget is still mounted before showing dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext qrContext) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Scan QR to Transfer Data',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ask the new owner to scan this QR code:'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200.0,
                    height: 200.0,
                    child: QrImageView(
                      data: payload.toString(),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(qrContext).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      // Use ScaffoldMessenger directly if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No User Found with this email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cat profile header - kept as is
            _buildProfileHeader(colors),

            const SizedBox(height: 20),

            // Divider
            Divider(
              color: colors.onSurface.withOpacity(0.2),
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 20),

            // Quick actions with grid layout like user_dashboard
            _buildQuickActions(colors),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CatDetailScreen(cat: widget.cat, onRefresh: widget.onRefresh),
                ),
              ).then((_) {
                widget.onRefresh();
              });
            },
            child: Hero(
              tag: 'cat_image_${widget.cat['id']}',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  image: widget.cat['image_url'] != null && widget.cat['image_url'].isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(widget.cat['image_url']),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: widget.cat['image_url'] == null || widget.cat['image_url'].isEmpty
                    ? Icon(
                  Icons.pets,
                  size: 60,
                  color: colors.primary,
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cat name
          Text(
            widget.cat['name'] ?? 'Your Cat',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          // Cat details
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDetailChip(
                  colors,
                  Icons.cake_rounded,
                  '${widget.cat['age'] ?? 0} ${int.parse(widget.cat['age'].toString()) == 1 ? 'year' : 'years'}'
              ),
              const SizedBox(width: 12),
              _buildDetailChip(colors, Icons.pets_rounded, widget.cat['breed'] ?? 'Unknown'),
              const SizedBox(width: 12),
              _buildDetailChip(colors,
                  widget.cat['gender'] == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                  widget.cat['gender'] ?? 'Unknown'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(ColorScheme colors, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              // Health Records card
              ActionCard(
                icon: Icons.medical_services,
                title: 'Health Records',
                value: 'Medical History',
                description: 'View and add health records',
                color: Colors.blue,
                onTap: () => widget.onNavigateToTab(2), // Navigate to Health tab
              ),

              // Collar Tag card .
              ActionCard(
                icon: Icons.qr_code,
                title: 'Collar Tag',
                value: 'QR Code Access',
                description: 'View and share tag information',
                color: Colors.orange,
                onTap: () => widget.onNavigateToTab(1), // Navigate to Collar Tag tab
              ),

              // Report Lost Cat card
              ActionCard(
                icon: Icons.report_problem,
                title: 'Report Lost',
                value: 'Lost Cat Alert',
                description: 'Report your cat as missing',
                color: Colors.red,
                onTap: () => widget.onNavigateToTab(3), // Navigate to Report Lost tab
              ),

              // Sell My Cat card
              ActionCard(
                icon: Icons.sell,
                title: 'Sell Cat',
                value: 'New Owner Transfer',
                description: 'Transfer ownership via QR code',
                color: Colors.amber,
                onTap: () => _showSellCatDialog(context),
                showBadge: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool showBadge;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
    required this.description,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1, // Consistent minimal elevation
      shadowColor: colorScheme.shadow.withOpacity(0.7),
      // Slightly adjust card color to differentiate from background
      color: Theme.of(context).brightness == Brightness.light
          ? colorScheme.surface.brighten(10)
          : colorScheme.surface.brighten(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (showBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to adjust color brightness (copied from user_dashboard.dart)
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
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user/user_detail_screen.dart';

class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();
  factory UserDataManager() => _instance;
  UserDataManager._internal();

  Map<String, dynamic>? userData;
  int catsCount = 0;
  DateTime? lastFetched;

  // Cache expiration threshold (15 minutes)
  static const cacheDuration = Duration(minutes: 15);

  bool get isDataFresh => lastFetched != null &&
      DateTime.now().difference(lastFetched!) < cacheDuration;

  Future<void> fetchUserData() async {
    // If data is fresh, no need to fetch again
    if (isDataFresh) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      final catsResponse = await Supabase.instance.client
          .from('cats')
          .select('id')
          .eq('user_id', userId);

      userData = response;
      catsCount = catsResponse.length;
      lastFetched = DateTime.now();
    } catch (e) {
      // Handle any errors here if needed
      print('Error fetching user data: $e');
    }
  }

  // Force refresh data
  Future<void> refreshUserData() async {
    lastFetched = null;
    await fetchUserData();
  }
}

class UserDashboard extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const UserDashboard({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _userDataManager = UserDataManager();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    await _userDataManager.fetchUserData();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showUserDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(userData: _userDataManager.userData!),
      ),
    ).then((_) {
      // Optional: Refresh data when returning from details screen
      // if you expect data might change there
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _navigateToTab(int tabIndex) {
    widget.onNavigateToTab(tabIndex);
  }

  void _showCatTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => const CatTipsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userDataManager.userData == null
          ? const Center(child: Text("No user data found"))
          : RefreshIndicator(
        onRefresh: () async {
          await _userDataManager.refreshUserData();
          if (mounted) setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              UserCard(
                userData: _userDataManager.userData!,
                onTap: _showUserDetails,
              ),
              Divider(
                color: colors.onSurface.withOpacity(0.2),
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              const SizedBox(height: 20),
              DashboardActions(
                catsCount: _userDataManager.catsCount,
                onCatsPressed: () => _navigateToTab(1),
                onLostFoundPressed: () => _navigateToTab(2),
                onNewsPressed: () => _navigateToTab(3),
                onChatPressed: () => _navigateToTab(4),
                onTipsPressed: _showCatTipsDialog,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.userData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Card(
      elevation: brightness == Brightness.light ? 4 : 0,
      color: colorScheme.surface,
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                backgroundImage: userData['profile_image_url'] != null &&
                    userData['profile_image_url'].isNotEmpty
                    ? NetworkImage(userData['profile_image_url'])
                    : null,
                child: userData['profile_image_url'] == null ||
                    userData['profile_image_url'].isEmpty
                    ? Icon(
                  Icons.person,
                  size: 30,
                  color: colorScheme.primary,
                )
                    : null,
              ),
              const SizedBox(width: 16),
              // Display Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['display_name'] ?? 'No Display Name',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Indication arrow
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardActions extends StatelessWidget {
  final int catsCount;
  final VoidCallback onCatsPressed;
  final VoidCallback onLostFoundPressed;
  final VoidCallback onNewsPressed;
  final VoidCallback onChatPressed;
  final VoidCallback onTipsPressed;

  const DashboardActions({
    super.key,
    required this.catsCount,
    required this.onCatsPressed,
    required this.onLostFoundPressed,
    required this.onNewsPressed,
    required this.onChatPressed,
    required this.onTipsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

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
                color: colorScheme.onSurface,
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
              // Cats card
              ActionCard(
                icon: Icons.pets,
                title: 'My Cats',
                value: '$catsCount Cat Profiles',
                description: 'Manage your cat companions',
                color: colorScheme.primary,
                onTap: onCatsPressed,
                elevation: brightness == Brightness.light ? 2 : 0,
              ),

              // Lost & Found card
              ActionCard(
                icon: Icons.search,
                title: 'Lost & Found',
                value: 'Lost or Found a Cat?',
                description: 'Help reunite cats with owners',
                color: Colors.orange,
                onTap: onLostFoundPressed,
                elevation: brightness == Brightness.light ? 2 : 0,
              ),

              // News card
              ActionCard(
                icon: Icons.newspaper,
                title: 'Cat News',
                value: 'Read News About Cats',
                description: 'Latest cat care tips and news',
                color: Colors.blue,
                onTap: onNewsPressed,
                elevation: brightness == Brightness.light ? 2 : 0,
              ),

              // Chat card
              ActionCard(
                icon: Icons.chat,
                title: 'Cat Chat',
                value: 'Chat With AI About Cats',
                description: 'Get advice and assistance',
                color: Colors.green,
                onTap: onChatPressed,
                elevation: brightness == Brightness.light ? 2 : 0,
                showBadge: true,
              ),

              // Cat Tips card
              ActionCard(
                icon: Icons.info_outline,
                title: 'Cat Tips',
                value: 'Care Tips & Advice',
                description: 'Best practices for cat care',
                color: Colors.purple,
                onTap: onTipsPressed,
                elevation: brightness == Brightness.light ? 2 : 0,
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
  final double elevation;
  final bool showBadge;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
    required this.description,
    this.elevation = 2,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: elevation,
      color: colorScheme.surface,
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

class CatTipsDialog extends StatelessWidget {
  const CatTipsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.info_outline, color: colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Cat Care Tips',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.2)),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTipItem(
                      context,
                      icon: Icons.water_drop,
                      title: 'Fresh Water Daily',
                      description: 'Make sure your cat always has access to clean water.',
                    ),
                    const SizedBox(height: 16),
                    _buildTipItem(
                      context,
                      icon: Icons.restaurant,
                      title: 'Balanced Diet',
                      description: 'Feed your cat high-quality food appropriate for their age and health needs.',
                    ),
                    const SizedBox(height: 16),
                    _buildTipItem(
                      context,
                      icon: Icons.fitness_center,
                      title: 'Regular Exercise',
                      description: 'Engage your cat in play to keep them physically active and mentally stimulated.',
                    ),
                    const SizedBox(height: 16),
                    _buildTipItem(
                      context,
                      icon: Icons.medical_services,
                      title: 'Regular Vet Visits',
                      description: 'Schedule annual checkups to ensure your cat stays healthy and prevent issues.',
                    ),
                    const SizedBox(height: 16),
                    _buildTipItem(
                      context,
                      icon: Icons.cleaning_services,
                      title: 'Clean Litter Box',
                      description: 'Clean the litter box daily and change litter regularly to maintain hygiene.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
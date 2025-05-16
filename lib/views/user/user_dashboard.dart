import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user/user_detail_screen.dart';

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

class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();
  factory UserDataManager() => _instance;
  UserDataManager._internal();

  Map<String, dynamic>? userData;
  int catsCount = 0;
  DateTime? lastFetched;
  String? _currentUserId;

  // Cache expiration threshold (15 minutes)
  static const cacheDuration = Duration(minutes: 15);

  bool get isDataFresh => lastFetched != null &&
      DateTime.now().difference(lastFetched!) < cacheDuration;

  // Clear all user data
  void clearData() {
    userData = null;
    catsCount = 0;
    lastFetched = null;
    _currentUserId = null;
  }

  Future<void> fetchUserData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // If no logged in user, clear data and return
    if (userId == null) {
      clearData();
      return;
    }

    // Check if the user has changed or if data is stale
    final userChanged = _currentUserId != userId;
    if (userChanged) {
      // Clear existing data if user has changed
      clearData();
      _currentUserId = userId;
    } else if (isDataFresh && userData != null) {
      // If data is fresh and for the current user, no need to fetch again
      return;
    }

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
      debugPrint('Error fetching user data: $e');
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
      _userDataManager.refreshUserData().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _navigateToTab(int tabIndex) {
    widget.onNavigateToTab(tabIndex);
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
    final greeting = _getGreeting();

    return Card(
      elevation: 1, // Consistent minimal elevation
      shadowColor: colorScheme.shadow.withOpacity(0.7),
      // Slightly adjust card color to differentiate from background
      color: Theme.of(context).brightness == Brightness.light
          ? colorScheme.surface.brighten(10)
          : colorScheme.surface.brighten(15),
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Row(
            children: [
              // Profile Image - Larger size
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                backgroundImage: userData['profile_image_url'] != null &&
                    userData['profile_image_url'].isNotEmpty
                    ? NetworkImage(userData['profile_image_url'])
                    : null,
                child: userData['profile_image_url'] == null ||
                    userData['profile_image_url'].isEmpty
                    ? Icon(
                  Icons.person,
                  size: 40,
                  color: colorScheme.primary,
                )
                    : null,
              ),
              const SizedBox(width: 16),
              // Display Name and Welcome Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['display_name'] ?? 'No Display Name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tap to view your profile details',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  // Helper method to generate a friendly greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

}

class DashboardActions extends StatelessWidget {
  final int catsCount;
  final VoidCallback onCatsPressed;
  final VoidCallback onLostFoundPressed;
  final VoidCallback onNewsPressed;
  final VoidCallback onChatPressed;

  const DashboardActions({
    super.key,
    required this.catsCount,
    required this.onCatsPressed,
    required this.onLostFoundPressed,
    required this.onNewsPressed,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              ),

              // Lost & Found card
              ActionCard(
                icon: Icons.search,
                title: 'Lost & Found',
                value: 'Lost or Found a Cat?',
                description: 'Help reunite cats with owners',
                color: Colors.orange,
                onTap: onLostFoundPressed,
              ),

              // News card
              ActionCard(
                icon: Icons.newspaper,
                title: 'Cat News',
                value: 'Read News About Cats',
                description: 'Latest cat care tips and news',
                color: Colors.blue,
                onTap: onNewsPressed,
              ),

              // Chat card
              ActionCard(
                icon: Icons.chat,
                title: 'Cat Chat',
                value: 'Chat With AI About Cats',
                description: 'Get advice and assistance',
                color: Colors.green,
                onTap: onChatPressed,
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
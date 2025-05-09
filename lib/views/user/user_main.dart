import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/theme_toggle.dart';
import '../user/user_dashboard.dart';
import '../user/user_cats_screen.dart';
import '../user/setting_screen.dart';
import '../user/news_screen.dart';
import '../user/chat_screen.dart';
import '../user/lost_and_found_screen.dart';

class UserMain extends StatefulWidget {
  const UserMain({super.key});

  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final List<String> _titles = [
    'Dashboard',
    'Cats',
    'Lost & Found',
    'News',
    'Chat'
  ];

  // Pass this method to the dashboard to allow it to change tabs
  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  List<Widget> _getPages() {
    return [
      UserDashboard(onNavigateToTab: _navigateToTab),
      const CatsListScreen(),
      const LostAndFoundScreen(),
      const NewsScreen(),
      const ChatScreen(),
    ];
  }

  void _onItemTapped(int index) {
    _navigateToTab(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              bottom: BorderSide(
                color: colors.outlineVariant.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colors.onSurface,
              ),
            ),
            elevation: 0,
            backgroundColor: colors.surface,
            centerTitle: true,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: ThemeToggle(),
              )
            ],
          ),
        ),
      ),
      drawer: Drawer(
        elevation: 2,
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: colors.onPrimary.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cat Shelter App',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'User Menu',
                        style: TextStyle(
                          color: colors.onPrimary.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    index: 0,
                    colors: colors,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.pets_rounded,
                    title: 'Cats',
                    index: 1,
                    colors: colors,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.search_rounded,
                    title: 'Lost & Found',
                    index: 2,
                    colors: colors,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.newspaper_rounded,
                    title: 'News',
                    index: 3,
                    colors: colors,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.chat_rounded,
                    title: 'Chat',
                    index: 4,
                    colors: colors,
                  ),
                  const Divider(thickness: 1),
                  ListTile(
                    leading: Icon(
                      Icons.settings_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Logout button at the bottom
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.outlineVariant, width: 0.5),
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: colors.error,
                  size: 24,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: _signOut,
              ),
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: _getPages(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          backgroundColor: colors.surface,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
          ),
          showUnselectedLabels: true,
          elevation: 8,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_rounded),
              label: 'Cats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Lost & Found',
              activeIcon: Icon(Icons.search),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_rounded),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required int index,
        required ColorScheme colors,
      }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        icon,
        color: isSelected ? colors.primary : colors.onSurface.withOpacity(0.7),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colors.primary : colors.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colors.primaryContainer.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        _navigateToTab(index);
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../user/user_dashboard.dart';
import '../user/user_cats_screen.dart';
import '../user/news_screen.dart';
import '../user/chat_screen.dart';
import '../user/lost_and_found_screen.dart';
import 'settings_dialog.dart';
import 'settings_screen.dart';

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
    'Chat',
    'Settings'
  ];
  bool _isDialogOpen = false;

  // Track if user is currently dragging
  bool _isDragging = false;
  // Store drag start position to determine direction
  double _dragStartPosition = 0;

  // Define constants for page indices
  static const int kDashboardIndex = 0;
  static const int kSettingsIndex = 5;
  static const int kChatIndex = 4;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null &&
          (_pageController.page?.round() ?? -1) != _selectedIndex) {
      }
    });
  }

  // Pass this method to the dashboard to allow it to change tabs
  void _navigateToTab(int index) {

    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });

      // Prevent animation to/from settings page
      if (index == kSettingsIndex || _selectedIndex == kSettingsIndex) {
        _pageController.jumpToPage(index);
      } else {
        _pageController.jumpToPage(index);
      }
    }
  }

  List<Widget> _getPages() {
    return [
      UserDashboard(onNavigateToTab: _navigateToTab),
      const CatsListScreen(),
      const LostAndFoundScreen(),
      const NewsScreen(),
      const ChatScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    // If already on dashboard and dashboard is tapped again
    if (index == kDashboardIndex && _selectedIndex == kDashboardIndex) {
      // Could add "scroll to top" or refresh functionality here
      _pageController.jumpToPage(kDashboardIndex);
      return;
    }

    // Don't navigate to settings from bottom nav - settings is only accessible from dialog
    if (index < kSettingsIndex) {
      _navigateToTab(index);
    }
  }

  // Updated page changed handler with swipe constraints
  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        // Only update selected index for non-settings pages
        _selectedIndex = index < kSettingsIndex ? index : kDashboardIndex;
      });
    }
  }

  void _navigateToSettingsPage() {
    if (mounted) {
      // Use jumpToPage to ensure immediate transition without animation
      _pageController.jumpToPage(kSettingsIndex);
      setState(() {
        _selectedIndex = kSettingsIndex;
      });
    }
  }

  void _showSettingsDialog() {
    setState(() {
      _isDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => SettingsDialog(
        onClose: () {
          Navigator.of(dialogContext).pop();
          if (mounted) {
            setState(() {
              _isDialogOpen = false;
            });
          }
        },
        onNavigateToSettings: (_) {
          Navigator.of(dialogContext).pop();
          if (mounted) {
            setState(() {
              _isDialogOpen = false;
            });

            // Navigate to settings page after dialog is closed
            _navigateToSettingsPage();
          }
        },
      ),
    ).then((_) {
      // In case dialog is dismissed by tapping outside
      if (mounted && _isDialogOpen) {
        setState(() {
          _isDialogOpen = false;
        });
      }
    });
  }

  // Updated page swipe handler that prevents navigation between settings and chat
  bool _handlePageSwipe(ScrollNotification notification) {
    // For scroll start, capture the beginning position and current page
    if (notification is ScrollStartNotification) {
      _isDragging = true;
      _dragStartPosition = notification.metrics.pixels;
      return false;
    }

    // For scroll update, implement our custom swipe logic
    if (notification is ScrollUpdateNotification && _isDragging) {
      final currentPage = _pageController.page?.round() ?? 0;
      final isSwipingLeft = notification.metrics.pixels > _dragStartPosition;

      // Case 1: On settings page (index 5), prevent any swipe navigation
      if (currentPage == kSettingsIndex) {
        if (notification is ScrollUpdateNotification) {
          _pageController.jumpToPage(kSettingsIndex);
        }
        return true; // Block all swipes from settings page
      }

      // Case 2: Trying to swipe to settings page
      else if (currentPage == kChatIndex && isSwipingLeft) {
        // Prevent swiping left to settings from chat page
        if (notification is ScrollUpdateNotification) {
          _pageController.jumpToPage(kChatIndex);
        }
        return true; // Block the scroll
      }
    }

    // For scroll end, reset tracking
    if (notification is ScrollEndNotification) {
      _isDragging = false;
    }

    return false; // Allow other scrolling behavior
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

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
            leading: IconButton(
              icon: Icon(
                _isDialogOpen ? Icons.close : Icons.menu,
                color: colors.onSurface,
              ),
              onPressed: _showSettingsDialog,
            ),
            title: Text(
              _selectedIndex < _titles.length ? _titles[_selectedIndex] : _titles[0],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colors.onSurface,
              ),
            ),
            elevation: 0,
            backgroundColor: colors.surface,
            centerTitle: true,
            actions: [
              // Theme toggle with sun/moon icon
              IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode  // Sun icon for light mode
                      : Icons.dark_mode,  // Moon icon for dark mode
                  color: colors.onSurface,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handlePageSwipe,
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const PageScrollPhysics(), // Use basic physics, we'll handle custom behavior
          children: _getPages(),
        ),
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
          currentIndex: _selectedIndex < kSettingsIndex ? _selectedIndex : kDashboardIndex, // Keep Dashboard selected if on settings
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
}
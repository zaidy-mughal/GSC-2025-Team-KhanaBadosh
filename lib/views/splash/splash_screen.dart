import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../user/user_main.dart';
import '../../core/services/supabase_service.dart';
import '../auth/complete_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Create animation that goes from 0.0 to 1.0 (fully visible on screen)
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );

    // Start the animation
    _animationController.forward();

    // Check auth after animation starts
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Add a delay for splash screen display (matches animation duration)
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    // Check if user is logged in
    final currentUser = SupabaseService.currentUser;

    if (currentUser != null) {
      // User is logged in, check if profile is completed
      try {
        final userProfile = await SupabaseService.getUserProfile();

        // Check if profile exists and if is_data_added is true
        final bool isProfileComplete = userProfile != null &&
            userProfile['is_data_added'] == true;

        if (isProfileComplete) {
          // Profile is complete, navigate to dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const UserMain()),
          );
        } else {
          // Profile is not complete, navigate to complete profile screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(
                initialDisplayName: currentUser.userMetadata?['name'] ?? '',
                initialEmail: currentUser.email ?? '',
              ),
            ),
          );
        }
      } catch (e) {
        // Handle error - if we can't check profile status, default to profile completion
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              initialDisplayName: currentUser.userMetadata?['name'] ?? '',
              initialEmail: currentUser.email ?? '',
            ),
          ),
        );
      }
    } else {
      // No user logged in, navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the progress line boundaries
    final double progressLineStart = MediaQuery.of(context).size.width * 0.1;
    final double progressLineEnd = MediaQuery.of(context).size.width * 0.9;
    final double progressLineWidth = progressLineEnd - progressLineStart;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Progress Line (background)
          Positioned(
            left: progressLineStart,
            right: MediaQuery.of(context).size.width * 0.1,
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Animated Progress Line (foreground)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                left: progressLineStart,
                bottom: MediaQuery.of(context).size.height * 0.2,
                child: Container(
                  height: 5,
                  width: progressLineWidth * _animation.value,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),

          // Animated cat
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Calculate cat position along the progress line
              double catX = progressLineStart + (progressLineWidth * _animation.value);

              // Center the cat on the current progress point (half of cat width = 40)
              double adjustedX = catX - 40;

              return Positioned(
                left: adjustedX,
                bottom: MediaQuery.of(context).size.height * 0.22,
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Image.asset(
                    'assets/images/cat_silhouette.png',
                    fit: BoxFit.contain,
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              );
            },
          ),

          // App logo in the center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // Team credit text at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.05,
            child: Center(
              child: Text(
                'Developed by Team KhanaBadosh',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
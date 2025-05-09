import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;
  String? _errorMessage;
  bool _isEmailFocused = false;

  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isEmailFocused = _emailFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();

      // Using Supabase password reset
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        // Uncomment and update this if you have a password reset page
        // redirectTo: 'io.supabase.flutterquickstart://reset-callback/',
      );

      if (mounted) {
        setState(() {
          _isEmailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send reset link: ${e.toString()}';
          _isLoading = false;
        });
      }
      print('Password reset error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Forgot Password",
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon with shadow (similar to profile avatar)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.lock_outline,
                      size: 70,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title and subtitle
                Text(
                  _isEmailSent ? 'Check Your Email' : 'Reset Your Password',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isEmailSent
                      ? "We've sent a password reset link to ${_emailController.text}. Please check your inbox and follow the instructions."
                      : "Enter your email address and we'll send you instructions to reset your password",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Display error message if any
                if (_errorMessage != null && !_isEmailSent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Form or success view
                if (_isEmailSent)
                  Column(
                    children: [
                      // Success illustration
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: colors.primary,
                          size: 60,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Return to login button
                      _buildButton(
                        Icons.login_outlined,
                        "RETURN TO LOGIN",
                            () => Navigator.pushReplacementNamed(context, '/login'),
                        color: colors.primary,
                      ),
                    ],
                  )
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email input with underline
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: colors.onSurfaceVariant),
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.7)),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: _isEmailFocused ? colors.primary : colors.primary.withOpacity(0.7),
                                      size: 22,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@') || !value.contains('.')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              // Animated underline that changes color when focused
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 2,
                                color: _isEmailFocused
                                    ? colors.primary
                                    : colors.onSurfaceVariant.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Send reset link button
                        _buildButton(
                          Icons.send_outlined,
                          _isLoading ? "SENDING..." : "SEND RESET LINK",
                          _isLoading ? null : _resetPassword,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Button style similar to user version but using theme colors
  Widget _buildButton(IconData icon, String text, VoidCallback? onTap, {
    required Color color,
    Color? textColor,
  }) {
    final onColor = textColor ?? Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: onColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3,
          shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
          disabledBackgroundColor: color.withOpacity(0.5),
          disabledForegroundColor: onColor.withOpacity(0.7),
        ),
      ),
    );
  }
}
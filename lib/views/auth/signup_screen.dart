import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/theme_toggle.dart';
import 'complete_profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final displayName = _nameController.text.trim();

      // Sign up with Supabase - use both name and display_name fields
      final response = await SupabaseService.signUp(
        email,
        password,
        metadata: {
          'name': displayName,
          'display_name': displayName,
        },
      );

      if (mounted) {
        // Since we're not requiring email verification, we can navigate to the complete profile screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteProfileScreen(
              initialDisplayName: displayName,
              initialEmail: email,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains('already registered')) {
          _errorMessage = 'Email already in use. Try signing in.';
        } else {
          _errorMessage = 'Authentication error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create account: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Create Account",
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        actions: const [ThemeToggle()],
      ),
      body: _buildSignupForm(context),
    );
  }

  Widget _buildSignupForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Icon with Shadow
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.person_add_outlined,
                      size: 70,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Header Text
                Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign up to get started",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Card
                Card(
                  color: colors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Name field
                        _buildInputRow(
                          Icons.person_outline,
                          _nameController,
                          "Display Name",
                          isPassword: false,
                        ),
                        Divider(height: 24, color: colors.outlineVariant),

                        // Email field
                        _buildInputRow(
                          Icons.email_outlined,
                          _emailController,
                          "Email",
                          isPassword: false,
                        ),
                        Divider(height: 24, color: colors.outlineVariant),

                        // Password field
                        _buildInputRow(
                          Icons.lock_outline,
                          _passwordController,
                          "Password",
                          isPassword: true,
                        ),
                        Divider(height: 24, color: colors.outlineVariant),

                        // Confirm password field
                        _buildInputRow(
                          Icons.lock_outline,
                          _confirmPasswordController,
                          "Confirm Password",
                          isPassword: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 14,
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // Sign Up Button
                _buildButton(
                  Icons.person_add_outlined,
                  "Sign Up",
                  _isLoading ? null : _signUp,
                  colors.primary,
                ),

                // Sign in link
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: colors.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: colors.primary,
                          ),
                        ),
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

  Widget _buildInputRow(
      IconData icon,
      TextEditingController controller,
      String label, {
        required bool isPassword,
      }) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            obscureText: isPassword ? !_showPassword : false,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurface,
              fontWeight: FontWeight.w300,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: colors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w300,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              errorStyle: const TextStyle(height: 0), // Hide error text here
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (label == "Email" && (!value.contains('@') || !value.contains('.'))) {
                return 'Please enter a valid email';
              }
              if (label == "Password" && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              if (label == "Confirm Password" && value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ),
        if (isPassword)
          IconButton(
            icon: Icon(
              _showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: colors.primary,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
      ],
    );
  }

  Widget _buildButton(IconData icon, String text, VoidCallback? onTap, Color buttonColor) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: _isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
          ),
        )
            : Icon(icon, size: 20),
        label: Text(
          _isLoading ? "" : text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }
}
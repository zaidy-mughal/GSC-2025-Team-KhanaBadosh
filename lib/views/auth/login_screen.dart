import 'package:flutter/material.dart';
import '../../widgets/theme_toggle.dart';
import '../../core/services/supabase_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../user/user_main.dart';
import '../settings/settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserMain(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to login. Please check your credentials.';
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
        actions: const [ThemeToggle()],
      ),
      body: _buildLoginForm(context),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User icon container with shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    size: 70,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title and subtitle
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Login form card
              Card(
                color: colors.surfaceContainerHighest.brighten(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        isEmail: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sign In button
              _buildButton(
                icon: Icons.login_outlined,
                text: 'Sign In',
                onTap: _isLoading ? null : () => _login(),
                isLoading: _isLoading,
                color: colors.primary,
              ),

              // Sign Up option
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isEmail = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText && !_isPasswordVisible,
                keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface,
                  fontWeight: FontWeight.w300,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(color: colors.onSurface.withOpacity(0.7)),
                  suffixIcon: obscureText
                      ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your ${label.toLowerCase()}';
                  }
                  if (isEmail && (!value.contains('@') || !value.contains('.'))) {
                    return 'Please enter a valid email';
                  }
                  if (obscureText && value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        Divider(height: 24, color: colors.outlineVariant),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    required Color color,
    bool isLoading = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: isLoading
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
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
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
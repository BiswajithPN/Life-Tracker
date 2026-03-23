import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/floating_glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../state/user_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final error = ref.read(userProvider.notifier).login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.8),
                radius: 1.5,
                colors: [Color(0xFF1E112A), AppTheme.background],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.accentCyan, AppTheme.accentMagenta],
                      ).createShader(bounds),
                      child: Text(
                        'LIFE TRACKER',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SYNC YOUR REALITY',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        letterSpacing: 6,
                        color: AppTheme.accentCyan.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 50),

                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.glowingRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glowingRed.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.glowingRed),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    FloatingGlassCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _usernameController,
                            hint: 'Username',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 30),
                          NeonButton(
                            onPressed: _handleLogin,
                            text: 'LOG IN',
                            isLoading: _isLoading,
                            glowColor: AppTheme.accentCyan,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppTheme.textSecondary),
                          children: const [
                            TextSpan(
                              text: 'CREATE ONE',
                              style: TextStyle(
                                color: AppTheme.accentMagenta,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: Icon(icon, color: AppTheme.accentCyan.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.accentCyan, width: 1),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      mySnackBar(
        context: context,
        text: 'Password tidak cocok',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            data: {'full_name': _nameController.text.trim()},
          );
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Registrasi berhasil! Silakan cek email Anda.',
          status: ToastStatus.success,
        );
        context.pushReplacement('/setup-password');
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Registrasi Gagal: ${e.toString()}',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Google Sign-In Gagal: ${e.toString()}',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Curves
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Buat Akun Baru',
                      style: theme.textTheme.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Mulai kelola bisnis Anda dengan sistem POS modern.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.muted.copyWith(fontSize: 16),
                    ).animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Register Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar',
                            style: theme.textTheme.h3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lengkapi data di bawah untuk membuat akun.',
                            style: theme.textTheme.muted.copyWith(fontSize: 14),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Name Field
                          const Text(
                            'Nama Lengkap',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _nameController,
                            placeholder: const Text('John Doe'),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: ShadDecoration(
                              color: const Color(0xFFF1F3F5),
                              border: ShadBorder.none,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Email Field
                          const Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _emailController,
                            placeholder: const Text('parzivalxdd@gmail.com'),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: ShadDecoration(
                              color: const Color(0xFFEDF2FF),
                              border: ShadBorder.none,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Password Field
                          const Text(
                            'Password',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _passwordController,
                            placeholder: const Text('••••••••'),
                            obscureText: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: ShadDecoration(
                              color: const Color(0xFFEDF2FF),
                              border: ShadBorder.none,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Confirm Password Field
                          const Text(
                            'Konfirmasi Password',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _confirmPasswordController,
                            placeholder: const Text('••••••••'),
                            obscureText: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: ShadDecoration(
                              color: const Color(0xFFF1F3F5),
                              border: ShadBorder.none,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Text(
                                      'Daftar Sekarang',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'ATAU DAFTAR DENGAN',
                                  style: theme.textTheme.small.copyWith(
                                    color: Colors.grey[500],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Google Login
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(TablerIcons.brand_google, size: 20, color: Colors.black),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Google',
                                    style: theme.textTheme.h4.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Login Footer
                          Center(
                            child: TextButton(
                              onPressed: () => context.pop(),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Sudah punya akun? ',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Login di sini',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: Colors.black87),
      ),
    );
  }
}

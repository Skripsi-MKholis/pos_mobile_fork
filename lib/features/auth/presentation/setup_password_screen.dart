import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';

class SetupPasswordScreen extends ConsumerStatefulWidget {
  const SetupPasswordScreen({super.key});

  @override
  ConsumerState<SetupPasswordScreen> createState() =>
      _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends ConsumerState<SetupPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSavePassword() async {
    if (_passwordController.text.length < 6) {
      mySnackBar(
        context: context,
        text: 'Password minimal 6 karakter',
        status: ToastStatus.error,
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      mySnackBar(
        context: context,
        text: 'Password tidak cocok',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    // TODO: Implement password update logic in authProvider
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
    setState(() => _isLoading = false);

    if (mounted) {
      mySnackBar(
        context: context,
        text: 'Password berhasil disimpan!',
        status: ToastStatus.success,
      );
      context.go('/select-store');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(TablerIcons.lock, size: 40, color: primaryColor),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 24),

                Text(
                  'Keamanan Akun',
                  style: theme.textTheme.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Atur kata sandi Anda untuk akses lebih mudah di masa depan.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.muted.copyWith(fontSize: 16),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // Main Form Area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ATUR KATA SANDI',
                                style: theme.textTheme.h4.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Gunakan minimal 6 karakter kombinasi huruf dan angka.',
                                style: theme.textTheme.muted.copyWith(
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Password Field
                              const Text(
                                'Password Baru',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ShadInput(
                                controller: _passwordController,
                                placeholder: const Text('••••••••'),
                                obscureText: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: ShadDecoration(
                                  color: const Color(0xFFF1F3F5),
                                  border: ShadBorder.none,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Confirm Password Field
                              const Text(
                                'Konfirmasi Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ShadInput(
                                controller: _confirmPasswordController,
                                placeholder: const Text('••••••••'),
                                obscureText: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: ShadDecoration(
                                  color: const Color(0xFFF1F3F5),
                                  border: ShadBorder.none,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleSavePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              TablerIcons.sparkles,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'SIMPAN & LANJUTKAN',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Footer Link
                              Center(
                                child: TextButton(
                                  onPressed: () => context.go('/select-store'),
                                  child: Text(
                                    'Lewati, Saya sudah punya',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

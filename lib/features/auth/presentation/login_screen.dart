import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Login Gagal: ${e.toString()}')),
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
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Google Sign In Gagal: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  TablerIcons.cash_banknote,
                  size: 64,
                  color: Colors.black,
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  'Parzello POS',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.h2,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk mengelola toko Anda',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.muted,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 48),
                ShadCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ShadInput(
                        controller: _emailController,
                        placeholder: const Text('nama@toko.com'),
                        leading: const Padding(padding: EdgeInsets.all(8.0), child: Icon(TablerIcons.mail, size: 18)),
                      ),
                      const SizedBox(height: 20),
                      const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ShadInput(
                        controller: _passwordController,
                        obscureText: true,
                        placeholder: const Text('••••••••'),
                        leading: const Padding(padding: EdgeInsets.all(8.0), child: Icon(TablerIcons.lock, size: 18)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),
                ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Login ke Sistem'),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 16),
                ShadButton.ghost(
                  onPressed: () => context.push('/register'),
                  child: const Text('Belum punya akun? Daftar sekarang'),
                ).animate().fadeIn(delay: 1000.ms),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ATAU', style: theme.textTheme.small),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ],
                ).animate().fadeIn(delay: 1100.ms),
                const SizedBox(height: 32),
                ShadButton.outline(
                  size: ShadButtonSize.lg,
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  leading: const Icon(TablerIcons.brand_google, size: 20),
                  child: const Text('Lanjutkan dengan Google'),
                ).animate().fadeIn(delay: 1200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

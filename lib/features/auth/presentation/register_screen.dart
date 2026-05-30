import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      mySnackBar(
        context: context,
        text: l10n.allFieldsRequired,
        status: ToastStatus.error,
      );
      return;
    }

    if (password != confirmPassword) {
      mySnackBar(
        context: context,
        text: l10n.passwordsDoNotMatch,
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signUp(
            email,
            password,
            data: {'full_name': name},
          );
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.registrationSuccess,
          status: ToastStatus.success,
        );
        context.pushReplacement('/setup-password');
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.registrationFailed(e.toString()),
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.googleSignInFailed(e.toString()),
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showLanguageSelector(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final currentLocale = ref.read(localeNotifierProvider);

    await showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(l10n.selectLanguage),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(
                  context: context,
                  title: l10n.indonesian,
                  isSelected: currentLocale.languageCode == 'id',
                  theme: theme,
                  onTap: () {
                    ref.read(localeNotifierProvider.notifier).changeLocale('id');
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  context: context,
                  title: l10n.english,
                  isSelected: currentLocale.languageCode == 'en',
                  theme: theme,
                  onTap: () {
                    ref.read(localeNotifierProvider.notifier).changeLocale('en');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required ShadThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
            if (isSelected)
              Icon(
                TablerIcons.check,
                color: theme.colorScheme.primary,
                size: 18,
              )
            else
              const SizedBox(width: 18, height: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.createAccount,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      l10n.registerSubtitle,
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.register,
                            style: theme.textTheme.h3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.registerInstructions,
                            style: theme.textTheme.muted.copyWith(fontSize: 14),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Name Field
                          Text(
                            l10n.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _nameController,
                            placeholder: const Text('John Doe'),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: const ShadDecoration(
                              color: Color(0xFFF1F3F5),
                              border: ShadBorder.none,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Email Field
                          Text(
                            l10n.email,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _emailController,
                            placeholder: const Text('contoh@email.com'),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: const ShadDecoration(
                              color: Color(0xFFEDF2FF),
                              border: ShadBorder.none,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Password Field
                          Text(
                            l10n.password,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _passwordController,
                            placeholder: const Text('••••••••'),
                            obscureText: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: const ShadDecoration(
                              color: Color(0xFFEDF2FF),
                              border: ShadBorder.none,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Confirm Password Field
                          Text(
                            l10n.confirmPassword,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _confirmPasswordController,
                            placeholder: const Text('••••••••'),
                            obscureText: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: const ShadDecoration(
                              color: Color(0xFFF1F3F5),
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
                                  : Text(
                                      l10n.registerNow,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                  l10n.orRegisterWith,
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
                                  text: l10n.alreadyHaveAccount,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: l10n.loginHere,
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
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLanguageSelector(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(TablerIcons.language, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          currentLocale.languageCode == 'id' ? 'ID' : 'EN',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(TablerIcons.chevron_down, size: 12, color: Colors.black54),
                      ],
                    ),
                  ),
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

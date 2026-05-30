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
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      mySnackBar(
        context: context,
        text: l10n.emailPasswordRequired,
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(email, password);
      if (mounted) context.go('/select-store');
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.loginFailed(e.toString()),
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
      if (mounted) context.go('/select-store');
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
                    // Top Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        TablerIcons.building_store,
                        size: 32,
                        color: Colors.black,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      l10n.welcomeBack,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.muted.copyWith(fontSize: 15),
                    ).animate().fadeIn(delay: 300.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Login Card
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
                            l10n.login,
                            style: theme.textTheme.h3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.useRegisteredAccount,
                            style: theme.textTheme.muted.copyWith(fontSize: 14),
                          ),
                          
                          const SizedBox(height: 24),
                          
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.password,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.forgotPassword,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
                          
                          const SizedBox(height: 32),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
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
                                      l10n.signIn,
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
                                  l10n.orContinueWith,
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
                          
                          // Register Footer
                          Center(
                            child: TextButton(
                              onPressed: () => context.push('/register'),
                              child: Text.rich(
                                TextSpan(
                                  text: l10n.dontHaveAccount,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: l10n.signUpHere,
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

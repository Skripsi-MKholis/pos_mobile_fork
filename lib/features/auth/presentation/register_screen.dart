import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';
import 'package:pos_mobile/configuration/configuration.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.border.withValues(alpha: 0.5),
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
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Sign Up Title
                    Text(
                      currentLocale.languageCode == 'id' ? 'Buat Akun' : 'Sign up Account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 6),
                    
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        l10n.registerSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    
                    const SizedBox(height: 24),
                    
                    // Name Field Label
                    Text(
                      l10n.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: 4),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: currentLocale.languageCode == 'id'
                            ? 'Masukkan nama lengkap Anda'
                            : 'Enter your full name',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        fillColor: const Color(0xFFF3F4F6),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 10),
                    
                    // Email Field Label
                    Text(
                      l10n.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                    
                    const SizedBox(height: 4),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: currentLocale.languageCode == 'id'
                            ? 'Masukkan email Anda'
                            : 'Enter your email',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        fillColor: const Color(0xFFF3F4F6),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 10),
                    
                    // Password Field Label
                    Text(
                      l10n.password,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    
                    const SizedBox(height: 4),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: currentLocale.languageCode == 'id'
                            ? 'Masukkan kata sandi Anda'
                            : 'Enter your password',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        fillColor: const Color(0xFFF3F4F6),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            icon: Icon(
                              _obscurePassword ? TablerIcons.eye_off : TablerIcons.eye,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 10),
                    
                    // Confirm Password Field Label
                    Text(
                      l10n.confirmPassword,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                    
                    const SizedBox(height: 4),
                    
                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: currentLocale.languageCode == 'id'
                            ? 'Konfirmasi kata sandi Anda'
                            : 'Confirm your password',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        fillColor: const Color(0xFFF3F4F6),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? TablerIcons.eye_off : TablerIcons.eye,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 20),
                    
                    // Primary Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Warna.primary,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Warna.primary.withValues(alpha: 0.5),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                currentLocale.languageCode == 'id' ? 'Daftar' : 'Sign up',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                    
                    const SizedBox(height: 16),
                    
                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade200,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            currentLocale.languageCode == 'id' ? 'ATAU' : 'OR',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade200,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                    
                    const SizedBox(height: 12),
                    
                    // Google Signup Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(TablerIcons.brand_google, size: 18, color: Colors.black87),
                            const SizedBox(width: 10),
                            Text(
                              currentLocale.languageCode == 'id'
                                  ? 'Lanjutkan dengan Google'
                                  : 'Continue with Google',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 550.ms),
                    
                    const SizedBox(height: 20),
                    
                    // Footer Link
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text.rich(
                          TextSpan(
                            text: currentLocale.languageCode == 'id'
                                ? 'Sudah punya akun? '
                                : "Already have an account? ",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: currentLocale.languageCode == 'id' ? 'Masuk' : 'Sign in',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 650.ms),
                    
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating subtle language selector in top right corner
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLanguageSelector(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(TablerIcons.language, size: 16, color: Colors.black87),
                        const SizedBox(width: 8),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';
import 'package:pos_mobile/configuration/configuration.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final currentLocale = ref.read(localeNotifierProvider);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      mySnackBar(
        context: context,
        text: currentLocale.languageCode == 'id'
            ? 'Harap masukkan alamat email Anda.'
            : 'Please enter your email address.',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(email);
      if (mounted) {
        mySnackBar(
          context: context,
          text: currentLocale.languageCode == 'id'
              ? 'Tautan pemulihan kata sandi telah dikirim ke email Anda!'
              : 'Password recovery link has been sent to your email!',
          status: ToastStatus.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: currentLocale.languageCode == 'id'
              ? 'Gagal mengirim tautan: ${e.toString()}'
              : 'Failed to send link: ${e.toString()}',
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
                const SizedBox(height: 8),
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
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(
                TablerIcons.check,
                color: Colors.black87,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    // Back button at the top-left (within form view area for accessibility)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(TablerIcons.arrow_left, color: Colors.black87),
                        onPressed: () => context.pop(),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    
                    const SizedBox(height: 12),

                    // Reset Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          TablerIcons.key,
                          size: 32,
                          color: Colors.black87,
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 16),

                    // Forgot Password Title
                    Text(
                      currentLocale.languageCode == 'id' ? 'Lupa Kata Sandi' : 'Forgot Password',
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
                        currentLocale.languageCode == 'id'
                            ? 'Masukkan email Anda dan kami akan mengirimkan tautan pemulihan kata sandi.'
                            : 'Enter your email and we will send you a password recovery link.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    
                    const SizedBox(height: 24),
                    
                    // Email Field Label
                    Text(
                      currentLocale.languageCode == 'id' ? 'Alamat Email' : 'Email Address',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    
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
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 20),
                    
                    // Primary Reset Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
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
                                currentLocale.languageCode == 'id'
                                    ? 'Kirim Tautan Pemulihan'
                                    : 'Send Recovery Link',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                    
                    const SizedBox(height: 20),
                    
                    // Footer Link
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          currentLocale.languageCode == 'id'
                              ? 'Kembali ke Masuk'
                              : 'Back to Sign In',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    
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

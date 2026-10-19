import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      mySnackBar(
        context: context,
        text: isId
            ? 'Kata sandi minimal 6 karakter'
            : 'Password must be at least 6 characters',
        status: ToastStatus.error,
      );
      return;
    }

    if (password != confirmPassword) {
      mySnackBar(
        context: context,
        text: isId ? 'Kata sandi tidak cocok' : 'Passwords do not match',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;

      mySnackBar(
        context: context,
        text: isId
            ? 'Kata sandi berhasil diperbarui!'
            : 'Password updated successfully!',
        status: ToastStatus.success,
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      mySnackBar(
        context: context,
        text: isId ? 'Gagal memperbarui kata sandi: $e' : 'Failed to update password: $e',
        status: ToastStatus.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isId ? 'Ganti Kata Sandi' : 'Change Password',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Warna.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Warna.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(TablerIcons.shield_lock, size: 20, color: Colors.black),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isId ? 'Keamanan Akun' : 'Account Security',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isId
                                ? 'Masukkan kata sandi baru Anda minimal 6 karakter. Gunakan kombinasi huruf dan angka agar lebih aman.'
                                : 'Enter your new password with a minimum of 6 characters. Use a mix of letters and numbers for better security.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Form Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isId ? 'Kata Sandi Baru' : 'New Password',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: _passwordController,
                      placeholder: Text(isId ? 'Minimal 6 karakter' : 'At least 6 characters'),
                      obscureText: _obscurePassword,
                      trailing: IconButton(
                        icon: Icon(
                          _obscurePassword ? TablerIcons.eye_off : TablerIcons.eye,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: ShadDecoration(
                        color: const Color(0xFFF8F9FA),
                        border: ShadBorder.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          radius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      isId ? 'Konfirmasi Kata Sandi Baru' : 'Confirm New Password',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: _confirmPasswordController,
                      placeholder: Text(isId ? 'Ulangi kata sandi baru' : 'Repeat new password'),
                      obscureText: _obscureConfirmPassword,
                      trailing: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? TablerIcons.eye_off : TablerIcons.eye,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: ShadDecoration(
                        color: const Color(0xFFF8F9FA),
                        border: ShadBorder.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          radius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleUpdatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Warna.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(TablerIcons.check, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isId ? 'Simpan Kata Sandi' : 'Save Password',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
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
    ),
  );
}
}

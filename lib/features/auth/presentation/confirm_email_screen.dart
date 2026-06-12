import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const ConfirmEmailScreen({super.key, required this.email});

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  Timer? _resendTimer;
  int _secondsLeft = 60;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) timer.cancel();
      });
    });
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authProvider.notifier).resendConfirmationEmail(widget.email);
      if (mounted) {
        final isId = ref.read(localeNotifierProvider).languageCode == 'id';
        mySnackBar(
          context: context,
          text: isId ? 'Email konfirmasi telah dikirim ulang' : 'Confirmation email resent',
          status: ToastStatus.success,
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(context: context, text: e.toString(), status: ToastStatus.error);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isId = ref.watch(localeNotifierProvider).languageCode == 'id';

    // When user confirms email via deep link, Supabase fires signedIn.
    // The router's _RouterRefreshNotifier handles navigation automatically,
    // but we listen here to show a brief success snackbar.
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      next.whenData((state) {
        if (state.event == AuthChangeEvent.signedIn &&
            state.session?.user.emailConfirmedAt != null &&
            mounted) {
          mySnackBar(
            context: context,
            text: isId ? 'Email berhasil dikonfirmasi!' : 'Email confirmed!',
            status: ToastStatus.success,
          );
        }
      });
    });

    final canResend = _secondsLeft <= 0 && !_isResending;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(TablerIcons.arrow_left, size: 22),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const Spacer(),

              // Animated email icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(TablerIcons.mail_check, size: 46, color: Warna.primary),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.06, duration: 1400.ms, curve: Curves.easeInOut),

              const SizedBox(height: 28),

              Text(
                isId ? 'Periksa Email Anda' : 'Check Your Email',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  isId
                      ? 'Kami telah mengirimkan tautan konfirmasi ke:'
                      : 'We sent a confirmation link to:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 28),

              // Steps card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStep(
                      number: '1',
                      text: isId ? 'Buka aplikasi email Anda' : 'Open your email app',
                    ),
                    const SizedBox(height: 14),
                    _buildStep(
                      number: '2',
                      text: isId
                          ? 'Cari email dari Parzello POS'
                          : 'Find the email from Parzello POS',
                    ),
                    const SizedBox(height: 14),
                    _buildStep(
                      number: '3',
                      text: isId
                          ? 'Klik tautan "Konfirmasi Email" di dalam email'
                          : 'Click the "Confirm Email" link inside the email',
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 10),

              // Spam note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(TablerIcons.info_circle, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isId
                            ? 'Tidak menemukan email? Cek folder Spam atau Junk.'
                            : "Can't find the email? Check your Spam or Junk folder.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 280.ms),

              const Spacer(),

              // Resend button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canResend ? _handleResend : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Warna.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade100,
                    disabledForegroundColor: Colors.grey.shade400,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(TablerIcons.send, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _secondsLeft > 0
                                  ? (isId
                                      ? 'Kirim Ulang dalam ${_secondsLeft}d'
                                      : 'Resend in ${_secondsLeft}s')
                                  : (isId ? 'Kirim Ulang Email' : 'Resend Email'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 320.ms),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  isId ? 'Kembali ke Halaman Masuk' : 'Back to Sign In',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 360.ms),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: Warna.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.4),
          ),
        ),
      ],
    );
  }
}

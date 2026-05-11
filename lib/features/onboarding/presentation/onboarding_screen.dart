import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/onboarding/providers/onboarding_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Selamat Datang di Parzello POS',
      description: 'Solusi kasir modern untuk membantu mengelola bisnis Anda dengan lebih cerdas dan efisien.',
      icon: TablerIcons.device_mobile,
      color: const Color(0xFF6366F1),
    ),
    OnboardingData(
      title: 'Analitik Pintar',
      description: 'Pantau performa toko Anda secara real-time dengan laporan yang mendalam dan mudah dipahami.',
      icon: TablerIcons.chart_bar,
      color: const Color(0xFFEC4899),
    ),
    OnboardingData(
      title: 'Transaksi Cepat',
      description: 'Layani pelanggan Anda lebih cepat dengan antarmuka yang intuitif dan sistem pembayaran yang handal.',
      icon: TablerIcons.receipt,
      color: const Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: page.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        page.icon,
                        size: 100,
                        color: page.color,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                    const SizedBox(height: 48),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.h2.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, duration: 500.ms),
                    const SizedBox(height: 16),
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.muted.copyWith(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, duration: 500.ms),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _pages[_currentPage].color
                            : theme.colorScheme.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: () => _completeOnboarding(),
                        child: Text(
                          'Lewati',
                          style: TextStyle(color: theme.colorScheme.mutedForeground),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    ShadButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: 400.ms,
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      child: Text(_currentPage == _pages.length - 1 ? 'Mulai Sekarang' : 'Lanjut'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();
    if (mounted) context.go('/login');
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

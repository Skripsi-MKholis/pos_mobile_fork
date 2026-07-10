import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/onboarding/providers/onboarding_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/core/theme/colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<OnboardingData> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OnboardingData(
        title: 'Transaksi POS Cepat & Mudah',
        description: 'Proses pesanan pelanggan dalam hitungan detik dengan antarmuka yang intuitif dan sistem transaksi kasir yang andal.',
        illustration: _buildPOSIllustration(),
      ),
      OnboardingData(
        title: 'Manajemen Meja & Split Bill',
        description: 'Pantau ketersediaan meja makan secara langsung dan permudah pembagian tagihan pesanan untuk pengalaman pelanggan terbaik.',
        illustration: _buildTableIllustration(),
      ),
      OnboardingData(
        title: 'Analitik Pintar & Laporan',
        description: 'Dapatkan laporan penjualan harian secara real-time dan analisis pertumbuhan bisnis Anda dengan grafik interaktif pintar.',
        illustration: _buildAnalyticsIllustration(),
      ),
      OnboardingData(
        title: 'Integrasi Printer Bluetooth',
        description: 'Hubungkan perangkat printer struk dengan mudah melalui bluetooth untuk cetak bukti pembayaran instan.',
        illustration: _buildPrinterIllustration(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ambient radial brand glow background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    Warna.primary.withValues(alpha: 0.05),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          
          // Brand Logo Header
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Text(
                  'PARZELLO POS',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2.0,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),

          // Main Onboarding Slides
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 90.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      page.illustration,
                      const SizedBox(height: 32),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 500.ms),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1, duration: 500.ms),
                    ],
                  ),
                ),
              );
            },
          ),

          // Bottom Navigation Controls
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // Animated pill page indicator
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
                            ? Warna.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                
                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: () => _completeOnboarding(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Warna.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Mulai Sekarang' : 'Lanjut',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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

  // Visual Illustrations Builders
  Widget _buildPOSIllustration() {
    return SizedBox(
      height: 240,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Decorative Glow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Warna.primary.withValues(alpha: 0.25),
                  Warna.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
          
          // Base Tablet/Register Frame
          Positioned(
            bottom: 20,
            child: Container(
              width: 180,
              height: 125,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Warna.line, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Warna.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mock Product Rows
                  _buildMockRow(Colors.grey.shade200, 60),
                  const SizedBox(height: 6),
                  _buildMockRow(Colors.grey.shade200, 40),
                  const SizedBox(height: 6),
                  _buildMockRow(Warna.primary.withValues(alpha: 0.2), 50),
                  const Spacer(),
                  // Mock Checkout Button
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Warna.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          ),

          // Floating Cash Badge
          Positioned(
            top: 15,
            left: 35,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                TablerIcons.cash,
                color: Warna.primary,
                size: 24,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .slideY(begin: -0.1, end: 0.1, duration: 1.6.seconds, curve: Curves.easeInOut)
             .animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          ),

          // Floating Receipt Badge
          Positioned(
            top: 30,
            right: 35,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                TablerIcons.receipt,
                color: Colors.black87,
                size: 24,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .slideY(begin: 0.1, end: -0.1, duration: 1.8.seconds, curve: Curves.easeInOut)
             .animate().scale(delay: 350.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildMockRow(Color color, double width) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: width,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  Widget _buildTableIllustration() {
    return SizedBox(
      height: 240,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Decorative Glow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Warna.primary.withValues(alpha: 0.15),
                  Warna.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

          // Grid of Restaurant Tables
          Positioned(
            bottom: 20,
            child: SizedBox(
              width: 180,
              height: 110,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Table 1 (Active/Occupied - Glow & Accent)
                  Container(
                    decoration: BoxDecoration(
                      color: Warna.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Warna.primary, width: 2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(TablerIcons.users, size: 18, color: Colors.black87),
                        SizedBox(height: 2),
                        Text(
                          'Meja 01',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),

                  // Table 2 (Available/Empty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Warna.line, width: 1.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(TablerIcons.circle, size: 16, color: Colors.grey),
                        SizedBox(height: 2),
                        Text(
                          'Meja 02',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),

                  // Table 3 (Available/Empty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Warna.line, width: 1.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(TablerIcons.circle, size: 16, color: Colors.grey),
                        SizedBox(height: 2),
                        Text(
                          'Meja 03',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),

                  // Table 4 (Occupied)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Warna.line, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(TablerIcons.users, size: 16, color: Colors.grey.shade700),
                        const SizedBox(height: 2),
                        Text(
                          'Meja 04',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
                ],
              ),
            ),
          ),

          // Floating Split Bill Ticket
          Positioned(
            top: 10,
            child: Container(
              width: 130,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Warna.primary.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(TablerIcons.arrows_split_2, size: 14, color: Warna.primary),
                      const SizedBox(width: 4),
                      const Text(
                        'Bagi Tagihan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 10, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 25, height: 4, color: Colors.grey.shade300),
                      Container(width: 30, height: 4, color: Warna.primary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 30, height: 4, color: Colors.grey.shade300),
                      Container(width: 25, height: 4, color: Warna.primary),
                    ],
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .slideY(begin: -0.08, end: 0.08, duration: 2.seconds, curve: Curves.easeInOut)
             .animate().scale(delay: 500.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsIllustration() {
    return SizedBox(
      height: 240,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Warna.primary.withValues(alpha: 0.2),
                  Warna.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

          // Base Chart Container
          Positioned(
            bottom: 20,
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Warna.line, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Chart Bars
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(25, Colors.grey.shade200),
                        _buildBar(45, Colors.grey.shade200),
                        _buildBar(75, Warna.primary.withValues(alpha: 0.4)),
                        _buildBar(105, Warna.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          ),

          // Floating Trend Indicator Badge
          Positioned(
            top: 15,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Warna.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TablerIcons.trending_up,
                    color: Warna.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+45.8%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .slideY(begin: -0.05, end: 0.05, duration: 1.5.seconds, curve: Curves.easeInOut)
             .animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          ),

          // Floating Pie Mini Badge
          Positioned(
            top: 30,
            right: 25,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                TablerIcons.chart_pie,
                color: Colors.black54,
                size: 20,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .slideY(begin: 0.05, end: -0.05, duration: 1.7.seconds, curve: Curves.easeInOut)
             .animate().scale(delay: 450.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
    ).animate().scaleY(
      alignment: Alignment.bottomCenter,
      duration: 800.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildPrinterIllustration() {
    return SizedBox(
      height: 240,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Warna.primary.withValues(alpha: 0.25),
                  Warna.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

          // The printed receipt coming out of printer
          Positioned(
            top: 30,
            child: Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 4,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 35, height: 3, color: Colors.grey.shade300),
                      Container(width: 15, height: 3, color: Colors.grey.shade300),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 40, height: 3, color: Colors.grey.shade300),
                      Container(width: 12, height: 3, color: Colors.grey.shade300),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Divider(height: 4, thickness: 0.5, color: Colors.grey.shade200),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 25, height: 3, color: Colors.grey.shade400),
                      Container(width: 20, height: 3, color: Warna.primary),
                    ],
                  ),
                  const Spacer(),
                  const Icon(TablerIcons.circle_check_filled, color: Warna.primary, size: 16),
                ],
              ),
            ).animate().slideY(begin: 0.4, duration: 800.ms, delay: 200.ms, curve: Curves.easeOut).fadeIn(delay: 200.ms),
          ),

          // Base Printer Box
          Positioned(
            bottom: 20,
            child: Container(
              width: 150,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slot Line
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  // LED Light and Button details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LED Green light
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Warna.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            TablerIcons.bluetooth,
                            color: Colors.white54,
                            size: 12,
                          ),
                        ],
                      ),
                      // Feed button
                      Container(
                        width: 20,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Widget illustration;

  OnboardingData({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

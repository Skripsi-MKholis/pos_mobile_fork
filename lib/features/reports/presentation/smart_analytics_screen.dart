import 'package:flutter/material.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SmartAnalyticsScreen extends StatelessWidget {
  const SmartAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Smart Analitik',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Warna.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                TablerIcons.brain,
                size: 80,
                color: Warna.primary.withOpacity(0.5),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
             .shimmer(delay: 1.seconds, duration: 2.seconds),
            const SizedBox(height: 32),
            Text(
              'AI sedang disiapkan',
              style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 12),
            Text(
              'Fitur prediksi stok & saran penjualan berbasis AI sedang dalam tahap integrasi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 48),
            _buildFeaturePreview(
              TablerIcons.chart_arrows_vertical,
              'Prediksi Stok',
              'Tahu kapan harus belanja produk tertentu sebelum habis.',
              theme,
            ),
            const SizedBox(height: 24),
            _buildFeaturePreview(
              TablerIcons.bulb,
              'Saran Penjualan',
              'Rekomendasi promo & diskon berdasarkan tren pelanggan.',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePreview(IconData icon, String title, String desc, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

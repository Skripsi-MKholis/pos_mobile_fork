import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KONFIGURASI & AKSES CEPAT
          Text(
            'KONFIGURASI & AKSES CEPAT',
            style: theme.textTheme.muted.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickAccessGrid(context, theme),

          const SizedBox(height: 24),

          // STATS GRID
          _buildStatsGrid(context, theme),

          const SizedBox(height: 24),

          // SALES PERFORMANCE
          _buildSalesPerformanceCard(context, theme),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, ShadThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildAccessCard(
          theme,
          TablerIcons.settings_automation,
          'Modul & Fitur',
          'Sesuaikan alat POS',
          onTap: () => context.push('/settings/modules'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.cash,
          'Buka Kasir',
          'Transaksi baru',
          onTap: () => context.push('/pos'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.package,
          'Kelola Stok',
          'Input produk baru',
          backgroundColor: const Color(0xFFFF6B00), // Orange from web
          isInverse: true,
          onTap: () => context.push('/products'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.armchair,
          'Monitoring Meja',
          'Status okupansi',
          onTap: () => context.push('/tables'),
        ),
      ],
    );
  }

  Widget _buildAccessCard(
    ShadThemeData theme,
    IconData icon,
    String title,
    String subtitle, {
    Color? backgroundColor,
    bool isInverse = false,
    VoidCallback? onTap,
  }) {
    final bg = backgroundColor ?? theme.colorScheme.card;
    final textColor = isInverse ? Colors.white : theme.colorScheme.foreground;
    final subColor = isInverse
        ? Colors.white70
        : theme.colorScheme.mutedForeground;

    return ShadCard(
      padding: EdgeInsets.zero,
      backgroundColor: bg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isInverse
                          ? Colors.white24
                          : theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isInverse
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                  Icon(TablerIcons.arrow_right, size: 14, color: subColor),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
              Text(subtitle, style: TextStyle(fontSize: 10, color: subColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ShadThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          theme,
          'Total Pendapatan Hari Ini',
          'Rp 0',
          TablerIcons.wallet,
          accentColor: theme.colorScheme.primary,
        ),
        _buildStatCard(
          theme,
          'Transaksi Selesai',
          '0',
          TablerIcons.shopping_cart,
        ),
        _buildStatCard(
          theme,
          'Stok Rendah',
          '0',
          TablerIcons.package,
          accentColor: const Color(0xFFFF6B00),
        ),
        _buildStatCard(
          theme,
          'Estimasi Laba Kotor',
          'Rp 0',
          TablerIcons.chart_line,
          accentColor: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ShadThemeData theme,
    String title,
    String value,
    IconData icon, {
    Color? accentColor,
  }) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 14,
                color: accentColor ?? theme.colorScheme.mutedForeground,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor ?? theme.colorScheme.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                TablerIcons.chart_arrows_vertical,
                size: 10,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Real-time data',
                style: TextStyle(
                  fontSize: 8,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesPerformanceCard(BuildContext context, ShadThemeData theme) {
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Performance',
                    style: theme.textTheme.h4.copyWith(fontSize: 16),
                  ),
                  Text(
                    'Revenue and Order flow',
                    style: theme.textTheme.muted.copyWith(fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Last 30 days',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // CHART PLACEHOLDER
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: SimpleChartPainter(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Apr 7', 'Apr 17', 'Apr 27', 'May 5']
                .map(
                  (d) => Text(
                    d,
                    style: theme.textTheme.muted.copyWith(fontSize: 10),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final Color color;
  SimpleChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.85,
      size.width * 0.4,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.5,
      size.width * 0.7,
      size.height * 0.1,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.5,
      size.width * 0.9,
      size.height * 0.75,
    );
    path.lineTo(size.width, size.height * 0.8);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

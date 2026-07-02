import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/features/reports/providers/smart_analytics_provider.dart';

/// Daftar riwayat hasil Smart Analitik untuk toko aktif. Setiap entri adalah
/// satu kali "Segarkan Analisis" yang berhasil disimpan sebagai snapshot.
class SmartAnalyticsHistoryScreen extends ConsumerStatefulWidget {
  const SmartAnalyticsHistoryScreen({super.key});

  @override
  ConsumerState<SmartAnalyticsHistoryScreen> createState() =>
      _SmartAnalyticsHistoryScreenState();
}

class _SmartAnalyticsHistoryScreenState
    extends ConsumerState<SmartAnalyticsHistoryScreen> {
  late Future<List<SmartAnalyticsHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ref.read(smartAnalyticsProvider.notifier).fetchHistory();
  }

  Future<void> _reload() async {
    final future = ref.read(smartAnalyticsProvider.notifier).fetchHistory();
    setState(() {
      _historyFuture = future;
    });
    await future;
  }

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
          'Riwayat Analisis',
          style: theme.textTheme.h4.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          color: Warna.primary,
          child: FutureBuilder<List<SmartAnalyticsHistoryItem>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerList();
              }

              if (snapshot.hasError) {
                return _buildMessage(
                  icon: TablerIcons.alert_triangle,
                  title: 'Gagal Memuat Riwayat',
                  desc: 'Terjadi kesalahan saat mengambil riwayat analisis. Tarik untuk mencoba lagi.',
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return _buildMessage(
                  icon: TablerIcons.history,
                  title: 'Belum Ada Riwayat',
                  desc: 'Riwayat akan muncul setiap kali Anda menjalankan Segarkan Analisis di Smart Analitik.',
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildHistoryCard(context, items[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, SmartAnalyticsHistoryItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/smart-analytics/history/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Warna.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                TablerIcons.chart_infographic,
                color: Warna.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Estimasi omzet: ${item.revenueText}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.apiOnline ? Warna.success : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.apiServerLabel,
                          style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(TablerIcons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Container(
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

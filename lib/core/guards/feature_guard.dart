import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/settings/providers/subscription_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Daftar Enum Standar Fitur Aplikasi yang dapat di Lock/Unlock
enum AppFeature {
  /// Prediksi Penjualan Berbasis AI / Machine Learning (LSTM)
  smartAnalytics(
    'smart_analytics',
    'Smart AI Analytics',
    'Prediksi tren penjualan masa depan toko menggunakan model Machine Learning LSTM dan evaluasi akurasi.',
  ),

  /// Laporan Analisis Advance (Grafik Tren Penjualan & Ekspor Laporan)
  advancedReports(
    'advanced_reports',
    'Laporan Analisis Advance',
    'Grafik performa mendalam dan ekspor rekapan data penjualan toko.',
  ),

  /// Manajemen Staf & Karyawan Toko (Multi User / Kasir)
  staffManagement(
    'staff_management',
    'Manajemen Karyawan & Staf',
    'Tambah staf, atur peran (Kasir/Manajer), dan pantau kinerja tim toko Anda.',
  ),

  /// Katalog Mandiri Pelanggan (Self-Order / Menu Digital QR)
  customerCatalog(
    'customer_catalog',
    'Katalog Pelanggan Mandiri (QR)',
    'Akses layar katalog digital khusus pelanggan untuk melihat produk toko.',
  ),

  /// Bebas Iklan (Tanpa Iklan Banner)
  removeAds(
    'remove_ads',
    'Bebas Iklan',
    'Nikmati pengalaman kasir dan laporan tanpa gangguan iklan banner.',
  );

  final String key;
  final String label;
  final String description;

  const AppFeature(this.key, this.label, this.description);
}

/// Provider pembantu untuk mengecek apakah fitur tertentu bisa diakses toko aktif
final canAccessFeatureProvider = Provider.family<bool, AppFeature>((ref, feature) {
  final currentSubAsync = ref.watch(currentSubscriptionProvider);
  final subInfo = currentSubAsync.value;
  if (subInfo == null) return false;

  return subInfo.canAccess(feature.key);
});

/// Reusable Widget Guard: Jika terkunci, menampilkan tampilan/badge terkunci
class FeatureGate extends ConsumerWidget {
  final AppFeature feature;
  final Widget child;
  final Widget? lockedPlaceholder;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedPlaceholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = ref.watch(canAccessFeatureProvider(feature));

    if (canAccess) {
      return child;
    }

    return lockedPlaceholder ?? _DefaultLockedCard(feature: feature);
  }
}

/// Modal Dialog ajakan Upgrade ketika user menekan fitur yang terkunci
void showFeatureLockedDialog(BuildContext context, AppFeature feature) {
  showShadDialog(
    context: context,
    builder: (dialogContext) => ShadDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Warna.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.crown, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Fitur Eksklusif PRO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      description: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fitur "${feature.label}" saat ini terkunci di paket Anda.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              feature.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: const Row(
                children: [
                  Icon(TablerIcons.sparkles, size: 16, color: Colors.black87),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade ke paket UMKM Hebat atau Bisnis Skalabel untuk membuka fitur ini.',
                      style: TextStyle(fontSize: 11.5, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Nanti Saja'),
        ),
        ShadButton(
          backgroundColor: Warna.primary,
          foregroundColor: Colors.black,
          onPressed: () {
            Navigator.pop(dialogContext);
            context.push('/subscription-plans');
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(TablerIcons.crown, size: 16),
              SizedBox(width: 6),
              Text('Lihat Pilihan Paket'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DefaultLockedCard extends StatelessWidget {
  final AppFeature feature;
  const _DefaultLockedCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.lock, color: Colors.amber, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            feature.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            feature.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => showFeatureLockedDialog(context, feature),
            icon: const Icon(TablerIcons.crown, size: 18),
            label: const Text('Buka Fitur dengan PRO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Warna.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

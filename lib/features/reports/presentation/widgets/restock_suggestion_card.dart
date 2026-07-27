import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/recommendation_style.dart';
import 'package:pos_mobile/features/reports/providers/forecast_provider.dart';
import 'package:pos_mobile/features/reports/providers/stock_forecast_provider.dart';

/// Kartu "Saran Belanja Minggu Ini" di layar Manajemen Stok (§8.3).
///
/// Menyarankan jumlah pembelian dari prediksi permintaan, tetapi **tidak
/// pernah mengubah stok sendiri** — menekan sebuah baris hanya membuka form
/// penyesuaian stok yang sudah ada, dengan angka saran sebagai nilai awal.
class RestockSuggestionCard extends ConsumerStatefulWidget {
  /// Dipanggil saat pengguna memilih sebuah saran; pemanggil membuka form
  /// edit stok dengan [suggestedStock] sebagai nilai awal.
  final void Function(Product product, int suggestedStock) onApply;

  const RestockSuggestionCard({super.key, required this.onApply});

  @override
  ConsumerState<RestockSuggestionCard> createState() =>
      _RestockSuggestionCardState();
}

class _RestockSuggestionCardState extends ConsumerState<RestockSuggestionCard> {
  bool _expanded = false;

  static const int _collapsedCount = 3;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(forecastProvider).valueOrNull;
    final suggestions = ref.watch(restockSuggestionsProvider);

    if (summary == null || suggestions.isEmpty) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final visible = _expanded
        ? suggestions
        : suggestions.take(_collapsedCount).toList();
    final modeStyle = ForecastModeStyle.of(summary.mode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  TablerIcons.shopping_cart_plus,
                  size: 15,
                  color: Warna.black,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saran Belanja Minggu Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${suggestions.length} produk diproyeksikan kurang',
                      style: theme.textTheme.muted.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Icon(modeStyle.icon, size: 12, color: modeStyle.color),
              const SizedBox(width: 4),
              Text(
                summary.mode.shortLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: modeStyle.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in visible) _buildRow(item, theme),
          if (suggestions.length > _collapsedCount)
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? 'Tampilkan lebih sedikit'
                      : 'Lihat semua (${suggestions.length})',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          if (summary.isStale)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Prediksi dibuat ${summary.age.inHours} jam lalu — segarkan di '
                'Smart Analitik untuk saran yang lebih mutakhir.',
                style: TextStyle(
                  fontSize: 9.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(StockForecast item, ShadThemeData theme) {
    final urgency = item.urgency;
    final targetStock = item.product.stockQuantity + item.recommendedPurchase;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: urgency.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Stok ${item.product.stockQuantity} • '
                  '${urgency.label(item.daysOfStockLeft)}',
                  style: theme.textTheme.muted.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${item.recommendedPurchase}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                'unit',
                style: theme.textTheme.muted.copyWith(fontSize: 9),
              ),
            ],
          ),
          const SizedBox(width: 10),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () => widget.onApply(item.product, targetStock),
            child: const Text('Isi', style: TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

/// Badge kecil "habis dalam N hari" untuk baris produk.
class StockForecastBadge extends ConsumerWidget {
  final String productSupabaseId;

  const StockForecastBadge({super.key, required this.productSupabaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(stockForecastProvider)[productSupabaseId];
    if (forecast == null) return const SizedBox.shrink();

    final urgency = forecast.urgency;
    if (urgency == StockUrgency.unknown) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgency.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.clock_exclamation, size: 11, color: urgency.color),
          const SizedBox(width: 4),
          Text(
            urgency.label(forecast.daysOfStockLeft),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: urgency.color,
            ),
          ),
        ],
      ),
    );
  }
}

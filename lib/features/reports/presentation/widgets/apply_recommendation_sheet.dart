import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/reports/data/recommendation_action_service.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';

/// Lembar konfirmasi sebelum sebuah rekomendasi harga benar-benar dijadikan
/// voucher (T-12).
///
/// Menampilkan produk sasaran, besar diskon, masa berlaku, dan hasil
/// pemeriksaan margin. Pembuatan voucher **selalu** butuh konfirmasi manual —
/// model tidak pernah mengubah harga sendiri.
class ApplyRecommendationSheet extends StatefulWidget {
  final ForecastRecommendation recommendation;
  final String storeId;
  final String? snapshotId;

  const ApplyRecommendationSheet({
    super.key,
    required this.recommendation,
    required this.storeId,
    this.snapshotId,
  });

  static Future<AppliedVoucher?> show(
    BuildContext context, {
    required ForecastRecommendation recommendation,
    required String storeId,
    String? snapshotId,
  }) {
    return showModalBottomSheet<AppliedVoucher>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApplyRecommendationSheet(
        recommendation: recommendation,
        storeId: storeId,
        snapshotId: snapshotId,
      ),
    );
  }

  @override
  State<ApplyRecommendationSheet> createState() =>
      _ApplyRecommendationSheetState();
}

class _ApplyRecommendationSheetState extends State<ApplyRecommendationSheet> {
  final _service = RecommendationActionService();

  late double _percent;
  int _validDays = 7;
  MarginCheck? _margin;
  bool _checking = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final suggested =
        (widget.recommendation.payload['discount_percent'] as num?)
            ?.toDouble() ??
        10;
    _percent = suggested.clamp(1, 90);
    _runMarginCheck();
  }

  List<String> get _targetProductIds {
    final raw = widget.recommendation.payload['product_ids'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  Future<void> _runMarginCheck() async {
    setState(() => _checking = true);
    final result = await _service.checkMargin(
      storeId: widget.storeId,
      discountPercent: _percent,
      productIds: _targetProductIds,
    );
    if (!mounted) return;
    setState(() {
      _margin = result;
      _checking = false;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final voucher = await _service.createDiscountVoucher(
        storeId: widget.storeId,
        discountPercent: _percent,
        description: widget.recommendation.title,
        snapshotId: widget.snapshotId,
        validFor: Duration(days: _validDays),
      );
      if (!mounted) return;
      Navigator.of(context).pop(voucher);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Gagal membuat voucher: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final margin = _margin;
    final blocked = margin != null && !margin.allowed;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.recommendation.title,
            style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Rekomendasi ini akan dibuat sebagai voucher diskon baru. '
            'Harga produk tidak diubah.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 18),

          _label('Besar diskon'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _percent,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: Warna.primary,
                  label: '${_percent.round()}%',
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _percent = v),
                  onChangeEnd: (_) => _runMarginCheck(),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${_percent.round()}%',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _label('Masa berlaku'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [1, 3, 7, 14, 30].map((days) {
              final selected = _validDays == days;
              return ChoiceChip(
                label: Text('$days hari', style: const TextStyle(fontSize: 11)),
                selected: selected,
                selectedColor: Warna.primary.withOpacity(0.2),
                onSelected: _submitting
                    ? null
                    : (_) => setState(() => _validDays = days),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          if (_checking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Memeriksa margin…', style: TextStyle(fontSize: 11)),
                ],
              ),
            )
          else if (margin != null)
            _marginBanner(margin),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ShadButton(
                  backgroundColor: Warna.primary,
                  foregroundColor: Warna.black,
                  onPressed: (_submitting || blocked || _checking)
                      ? null
                      : _submit,
                  child: Text(
                    _submitting ? 'Membuat…' : 'Buat Voucher',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade700,
    ),
  );

  Widget _marginBanner(MarginCheck margin) {
    final blocked = !margin.allowed;
    final color = blocked ? const Color(0xFFDC2626) : Warna.success;
    final maxSafe = margin.maxSafePercent;

    final messages = <String>[];
    if (blocked) {
      messages.add(
        'Diskon ${_percent.round()}% membuat "${margin.blockingProduct}" '
        'terjual di bawah batas margin aman.',
      );
      if (maxSafe != null) {
        messages.add('Diskon maksimum yang aman: ${maxSafe.floor()}%.');
      }
    } else {
      messages.add('Margin masih aman pada diskon ${_percent.round()}%.');
      if (maxSafe != null) {
        messages.add('Batas aman: ${maxSafe.floor()}%.');
      }
    }
    if (margin.unknownCostCount > 0) {
      messages.add(
        '${margin.unknownCostCount} produk belum punya harga modal sehingga '
        'tidak ikut dinilai.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            blocked ? TablerIcons.alert_triangle : TablerIcons.shield_check,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              messages.join(' '),
              style: TextStyle(fontSize: 10.5, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Format tanggal kadaluarsa untuk pesan sukses.
String formatVoucherExpiry(DateTime date) =>
    DateFormat('dd MMM yyyy').format(date);

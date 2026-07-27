import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/product.dart';

/// Hasil pemeriksaan margin sebelum diskon diterapkan.
class MarginCheck {
  final bool allowed;

  /// Produk dengan margin paling tipis pada diskon yang diminta.
  final String? blockingProduct;

  /// Diskon maksimum (persen) yang masih aman untuk seluruh produk sasaran.
  final double? maxSafePercent;

  /// Produk yang harga modalnya belum diisi sehingga tidak bisa dievaluasi.
  final int unknownCostCount;

  const MarginCheck({
    required this.allowed,
    this.blockingProduct,
    this.maxSafePercent,
    this.unknownCostCount = 0,
  });
}

/// Voucher yang berhasil dibuat dari sebuah rekomendasi.
class AppliedVoucher {
  final String id;
  final String code;
  final double percent;
  final DateTime expiresAt;

  const AppliedVoucher({
    required this.id,
    required this.code,
    required this.percent,
    required this.expiresAt,
  });
}

/// Mengubah rekomendasi model menjadi tindakan nyata di aplikasi.
///
/// Sebelumnya tombol "Terapkan" hanya memunculkan snackbar (T-12). Sekarang
/// tombol itu benar-benar membuat baris `vouchers`, dengan penjagaan margin
/// agar diskon yang disarankan tidak membuat toko menjual di bawah biaya.
class RecommendationActionService {
  final SupabaseClient _client;

  RecommendationActionService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Margin minimum yang harus tersisa di atas harga modal (10%).
  static const double minMarginMultiplier = 1.1;

  /// Memeriksa apakah diskon [discountPercent] masih menyisakan margin sehat
  /// untuk seluruh produk sasaran.
  ///
  /// Produk tanpa harga modal tidak bisa dinilai dan dihitung terpisah lewat
  /// [MarginCheck.unknownCostCount] — bukan dianggap aman diam-diam.
  Future<MarginCheck> checkMargin({
    required String storeId,
    required double discountPercent,
    List<String>? productIds,
  }) async {
    final products = await _loadProducts(storeId, productIds);
    if (products.isEmpty) {
      return const MarginCheck(allowed: true);
    }

    String? blocking;
    double? maxSafe;
    var unknownCost = 0;

    for (final product in products) {
      final cost = product.modalPrice ?? 0;
      if (cost <= 0) {
        unknownCost++;
        continue;
      }
      if (product.price <= 0) continue;

      final floor = cost * minMarginMultiplier;
      final safePercent = (1 - (floor / product.price)) * 100;
      maxSafe = maxSafe == null ? safePercent : math.min(maxSafe, safePercent);

      final discounted = product.price * (1 - discountPercent / 100);
      if (discounted < floor) {
        blocking ??= product.name;
      }
    }

    return MarginCheck(
      allowed: blocking == null,
      blockingProduct: blocking,
      maxSafePercent: maxSafe == null ? null : math.max(0, maxSafe),
      unknownCostCount: unknownCost,
    );
  }

  Future<List<Product>> _loadProducts(
    String storeId,
    List<String>? productIds,
  ) async {
    try {
      final isar = IsarService.instance;
      final all = await isar
          .collection<Product>()
          .filter()
          .storeIdEqualTo(storeId)
          .findAll();
      final active = all.where((p) => !p.isDeleted).toList();
      if (productIds == null || productIds.isEmpty) return active;
      final wanted = productIds.toSet();
      return active.where((p) => wanted.contains(p.supabaseId)).toList();
    } catch (e) {
      debugPrint('DEBUG: Gagal memuat produk untuk cek margin: $e');
      return const [];
    }
  }

  /// Membuat voucher dari rekomendasi harga.
  ///
  /// [snapshotId] dicatat pada deskripsi agar dampak rekomendasi bisa
  /// ditelusuri kembali ke analisis yang melahirkannya.
  Future<AppliedVoucher> createDiscountVoucher({
    required String storeId,
    required double discountPercent,
    required String description,
    String? snapshotId,
    Duration validFor = const Duration(days: 7),
    double minPurchase = 0,
    double? maxDiscount,
    int? usageLimit,
  }) async {
    final code = _generateCode();
    final expiresAt = DateTime.now().add(validFor);

    final payload = {
      'store_id': storeId,
      'code': code,
      'description': snapshotId == null
          ? description
          : '$description (dari analisis $snapshotId)',
      'type': 'percentage',
      'value': discountPercent,
      'min_purchase': minPurchase,
      if (maxDiscount != null) 'max_discount': maxDiscount,
      if (usageLimit != null) 'usage_limit': usageLimit,
      'starts_at': DateTime.now().toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'is_active': true,
    };

    final inserted = await _client
        .from('vouchers')
        .insert(payload)
        .select()
        .single();

    return AppliedVoucher(
      id: inserted['id'].toString(),
      code: inserted['code'].toString(),
      percent: discountPercent,
      expiresAt: expiresAt,
    );
  }

  /// Kode voucher pendek yang mudah diketik kasir.
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random.secure();
    final suffix = List.generate(
      4,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'AI$suffix';
  }
}

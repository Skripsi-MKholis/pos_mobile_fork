import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/settings/models/subscription_model.dart';

/// Mengambil daftar paket langganan dari tabel `subscription_plans` di Supabase
final availablePlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('subscription_plans')
        .select('*, plan_features(*)')
        .order('price', ascending: true);

    return (response as List)
        .map((json) {
          final data = Map<String, dynamic>.from(json as Map);
          if (data['plan_features'] is List) {
            final list = List<Map<String, dynamic>>.from(data['plan_features'] as List);
            list.sort((a, b) => ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0));
            data['plan_features'] = list;
          }
          return SubscriptionPlan.fromJson(data);
        })
        .toList();
  } catch (e) {
    // Fallback static jika offline / gagal load
    return const [
      SubscriptionPlan(
        id: 'b29dcf1a-4c25-4abc-9e98-d562746e0294',
        slug: 'lite',
        name: 'Lite (UMKM Pemula)',
        tagline: 'Solusi dasar untuk memulai bisnis digital.',
        price: 0,
        period: 'Gratis',
        googlePlayProductId: 'com.posmobile.subscription.lite',
        features: [
          'Maksimal 500 transaksi/bulan',
          'Laporan penjualan standar',
          'Manajemen meja & reservasi',
        ],
      ),
      SubscriptionPlan(
        id: '99a67ea8-11e8-4e7b-83f3-fb8164081564',
        slug: 'umkm-hebat',
        name: 'UMKM Hebat',
        tagline: 'Fitur lengkap dengan harga paling bersahabat.',
        price: 19000,
        period: '/bulan',
        googlePlayProductId: 'com.posmobile.subscription.umkm-hebat',
        features: [
          'Transaksi Tanpa Batas (Unlimited)',
          'Dukungan hingga 2 cabang/outlet',
          'Analisis & Laporan advance (Excel/PDF)',
          'Kitchen Display System (KDS)',
          'Manajemen data pelanggan & loyalty',
          'Diskon, promo & voucher',
        ],
        isPopular: true,
      ),
      SubscriptionPlan(
        id: '78e47e8a-a4e2-459f-a4de-eae52e7f75cb',
        slug: 'bisnis-skalabel',
        name: 'Bisnis Skalabel',
        tagline: 'Untuk rantai bisnis yang siap ekspansi.',
        price: 49000,
        period: '/bulan',
        googlePlayProductId: 'com.posmobile.subscription.bisnis-skalabel',
        features: [
          'Transaksi Tanpa Batas (Unlimited)',
          'Dukungan hingga 5 cabang/outlet',
          'Manajemen multi-cabang & staff',
          'Kitchen Display System (KDS)',
          'Laporan & analitik real-time',
        ],
      ),
    ];
  }
});

/// Mengambil status subscription aktif toko saat ini dari tabel `subscriptions`
final currentSubscriptionProvider = FutureProvider<UserSubscriptionInfo>((ref) async {
  final activeStore = ref.watch(activeStoreProvider).value;
  if (activeStore == null || activeStore['id'] == null) {
    return const UserSubscriptionInfo(
      planId: 'lite',
      planName: 'Lite (UMKM Pemula)',
      status: 'free',
      expiresAt: null,
      autoRenew: false,
    );
  }

  final storeId = activeStore['id'];

  try {
    final response = await Supabase.instance.client
        .from('subscriptions')
        .select('*, subscription_plans(*)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return UserSubscriptionInfo.fromJson(response);
    }
  } catch (e) {
    // Abaikan error jaringan dan fallback ke default
  }

  return const UserSubscriptionInfo(
    planId: 'lite',
    planName: 'Lite (UMKM Pemula)',
    status: 'free',
    expiresAt: null,
    autoRenew: false,
  );
});

/// Mengambil histori transaksi pembayaran subscription toko dari tabel `subscription_history`
final subscriptionTransactionsProvider = FutureProvider<List<SubscriptionTransaction>>((ref) async {
  final activeStore = ref.watch(activeStoreProvider).value;
  if (activeStore == null || activeStore['id'] == null) {
    return [];
  }

  final storeId = activeStore['id'];

  try {
    final response = await Supabase.instance.client
        .from('subscription_history')
        .select('*, subscription_plans(*)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SubscriptionTransaction.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Menghitung jumlah transaksi toko pada bulan kalender berjalan (untuk pengecekan kuota)
final monthlyTransactionCountProvider = FutureProvider<int>((ref) async {
  final activeStore = ref.watch(activeStoreProvider).value;
  if (activeStore == null || activeStore['id'] == null) {
    return 0;
  }

  final storeId = activeStore['id'];
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).toUtc().toIso8601String();

  try {
    final response = await Supabase.instance.client
        .from('transactions')
        .select('id')
        .eq('store_id', storeId)
        .gte('created_at', startOfMonth);

    return (response as List).length;
  } catch (e) {
    return 0;
  }
});

/// Notifier/Service untuk memproses upgrade langganan toko ke Supabase
final subscriptionActionProvider = Provider((ref) => SubscriptionActionService(ref));

class SubscriptionActionService {
  final Ref _ref;
  SubscriptionActionService(this._ref);

  Future<void> purchasePlan({
    required SubscriptionPlan plan,
    required String paymentMethod,
    String? orderId,
    String? purchaseToken,
  }) async {
    final activeStore = _ref.read(activeStoreProvider).value;
    if (activeStore == null || activeStore['id'] == null) {
      throw Exception('Toko aktif tidak ditemukan');
    }

    final storeId = activeStore['id'] as String;
    final now = DateTime.now();
    // Jika durationDays > 0, hitung tanggal akhir, jika 0 (lifetime/free) set null
    final DateTime? endDate = plan.durationDays > 0
        ? now.add(Duration(days: plan.durationDays))
        : null;
    final client = Supabase.instance.client;

    final finalOrderId = orderId ?? 'GPA.${now.millisecondsSinceEpoch.toString().substring(0, 12)}';

    // 1. Simpan riwayat transaksi ke `subscription_history`
    await client.from('subscription_history').insert({
      'store_id': storeId,
      'plan_id': plan.id,
      'amount': plan.price,
      'status': 'success',
      'payload': {
        'order_id': finalOrderId,
        'plan_name': plan.name,
        'plan_slug': plan.slug,
        'duration_days': plan.durationDays,
        'billing_period': plan.billingPeriod,
        'payment_method': paymentMethod,
        'purchase_token': ?purchaseToken,
      },
    }).select().single();

    // 2. Update atau Insert data langganan toko di tabel `subscriptions`
    final existingSub = await client
        .from('subscriptions')
        .select('id')
        .eq('store_id', storeId)
        .maybeSingle();

    if (existingSub != null) {
      await client.from('subscriptions').update({
        'plan_id': plan.id,
        'status': 'active',
        'start_date': now.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', existingSub['id']);
    } else {
      await client.from('subscriptions').insert({
        'store_id': storeId,
        'plan_id': plan.id,
        'status': 'active',
        'start_date': now.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
    }

    // Refresh provider agar UI terupdate real-time
    _ref.invalidate(currentSubscriptionProvider);
    _ref.invalidate(subscriptionTransactionsProvider);
  }
}

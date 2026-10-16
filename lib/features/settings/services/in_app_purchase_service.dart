import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pos_mobile/features/settings/models/subscription_model.dart';
import 'package:pos_mobile/features/settings/providers/subscription_provider.dart';

/// Provider singleton untuk InAppPurchaseService
final inAppPurchaseServiceProvider = Provider<InAppPurchaseService>((ref) {
  final service = InAppPurchaseService(ref);
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State produk In-App Purchase yang berhasil diambil dari Google Play
final googlePlayProductsProvider =
    StateNotifierProvider<GooglePlayProductsNotifier, AsyncValue<List<ProductDetails>>>((ref) {
  return GooglePlayProductsNotifier(ref);
});

class GooglePlayProductsNotifier extends StateNotifier<AsyncValue<List<ProductDetails>>> {
  final Ref _ref;

  GooglePlayProductsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final iapService = _ref.read(inAppPurchaseServiceProvider);
      final products = await iapService.fetchSubscriptionProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class InAppPurchaseService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;

  InAppPurchaseService(this._ref);

  bool get isAvailable => _isAvailable;

  Future<bool> isStoreAvailable() async {
    _isAvailable = await _iap.isAvailable();
    return _isAvailable;
  }

  void initialize() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('[IAP] Purchase stream error: $error');
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Memeriksa ketersediaan Google Play Billing & mengambil produk langganan
  Future<List<ProductDetails>> fetchSubscriptionProducts() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('[IAP] Store is not available (running in simulator or Google Play not configured)');
      return [];
    }

    // Ambil semua Google Play Product ID dari daftar paket
    final plansAsync = await _ref.read(availablePlansProvider.future);
    final productIds = plansAsync
        .where((p) => p.price > 0 && p.googlePlayProductId.isNotEmpty)
        .map((p) => p.googlePlayProductId)
        .toSet();

    if (productIds.isEmpty) return [];

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('[IAP] Error querying products: ${response.error!.message}');
      return [];
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IAP] Products not found in Play Console: ${response.notFoundIDs}');
    }

    return response.productDetails;
  }

  /// Memulai alur pembelian native Google Play
  Future<bool> buySubscription(SubscriptionPlan plan) async {
    final isStoreAvailable = await _iap.isAvailable();
    if (!isStoreAvailable) {
      throw Exception('Layanan Google Play Store tidak tersedia di perangkat ini.');
    }

    final products = await fetchSubscriptionProducts();
    final productDetails = products.where((p) => p.id == plan.googlePlayProductId).firstOrNull;

    if (productDetails == null) {
      // Jika produk belum aktif di Play Console (misal saat tahap development),
      // kita berikan fallback atau lempar notifikasi informatif
      throw Exception(
        'Produk langganan (${plan.googlePlayProductId}) belum dipublikasikan atau belum aktif di Google Play Console.',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: productDetails);
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Memulihkan pembelian sebelumnya (Restore Purchases)
  Future<void> restorePurchases() async {
    final isStoreAvailable = await _iap.isAvailable();
    if (!isStoreAvailable) {
      throw Exception('Layanan Google Play Store tidak tersedia.');
    }
    await _iap.restorePurchases();
  }

  /// Handler saat ada transaksi yang masuk melalui stream
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('[IAP] Purchase pending for ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          debugPrint('[IAP] Purchase successful/restored for ${purchaseDetails.productID}');
          await _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          debugPrint('[IAP] Purchase error: ${purchaseDetails.error?.message}');
          break;

        case PurchaseStatus.canceled:
          debugPrint('[IAP] Purchase canceled by user');
          break;
      }

      // Wajib selesaikan transaksi (Acknowledge) agar Google Play tidak membatalkan/refund
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Memproses verifikasi dan pencatatan transaksi ke Supabase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final plans = await _ref.read(availablePlansProvider.future);
      final matchedPlan = plans.where((p) => p.googlePlayProductId == purchaseDetails.productID).firstOrNull;

      if (matchedPlan == null) {
        debugPrint('[IAP] Matched plan not found for ${purchaseDetails.productID}');
        return;
      }

      // Simpan transaksi pembelian ke Supabase
      await _ref.read(subscriptionActionProvider).purchasePlan(
        plan: matchedPlan,
        paymentMethod: 'Google Play Billing',
        orderId: purchaseDetails.purchaseID,
        purchaseToken: purchaseDetails.verificationData.serverVerificationData,
      );
    } catch (e) {
      debugPrint('[IAP] Error processing purchase on server: $e');
    }
  }
}

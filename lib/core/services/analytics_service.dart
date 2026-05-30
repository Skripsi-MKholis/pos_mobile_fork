import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Mencatat layar aktif secara manual jika diperlukan
  Future<void> logScreenView({required String screenName}) async {
    if (kDebugMode) {
      print('Analytics: Screen View -> $screenName');
    }
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logScreenView): $e');
      }
    }
  }

  /// Mencatat event Login
  Future<void> logLogin({required String method}) async {
    if (kDebugMode) {
      print('Analytics: Event -> login (method: $method)');
    }
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logLogin): $e');
      }
    }
  }

  /// Mencatat event Register / Sign Up
  Future<void> logSignUp({required String method}) async {
    if (kDebugMode) {
      print('Analytics: Event -> sign_up (method: $method)');
    }
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logSignUp): $e');
      }
    }
  }

  /// Mencatat event Pemilihan Toko
  Future<void> logStoreSelection({required String storeId, required String storeName}) async {
    if (kDebugMode) {
      print('Analytics: Event -> select_store (id: $storeId, name: $storeName)');
    }
    try {
      await _analytics.logEvent(
        name: 'select_store',
        parameters: {
          'store_id': storeId,
          'store_name': storeName,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logStoreSelection): $e');
      }
    }
  }

  /// Mencatat event Pembuatan Toko Baru
  Future<void> logStoreCreation({required String storeName, required String businessType}) async {
    if (kDebugMode) {
      print('Analytics: Event -> create_store (name: $storeName, type: $businessType)');
    }
    try {
      await _analytics.logEvent(
        name: 'create_store',
        parameters: {
          'store_name': storeName,
          'business_type': businessType,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logStoreCreation): $e');
      }
    }
  }

  /// Mencatat event Transaksi Sukses (Purchase)
  Future<void> logPurchase({
    required String transactionId,
    required double totalAmount,
    required String paymentMethod,
    required int itemCount,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> purchase (id: $transactionId, total: $totalAmount, method: $paymentMethod, items: $itemCount)');
    }
    try {
      // Menggunakan standar logging e-commerce Firebase
      await _analytics.logPurchase(
        transactionId: transactionId,
        value: totalAmount,
        currency: 'IDR',
        parameters: {
          'payment_method': paymentMethod,
          'item_count': itemCount,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logPurchase): $e');
      }
    }
  }

  /// Mencatat event Kalibrasi AI Smart Analytics
  Future<void> logAICalibration({required String storeId}) async {
    if (kDebugMode) {
      print('Analytics: Event -> ai_calibration (store_id: $storeId)');
    }
    try {
      await _analytics.logEvent(
        name: 'ai_calibration',
        parameters: {
          'store_id': storeId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logAICalibration): $e');
      }
    }
  }

  /// Mencatat event Pembuatan Produk Baru
  Future<void> logProductCreation({
    required String categoryName,
    required double price,
    required bool hasImage,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> create_product (category: $categoryName, price: $price, hasImage: $hasImage)');
    }
    try {
      await _analytics.logEvent(
        name: 'create_product',
        parameters: {
          'category_name': categoryName,
          'price': price,
          'has_image': hasImage ? 1 : 0,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logProductCreation): $e');
      }
    }
  }

  /// Mencatat event Pembaruan Produk
  Future<void> logProductUpdate({
    required bool priceChanged,
    required bool stockChanged,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> update_product (priceChanged: $priceChanged, stockChanged: $stockChanged)');
    }
    try {
      await _analytics.logEvent(
        name: 'update_product',
        parameters: {
          'price_changed': priceChanged ? 1 : 0,
          'stock_changed': stockChanged ? 1 : 0,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logProductUpdate): $e');
      }
    }
  }

  /// Mencatat event Penghapusan Produk
  Future<void> logProductDeletion({required String categoryName}) async {
    if (kDebugMode) {
      print('Analytics: Event -> delete_product (category: $categoryName)');
    }
    try {
      await _analytics.logEvent(
        name: 'delete_product',
        parameters: {
          'category_name': categoryName,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logProductDeletion): $e');
      }
    }
  }

  /// Mencatat event Pembuatan Kategori Baru
  Future<void> logCategoryCreation({required String categoryName}) async {
    if (kDebugMode) {
      print('Analytics: Event -> create_category (name: $categoryName)');
    }
    try {
      await _analytics.logEvent(
        name: 'create_category',
        parameters: {
          'category_name': categoryName,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logCategoryCreation): $e');
      }
    }
  }

  /// Mencatat event Penyesuaian Stok
  Future<void> logStockAdjustment({
    required String productName,
    required String adjustmentType,
    required double quantity,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> adjust_stock (name: $productName, type: $adjustmentType, qty: $quantity)');
    }
    try {
      await _analytics.logEvent(
        name: 'adjust_stock',
        parameters: {
          'product_name': productName,
          'adjustment_type': adjustmentType,
          'quantity': quantity,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logStockAdjustment): $e');
      }
    }
  }

  /// Mencatat pemakaian voucher belanja
  Future<void> logApplyVoucher({
    required String voucherCode,
    required double discountAmount,
    required String voucherType,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> apply_voucher (code: $voucherCode, amount: $discountAmount, type: $voucherType)');
    }
    try {
      await _analytics.logEvent(
        name: 'apply_voucher',
        parameters: {
          'voucher_code': voucherCode,
          'discount_amount': discountAmount,
          'voucher_type': voucherType,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logApplyVoucher): $e');
      }
    }
  }

  /// Mencatat pemakaian diskon manual
  Future<void> logApplyDiscount({
    required String discountType,
    required double amount,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> apply_discount (type: $discountType, amount: $amount)');
    }
    try {
      await _analytics.logEvent(
        name: 'apply_discount',
        parameters: {
          'discount_type': discountType,
          'amount': amount,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logApplyDiscount): $e');
      }
    }
  }

  /// Mencatat pemisahan tagihan (split bill)
  Future<void> logSplitBill({
    required String tableNumber,
    required double originalAmount,
    required int splitCount,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> split_bill (table: $tableNumber, originalAmount: $originalAmount, splitCount: $splitCount)');
    }
    try {
      await _analytics.logEvent(
        name: 'split_bill',
        parameters: {
          'table_number': tableNumber,
          'original_amount': originalAmount,
          'split_count': splitCount,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logSplitBill): $e');
      }
    }
  }

  /// Mencatat cetak struk belanja
  Future<void> logPrintReceipt({
    required String printerConnection,
    required bool isReprint,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> print_receipt (connection: $printerConnection, isReprint: $isReprint)');
    }
    try {
      await _analytics.logEvent(
        name: 'print_receipt',
        parameters: {
          'printer_connection': printerConnection,
          'is_reprint': isReprint ? 1 : 0,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logPrintReceipt): $e');
      }
    }
  }

  /// Mencatat pembukaan pemantauan meja aktif
  Future<void> logTableMonitoringView({
    required int activeTablesCount,
    required int waitingOrdersCount,
  }) async {
    if (kDebugMode) {
      print('Analytics: Event -> table_monitoring_view (activeTables: $activeTablesCount, waitingOrders: $waitingOrdersCount)');
    }
    try {
      await _analytics.logEvent(
        name: 'table_monitoring_view',
        parameters: {
          'active_tables_count': activeTablesCount,
          'waiting_orders_count': waitingOrdersCount,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (logTableMonitoringView): $e');
      }
    }
  }

  /// Identifikasi User ID untuk debugging/user tracking yang spesifik
  Future<void> setUserId(String? userId) async {
    if (kDebugMode) {
      print('Analytics: Set User ID -> $userId');
    }
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error (setUserId): $e');
      }
    }
  }
}

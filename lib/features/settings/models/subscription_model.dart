class SubscriptionPlan {
  final String id;
  final String slug;
  final String name;
  final String tagline;
  final int price;
  final String period; // '/bulan'
  final String googlePlayProductId;
  final List<String> features;
  final int durationDays; // 0 = lifetime/free, 30 = bulanan, 365 = tahunan
  final String billingPeriod; // 'lifetime', 'monthly', 'yearly'
  final int maxOutlets;
  final int maxTransactions;
  final bool isPopular;
  final bool isCurrent;

  const SubscriptionPlan({
    required this.id,
    required this.slug,
    required this.name,
    required this.tagline,
    required this.price,
    required this.period,
    required this.googlePlayProductId,
    required this.features,
    this.durationDays = 30,
    this.billingPeriod = 'monthly',
    this.maxOutlets = 1,
    this.maxTransactions = 0,
    this.isPopular = false,
    this.isCurrent = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    List<String> featureList = [];

    // 1. Ambil dari relasi tabel plan_features jika ada
    final rawPlanFeatures = json['plan_features'];
    if (rawPlanFeatures is List && rawPlanFeatures.isNotEmpty) {
      for (final item in rawPlanFeatures) {
        if (item is Map<String, dynamic> && item['title'] != null) {
          featureList.add(item['title'] as String);
        } else if (item is String) {
          featureList.add(item);
        }
      }
    }

    // 2. Fallback ke kolom JSONB features jika tabel plan_features belum/tidak di-join
    if (featureList.isEmpty) {
      final rawFeatures = json['features'];
      if (rawFeatures is Map<String, dynamic>) {
        // Fitur Smart Analytics disembunyikan sementara dari penawaran paket
        // if (rawFeatures['smart_analytics'] == true) {
        //   featureList.add('Smart Analytics & Prediksi AI Penjualan (LSTM)');
        // }
        if (rawFeatures['advanced_reports'] == true) {
          featureList.add('Analisis & Laporan advance (Excel & Grafik)');
        }
        if (rawFeatures['staff_management'] == true) {
          featureList.add('Manajemen staf & hak akses kasir/karyawan');
        }
        if (rawFeatures['customer_catalog'] == true) {
          featureList.add('Katalog mandiri pelanggan (Self-Order QR)');
        }
        if (rawFeatures['remove_ads'] == true) {
          featureList.add('Bebas Iklan (Tanpa Iklan Banner)');
        }
      } else if (rawFeatures is List) {
        featureList = rawFeatures.map((e) => e.toString()).toList();
      }

      final maxTx = (json['max_transactions'] as num?)?.toInt() ?? 0;
      if (maxTx > 0) {
        featureList.insert(0, 'Maksimal $maxTx transaksi/bulan');
      } else {
        featureList.insert(0, 'Transaksi Tanpa Batas (Unlimited)');
      }

      final maxOutlets = (json['max_outlets'] as num?)?.toInt() ?? 1;
      if (maxOutlets > 1) {
        featureList.insert(1, 'Dukungan hingga $maxOutlets cabang/outlet');
      }
    }

    final slug = json['slug'] as String? ?? '';
    final price = (json['price'] as num?)?.toInt() ?? 0;
    final maxTx = (json['max_transactions'] as num?)?.toInt() ?? 0;
    final maxOutlets = (json['max_outlets'] as num?)?.toInt() ?? 1;

    final durationDays = (json['duration_days'] as num?)?.toInt() ?? (price == 0 ? 0 : 30);
    final billingPeriod = json['billing_period'] as String? ?? (price == 0 ? 'lifetime' : 'monthly');

    String periodLabel = '/bulan';
    if (billingPeriod == 'lifetime' || price == 0) {
      periodLabel = 'Gratis';
    } else if (billingPeriod == 'yearly' || durationDays >= 365) {
      periodLabel = '/tahun';
    }

    return SubscriptionPlan(
      id: json['id'] as String,
      slug: slug,
      name: json['name'] as String? ?? '',
      tagline: json['description'] as String? ?? 'Paket langganan POS',
      price: price,
      period: periodLabel,
      durationDays: durationDays,
      billingPeriod: billingPeriod,
      googlePlayProductId: 'com.posmobile.subscription.$slug',
      features: featureList,
      maxOutlets: maxOutlets,
      maxTransactions: maxTx,
      isPopular: slug == 'umkm-hebat',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'description': tagline,
      'price': price,
      'duration_days': durationDays,
      'billing_period': billingPeriod,
      'max_outlets': maxOutlets,
      'max_transactions': maxTransactions,
    };
  }
}

class UserSubscriptionInfo {
  final String? id; // UUID from subscriptions table
  final String planId;
  final String planName;
  final String status; // 'active', 'trial', 'free', 'expired'
  final DateTime? startDate;
  final DateTime? expiresAt;
  final bool autoRenew;
  final Map<String, bool> featureFlags;
  final int maxOutlets;
  final int maxTransactions;

  const UserSubscriptionInfo({
    this.id,
    required this.planId,
    required this.planName,
    required this.status,
    this.startDate,
    this.expiresAt,
    this.autoRenew = true,
    this.featureFlags = const {},
    this.maxOutlets = 1,
    this.maxTransactions = 500,
  });

  bool get isExpired {
    if (expiresAt == null) return false; // Lifetime / free
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Menandakan user sedang memiliki paket berbayar yang masih aktif (belum expired)
  bool get isPaidActive {
    final isFreeOrLite = planId == 'b29dcf1a-4c25-4abc-9e98-d562746e0294' ||
        planId == 'lite' ||
        planId == 'free' ||
        status == 'free';
    return !isFreeOrLite && !isExpired;
  }

  bool get isFree => !isPaidActive;

  /// Jumlah sisa hari aktif paket langganan (null jika gratis/lifetime)
  int? get remainingDays {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Menandakan paket berbayar akan kedaluwarsa dalam waktu dekat (≤ 7 hari dan > 0)
  bool get isExpiringSoon {
    if (!isPaidActive || expiresAt == null) return false;
    final days = remainingDays ?? 999;
    return days <= 7;
  }

  bool canAccess(String featureKey) {
    if (isExpired) return false;
    return featureFlags[featureKey] == true;
  }

  factory UserSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final planData = json['subscription_plans'] as Map<String, dynamic>?;
    final planName = planData?['name'] as String? ?? json['plan_name'] as String? ?? 'Lite (UMKM Pemula)';

    Map<String, bool> flags = {};
    final rawFlags = planData?['features'] ?? json['features'];
    if (rawFlags is Map<String, dynamic>) {
      rawFlags.forEach((key, value) {
        if (value is bool) {
          flags[key] = value;
        } else if (value != null) {
          flags[key] = value.toString() == 'true';
        }
      });
    }

    final maxOutlets = (planData?['max_outlets'] as num?)?.toInt() ?? 1;
    final maxTransactions = (planData?['max_transactions'] as num?)?.toInt() ?? 500;

    return UserSubscriptionInfo(
      id: json['id'] as String?,
      planId: json['plan_id'] as String? ?? '',
      planName: planName,
      status: json['status'] as String? ?? 'active',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())?.toLocal()
          : null,
      expiresAt: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())?.toLocal()
          : null,
      autoRenew: json['auto_renew'] as bool? ?? false,
      featureFlags: flags,
      maxOutlets: maxOutlets,
      maxTransactions: maxTransactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'status': status,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (expiresAt != null) 'end_date': expiresAt!.toIso8601String(),
      'feature_flags': featureFlags,
    };
  }
}

class SubscriptionTransaction {
  final String id;
  final String orderId; // GPA.xxxx atau tx id
  final String planName;
  final int amount;
  final DateTime purchaseDate;
  final String status; // 'success', 'pending', 'refunded'
  final String paymentMethod; // 'Google Play Billing'

  const SubscriptionTransaction({
    required this.id,
    required this.orderId,
    required this.planName,
    required this.amount,
    required this.purchaseDate,
    required this.status,
    this.paymentMethod = 'Google Play Billing',
  });

  factory SubscriptionTransaction.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>?;
    final planData = json['subscription_plans'] as Map<String, dynamic>?;

    final orderId = payload?['order_id'] as String? ??
        'GPA.${json['id'].toString().substring(0, 8).toUpperCase()}';
    final planName = planData?['name'] as String? ??
        payload?['plan_name'] as String? ??
        'Langganan POS';
    final paymentMethod = payload?['payment_method'] as String? ?? 'Google Play Billing';

    return SubscriptionTransaction(
      id: json['id'] as String? ?? '',
      orderId: orderId,
      planName: planName,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      purchaseDate: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      status: json['status'] as String? ?? 'success',
      paymentMethod: paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'created_at': purchaseDate.toIso8601String(),
      'payload': {
        'order_id': orderId,
        'plan_name': planName,
        'payment_method': paymentMethod,
      },
    };
  }
}

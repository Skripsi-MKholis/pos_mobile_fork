/// Konfigurasi tampilan/cetak struk, dibaca dari `stores.settings.receipt`.
///
/// Dipakai bersama oleh layar struk (in-app), layanan cetak thermal, dan
/// layar kustomisasi struk agar aturan default & fallback tidak terduplikasi
/// di tiga tempat berbeda.
class ReceiptConfig {
  final String storeName;
  final String address;
  final String phone;
  final String headerMessage;
  final String footerMessage;
  final String websiteUrl;
  final String freeText;
  final String cashierNameOverride;
  final String receiptNumberPrefix;
  final String paperWidth;
  final String logoUrl;

  final bool showLogo;
  final bool showAddress;
  final bool showPhone;
  final bool showHeaderMessage;
  final bool showFooterMessage;
  final bool showCashier;
  final bool showQrCode;
  final bool showPaymentMethod;

  const ReceiptConfig({
    required this.storeName,
    required this.address,
    required this.phone,
    required this.headerMessage,
    required this.footerMessage,
    required this.websiteUrl,
    required this.freeText,
    required this.cashierNameOverride,
    required this.receiptNumberPrefix,
    required this.paperWidth,
    required this.logoUrl,
    required this.showLogo,
    required this.showAddress,
    required this.showPhone,
    required this.showHeaderMessage,
    required this.showFooterMessage,
    required this.showCashier,
    required this.showQrCode,
    required this.showPaymentMethod,
  });

  /// Bangun dari map `store` lengkap (hasil `activeStoreProvider`), yang
  /// membawa `settings.receipt` plus data dasar toko (`name`, `address`, dst)
  /// sebagai fallback ketika field struk belum diisi.
  factory ReceiptConfig.fromStore(Map<String, dynamic>? store) {
    final storeSettings = store?['settings'] as Map<String, dynamic>? ?? {};
    final receipt = storeSettings['receipt'] as Map<String, dynamic>? ?? {};
    return ReceiptConfig.fromReceiptMap(receipt, store: store);
  }

  /// Bangun langsung dari map pengaturan struk (mis. `_settings` pada layar
  /// kustomisasi yang sedang diedit, sebelum disimpan ke store).
  factory ReceiptConfig.fromReceiptMap(
    Map<String, dynamic> receipt, {
    Map<String, dynamic>? store,
  }) {
    String pick(String key, {String fallback = ''}) {
      final value = receipt[key];
      if (value is String && value.isNotEmpty) return value;
      return fallback;
    }

    return ReceiptConfig(
      storeName: pick(
        'store_name',
        fallback: (store?['name'] as String?) ?? 'PARZELLO POS',
      ),
      address: pick('address', fallback: (store?['address'] as String?) ?? ''),
      phone: pick('phone', fallback: (store?['phone'] as String?) ?? ''),
      headerMessage: pick(
        'header_message',
        fallback: 'Terima Kasih Telah Berbelanja',
      ),
      footerMessage: pick('footer_message', fallback: 'Terima Kasih'),
      websiteUrl: pick('website_url'),
      freeText: pick('free_text'),
      cashierNameOverride: pick('cashier_name'),
      receiptNumberPrefix: pick('receipt_number_prefix', fallback: 'PRZ'),
      paperWidth: pick('paper_width', fallback: '58'),
      logoUrl: (store?['logo_url'] as String?) ?? '',
      showLogo: receipt['show_logo'] ?? true,
      showAddress: receipt['show_address'] ?? true,
      showPhone: receipt['show_phone'] ?? true,
      showHeaderMessage: receipt['show_header_message'] ?? true,
      showFooterMessage: receipt['show_footer_message'] ?? true,
      showCashier: receipt['show_cashier'] ?? true,
      showQrCode: receipt['show_qr_code'] ?? true,
      showPaymentMethod: receipt['show_payment_method'] ?? true,
    );
  }

  /// Resolusi nama kasir: override manual > nama akun yang login > fallback.
  String resolveCashierName(
    String? loggedInName, {
    String fallback = 'Staf Parzello',
  }) {
    if (cashierNameOverride.isNotEmpty) return cashierNameOverride;
    if (loggedInName != null && loggedInName.isNotEmpty) return loggedInName;
    return fallback;
  }

  /// Lebar baris untuk printer thermal: 58mm ~32 karakter, 80mm ~48 karakter.
  int get printerLineWidth => paperWidth == '80' ? 48 : 32;

  String get printerSeparator => '-' * printerLineWidth;
}

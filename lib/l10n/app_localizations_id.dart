// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get menu => 'Menu';

  @override
  String get catalogAndStock => 'KATALOG & STOK';

  @override
  String get productList => 'Daftar Produk';

  @override
  String get productCategory => 'Kategori Produk';

  @override
  String get storeSettings => 'PENGATURAN TOKO';

  @override
  String get printerConnection => 'Koneksi Printer';

  @override
  String get receiptCustomization => 'Kustomisasi Struk';

  @override
  String get storeInformation => 'Informasi Toko';

  @override
  String get employeeManagement => 'Manajemen Karyawan';

  @override
  String get broadcastNotification => 'Broadcast Notifikasi';

  @override
  String get accountAndSecurity => 'AKUN & KEAMANAN';

  @override
  String get myProfile => 'Profil Saya';

  @override
  String get changePassword => 'Ganti Kata Sandi';

  @override
  String get dataSynchronization => 'Sinkronisasi Data';

  @override
  String get language => 'Bahasa';

  @override
  String get languageName => 'Bahasa Indonesia';

  @override
  String get logoutApp => 'Keluar Aplikasi';

  @override
  String get version => 'Versi';

  @override
  String get confirmLogout => 'Konfirmasi Keluar';

  @override
  String get confirmLogoutDesc =>
      'Apakah Anda yakin ingin keluar dari aplikasi? Sesi Anda akan dihentikan.';

  @override
  String get cancel => 'Batal';

  @override
  String get yesLogout => 'Ya, Keluar';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get english => 'English';

  @override
  String get logoutStore => 'Keluar dari Toko';

  @override
  String confirmLeaveStore(String storeName) {
    return 'Apakah Anda yakin ingin keluar dari toko $storeName? Anda tidak akan bisa mengakses toko ini lagi tanpa kode undangan baru.';
  }

  @override
  String get yesLeave => 'Ya, Keluar';

  @override
  String get leaveSuccess => 'Anda telah keluar dari toko.';

  @override
  String leaveFailed(String error) {
    return 'Gagal keluar dari toko: $error';
  }

  @override
  String get analytics => 'ANALITIK';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get reports => 'Laporan';

  @override
  String get smartAnalytics => 'Smart Analitik';

  @override
  String get cashierOperational => 'OPERASIONAL KASIR';

  @override
  String get cashierPos => 'Kasir (POS)';

  @override
  String get transactionHistory => 'Riwayat Transaksi';

  @override
  String get tableMonitoring => 'Monitoring Meja';

  @override
  String get tableManagement => 'Manajemen Meja';

  @override
  String get manageStock => 'Kelola Stok';

  @override
  String get categories => 'Kategori';

  @override
  String get settings => 'Pengaturan';

  @override
  String get printAndReceipt => 'Cetak & Struk';

  @override
  String get superAdmin => 'SUPER ADMIN';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get selectStore => 'Pilih Toko';

  @override
  String get tapToChangeOutlet => 'Tap untuk ganti outlet';

  @override
  String get selectStoreOutlet => 'Pilih Toko / Outlet';

  @override
  String get selectStoreDescription =>
      'Pilih toko yang ingin Anda kelola sekarang.';

  @override
  String get noStoreFound => 'Tidak ada toko ditemukan';

  @override
  String get manageAddStore => 'Kelola / Tambah Toko';

  @override
  String failedToLoad(String error) {
    return 'Gagal memuat: $error';
  }

  @override
  String get homeTab => 'Home';

  @override
  String get cashierTab => 'Kasir';

  @override
  String get historyTab => 'Riwayat';

  @override
  String get reportsTab => 'Laporan';

  @override
  String get menuTab => 'Menu';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get transactionHistoryTitle => 'Riwayat Transaksi';

  @override
  String get reportsTitle => 'Laporan Analitik';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get pressAgainToExit => 'Tekan sekali lagi untuk keluar';

  @override
  String get dashboardHeader => 'DASHBOARD';

  @override
  String get performanceSummary => 'Ringkasan Performa';

  @override
  String get today => 'Hari Ini';

  @override
  String get thisWeek => 'Minggu Ini';

  @override
  String get thisMonth => 'Bulan Ini';

  @override
  String get revenueToday => 'Omzet Hari Ini';

  @override
  String get revenueThisWeek => 'Omzet Minggu Ini';

  @override
  String get revenueThisMonth => 'Omzet Bulan Ini';

  @override
  String get transactionsToday => 'Transaksi Hari Ini';

  @override
  String get transactionsThisWeek => 'Transaksi Minggu Ini';

  @override
  String get transactionsThisMonth => 'Transaksi Bulan Ini';

  @override
  String get transactionsCompleted => 'Transaksi Selesai';

  @override
  String get lowStock => 'Stok Rendah';

  @override
  String get activeProducts => 'Produk Aktif';

  @override
  String get salesPerformance => 'Performa Penjualan';

  @override
  String get revenueTrend7Days => 'Tren omzet 7 hari terakhir';

  @override
  String get quickAccess => 'AKSES CEPAT';

  @override
  String get transaction => 'Transaksi';

  @override
  String get openNewCashier => 'Buka kasir baru';

  @override
  String get product => 'Produk';

  @override
  String get manageProductStock => 'Kelola stok barang';

  @override
  String get setupTableLayout => 'Atur layout meja';

  @override
  String get kitchenMonitor => 'Monitor Dapur';

  @override
  String get kdsDisplay => 'KDS Display';

  @override
  String get performanceAnalysis => 'Analisis performa';

  @override
  String get appConfiguration => 'Konfigurasi aplikasi';

  @override
  String productAddedToCart(String name) {
    return '$name telah ditambahkan ke keranjang.';
  }

  @override
  String get selectTable => 'Pilih Meja';

  @override
  String get reset => 'Reset';

  @override
  String get noTableAvailable => 'Tidak ada meja tersedia';

  @override
  String get tableOccupied => 'Meja Terisi';

  @override
  String get tableOccupiedDesc =>
      'Meja ini sedang digunakan. Ingin menambah pesanan ke meja ini?';

  @override
  String get addOrder => 'Tambah Pesanan';

  @override
  String get searchProduct => 'Cari produk...';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get table => 'Meja';

  @override
  String get all => 'Semua';

  @override
  String get sortByNameAsc => 'Nama (A-Z)';

  @override
  String get sortByNameDesc => 'Nama (Z-A)';

  @override
  String get sortByPriceAsc => 'Harga Terendah';

  @override
  String get sortByPriceDesc => 'Harga Tertinggi';

  @override
  String get sortByStockDesc => 'Stok Terbanyak';

  @override
  String get sortBy => 'Urutkan Berdasarkan';

  @override
  String get stockLow => 'Stok Menipis';

  @override
  String get outOfStock => 'Stok 0';

  @override
  String get totalBelanja => 'Total Belanja';

  @override
  String get clearCart => 'Kosongkan Keranjang';

  @override
  String get clearCartConfirmTitle => 'Kosongkan Keranjang';

  @override
  String get clearCartConfirmDesc =>
      'Apakah Anda yakin ingin mengosongkan keranjang? Semua barang akan dihapus.';

  @override
  String get viewDetails => 'Cek Detail';

  @override
  String get noProductsYet => 'Belum ada produk';

  @override
  String get noProductsYetDesc =>
      'Tambahkan produk pertama Anda untuk mulai berjualan.';

  @override
  String get addProduct => 'Tambah Produk';

  @override
  String get manageProduct => 'Kelola Produk';

  @override
  String get productNotFound => 'Produk tidak ditemukan';

  @override
  String productAddedScan(String name) {
    return '$name ditambahkan';
  }

  @override
  String skuNotRegistered(String code) {
    return 'SKU/Barcode \"$code\" tidak terdaftar!';
  }

  @override
  String get scanSkuBarcode => 'Scan SKU / Barcode';

  @override
  String get currentScanSession => 'Sesi Scan Ini';

  @override
  String get pointCameraToBarcode => 'Arahkan kamera ke barcode produk';

  @override
  String get totalSession => 'Total Sesi';

  @override
  String get done => 'Selesai';

  @override
  String minPurchase(String minPurchase) {
    return 'Min. belanja $minPurchase';
  }

  @override
  String get invalidVoucher => 'Kode voucher tidak valid';

  @override
  String get anErrorOccurred => 'Terjadi kesalahan';

  @override
  String get orderDetail => 'Detail Pesanan';

  @override
  String tableWithColon(String tableName) {
    return 'Meja: $tableName';
  }

  @override
  String get cartIsEmpty => 'Keranjang masih kosong';

  @override
  String get haveVoucherCode => 'Punya kode voucher?';

  @override
  String get apply => 'Pakai';

  @override
  String voucherWithColon(String voucherCode) {
    return 'Voucher: $voucherCode';
  }

  @override
  String savedAmount(String amount) {
    return 'Hemat $amount';
  }

  @override
  String get subtotal => 'Subtotal';

  @override
  String get voucherDiscount => 'Diskon Voucher';

  @override
  String get totalPayment => 'Total Bayar';

  @override
  String get saveToTable => 'Simpan ke Meja';

  @override
  String get orderSavedToTable => 'Pesanan berhasil disimpan ke meja.';

  @override
  String failedToSaveOrder(String error) {
    return 'Gagal menyimpan pesanan: $error';
  }

  @override
  String get continueToPayment => 'Lanjut Pembayaran';

  @override
  String get payment => 'Pembayaran';

  @override
  String get paymentMethod => 'Metode Pembayaran';

  @override
  String get cashReceived => 'Uang Tunai Diterima';

  @override
  String get enterAmount => 'Masukkan jumlah uang...';

  @override
  String get confirmAndSaveTransaction => 'Konfirmasi & Simpan Transaksi';

  @override
  String get totalBill => 'TOTAL TAGIHAN';

  @override
  String get cash => 'Tunai';

  @override
  String get change => 'KEMBALIAN';

  @override
  String get insufficientCash => 'Uang Kurang';

  @override
  String get cashNotSufficient => 'Uang tunai tidak mencukupi';

  @override
  String get activeStoreNotFound =>
      'Toko aktif tidak ditemukan. Silakan pilih toko terlebih dahulu.';

  @override
  String transactionSynced(String amount) {
    return 'Transaksi senilai $amount telah disimpan & disinkronkan.';
  }

  @override
  String transactionSavedLocal(String amount) {
    return 'Transaksi senilai $amount disimpan lokal (Belum Sinkron).';
  }

  @override
  String failedWithReason(String error) {
    return 'Gagal: $error';
  }

  @override
  String get paymentSuccess => 'Pembayaran Berhasil';

  @override
  String get paymentSuccessDesc =>
      'Transaksi Anda telah berhasil dicatat ke sistem. Silakan pilih langkah selanjutnya.';

  @override
  String get toHistory => 'Ke Riwayat';

  @override
  String get viewReceipt => 'Lihat Struk';

  @override
  String get receiptPrinting => 'Struk sedang dicetak.';

  @override
  String failedToPrint(String error) {
    return 'Gagal mencetak: $error';
  }

  @override
  String get digitalReceipt => 'Struk Digital';

  @override
  String get transactionNo => 'No. Transaksi';

  @override
  String get date => 'Tanggal';

  @override
  String get method => 'Metode';

  @override
  String get cashier => 'Kasir';

  @override
  String get parzelloStaff => 'Staf Parzello';

  @override
  String get paid => 'Bayar';

  @override
  String get scanToViewOnlineReceipt => 'Pindai untuk melihat struk online';

  @override
  String get share => 'Bagikan';

  @override
  String get printing => 'Mencetak...';

  @override
  String get setPrinter => 'Set Printer';

  @override
  String get printReceipt => 'Cetak Struk';

  @override
  String get connectPrinter => 'Hubungkan Printer';

  @override
  String get connectPrinterDesc =>
      'Pilih printer bluetooth Anda untuk langsung mencetak struk.';

  @override
  String get noBluetoothPrinterFound =>
      'Tidak ada bluetooth printer terpasang.';

  @override
  String get thermalPrinter => 'Printer Thermal';

  @override
  String get select => 'Pilih';

  @override
  String splitBillWithTable(String tableName) {
    return 'Bayar Pisah - Meja $tableName';
  }

  @override
  String pricePerItem(String price) {
    return '$price / item';
  }

  @override
  String get totalSelected => 'Total Terpilih';

  @override
  String get revenue => 'Omzet';

  @override
  String get searchTransaction => 'Cari transaksi...';

  @override
  String get success => 'Berhasil';

  @override
  String get pending => 'Pending';

  @override
  String get cancelled => 'Batal';

  @override
  String get yesterday => 'Kemarin';

  @override
  String get selectDate => 'Pilih Tanggal';

  @override
  String get noTransactions => 'Tidak ada transaksi';

  @override
  String get smartAnalyticsDesc => 'Prediksi stok & tren dengan AI';

  @override
  String get realTimeData => 'Data real-time';

  @override
  String get noSalesData => 'Tidak ada data penjualan';

  @override
  String get salesTrend => 'Tren Penjualan';

  @override
  String get noTopProductsData => 'Belum ada data produk terjual';

  @override
  String get topProducts => 'Produk Terlaris';

  @override
  String get highestSalesVolume => 'Volume penjualan tertinggi';

  @override
  String get sold => 'terjual';

  @override
  String get salesTrendToday => 'TREN PENJUALAN (HARI INI)';

  @override
  String get salesTrend7Days => 'TREN PENJUALAN (7 HARI)';

  @override
  String get salesTrendThisMonth => 'TREN PENJUALAN (BULAN INI)';

  @override
  String get comingSoon => 'Segera Hadir';

  @override
  String get aiProFeature => 'FITUR PRO AI';

  @override
  String get smartAnalyticsLockedDesc =>
      'Fitur Smart Analitik berbasis kecerdasan buatan sedang dalam tahap pengembangan aktif untuk menyajikan proyeksi bisnis terbaik bagi Anda.';

  @override
  String get productCatalog => 'Katalog Produk';

  @override
  String get manageYourInventory => 'Kelola inventaris barang Anda';

  @override
  String get deleteProduct => 'Hapus Produk';

  @override
  String deleteProductConfirm(String name) {
    return 'Apakah Anda yakin ingin menghapus \"$name\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deletePermanently => 'Hapus Permanen';

  @override
  String get productDeletedSuccess => 'Produk berhasil dihapus';

  @override
  String productDeleteFailed(String error) {
    return 'Gagal menghapus produk: $error';
  }

  @override
  String get searchNameOrSku => 'Cari nama atau SKU...';

  @override
  String get manageCategories => 'Kelola Kategori';

  @override
  String get productNotFoundDesc =>
      'Coba gunakan kata kunci lain atau tambah produk baru ke katalog Anda.';

  @override
  String get resetFilter => 'Reset Filter';

  @override
  String lowStockCount(int count) {
    return 'Tipis: $count';
  }

  @override
  String stockCount(int count) {
    return 'Stok: $count';
  }

  @override
  String get waitingForSync => 'Menunggu sinkronisasi ke cloud';

  @override
  String get skuCopied => 'SKU berhasil disalin ke clipboard.';

  @override
  String barcodeShareText(String name, String sku) {
    return 'Barcode untuk $name ($sku)';
  }

  @override
  String shareFailed(String error) {
    return 'Gagal membagikan: $error';
  }

  @override
  String get productBarcode => 'Barcode Produk';

  @override
  String get copySku => 'Salin SKU';

  @override
  String get add => 'Tambah';

  @override
  String get edit => 'Ubah';

  @override
  String get searchCategory => 'Cari kategori...';

  @override
  String get noCategoriesYet => 'Belum ada kategori';

  @override
  String get noCategoriesYetDesc =>
      'Tambah kategori baru untuk mulai mengelompokkan produk Anda.';

  @override
  String get viewProducts => 'Lihat Produk';

  @override
  String get editCategory => 'Edit Kategori';

  @override
  String get addCategory => 'Tambah Kategori';

  @override
  String get deleteCategory => 'Hapus Kategori';

  @override
  String get fillCategoryInfo => 'Isi informasi kategori dengan lengkap.';

  @override
  String get categoryName => 'Nama Kategori';

  @override
  String get categoryNameExample => 'Contoh: Makanan, Minuman...';

  @override
  String get categoryNameEmpty => 'Nama kategori tidak boleh kosong';

  @override
  String get categoryUpdatedSuccess => 'Kategori berhasil diperbarui';

  @override
  String get categoryAddedSuccess => 'Kategori berhasil ditambahkan';

  @override
  String categoryActionFailed(String error) {
    return 'Gagal: $error';
  }

  @override
  String deleteCategoryConfirm(String name) {
    return 'Apakah Anda yakin ingin menghapus kategori \"$name\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get categoryDeletedSuccess => 'Kategori berhasil dihapus';

  @override
  String categoryDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String get delete => 'Hapus';

  @override
  String get save => 'Simpan';

  @override
  String get randomSkuCreated => 'SKU acak berhasil dibuat';

  @override
  String barcodeFor(String productName, String sku) {
    return 'Barcode untuk $productName ($sku)';
  }

  @override
  String get newProduct => 'Produk Baru';

  @override
  String get editProduct => 'Edit Produk';

  @override
  String get productName => 'Nama Produk';

  @override
  String get enterProductName => 'Masukkan nama produk...';

  @override
  String get category => 'Kategori';

  @override
  String get selectCategory => 'Pilih Kategori';

  @override
  String get noCategory => 'Tanpa Kategori';

  @override
  String get loadingCategories => 'Loading kategori...';

  @override
  String errorCategories(String error) {
    return 'Error: $error';
  }

  @override
  String get skuBarcode => 'SKU / Barcode';

  @override
  String get scanOrTypeSku => 'Scan atau ketik SKU...';

  @override
  String get generateRandomSku => 'Generate SKU Acak';

  @override
  String get scanBarcodeCamera => 'Scan Barcode Kamera';

  @override
  String get barcodePreview => 'Barcode Preview';

  @override
  String get costPrice => 'Harga Modal';

  @override
  String get sellingPrice => 'Harga Jual';

  @override
  String get initialStock => 'Stok Awal';

  @override
  String get saveProduct => 'Simpan Produk';

  @override
  String get tapToAddPhoto => 'Ketuk untuk tambah foto';

  @override
  String get productNameRequired => 'Nama produk wajib diisi';

  @override
  String productSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get monitorAndUpdateStock => 'Pantau dan perbarui stok produk Anda';

  @override
  String get allCategories => 'Semua Kategori';

  @override
  String stockUpdated(String productName, int stock) {
    return 'Stok $productName diperbarui menjadi $stock';
  }

  @override
  String stockUpdateFailed(String error) {
    return 'Gagal memperbarui stok: $error';
  }

  @override
  String get welcomeBack => 'Selamat Datang Kembali';

  @override
  String get loginSubtitle =>
      'Masukkan email dan password untuk masuk ke dashboard POS.';

  @override
  String get login => 'Login';

  @override
  String get useRegisteredAccount => 'Gunakan akun yang sudah terdaftar.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Lupa password?';

  @override
  String get signIn => 'Masuk';

  @override
  String get orContinueWith => 'ATAU LANJUT DENGAN';

  @override
  String get dontHaveAccount => 'Belum punya akun? ';

  @override
  String get signUpHere => 'Daftar di sini';

  @override
  String get emailPasswordRequired => 'Email dan Password tidak boleh kosong';

  @override
  String loginFailed(String error) {
    return 'Login Gagal: $error';
  }

  @override
  String googleSignInFailed(String error) {
    return 'Google Sign-In Gagal: $error';
  }

  @override
  String get createAccount => 'Buat Akun Baru';

  @override
  String get registerSubtitle =>
      'Mulai kelola bisnis Anda dengan sistem POS modern.';

  @override
  String get register => 'Daftar';

  @override
  String get registerInstructions =>
      'Lengkapi data di bawah untuk membuat akun.';

  @override
  String get fullName => 'Nama Lengkap';

  @override
  String get confirmPassword => 'Konfirmasi Password';

  @override
  String get registerNow => 'Daftar Sekarang';

  @override
  String get orRegisterWith => 'ATAU DAFTAR DENGAN';

  @override
  String get alreadyHaveAccount => 'Sudah punya akun? ';

  @override
  String get loginHere => 'Login di sini';

  @override
  String get allFieldsRequired => 'Semua kolom wajib diisi';

  @override
  String get passwordsDoNotMatch => 'Password tidak cocok';

  @override
  String get registrationSuccess =>
      'Registrasi berhasil! Silakan cek email Anda.';

  @override
  String registrationFailed(String error) {
    return 'Registrasi Gagal: $error';
  }
}

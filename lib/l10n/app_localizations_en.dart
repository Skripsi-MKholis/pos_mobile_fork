// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menu => 'Menu';

  @override
  String get catalogAndStock => 'CATALOG & STOCK';

  @override
  String get productList => 'Product List';

  @override
  String get productCategory => 'Product Category';

  @override
  String get storeSettings => 'STORE SETTINGS';

  @override
  String get printerConnection => 'Printer Connection';

  @override
  String get receiptCustomization => 'Receipt Customization';

  @override
  String get storeInformation => 'Store Information';

  @override
  String get employeeManagement => 'Employee Management';

  @override
  String get broadcastNotification => 'Broadcast Notification';

  @override
  String get accountAndSecurity => 'ACCOUNT & SECURITY';

  @override
  String get myProfile => 'My Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get dataSynchronization => 'Data Synchronization';

  @override
  String get language => 'Language';

  @override
  String get languageName => 'English';

  @override
  String get logoutApp => 'Logout Application';

  @override
  String get version => 'Version';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get confirmLogoutDesc =>
      'Are you sure you want to log out of the application? Your session will be terminated.';

  @override
  String get cancel => 'Cancel';

  @override
  String get yesLogout => 'Yes, Logout';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get english => 'English';

  @override
  String get logoutStore => 'Leave Store';

  @override
  String confirmLeaveStore(String storeName) {
    return 'Are you sure you want to leave the store $storeName? You will not be able to access this store again without a new invitation code.';
  }

  @override
  String get yesLeave => 'Yes, Leave';

  @override
  String get leaveSuccess => 'You have left the store.';

  @override
  String leaveFailed(String error) {
    return 'Failed to leave the store: $error';
  }

  @override
  String get analytics => 'ANALYTICS';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get reports => 'Reports';

  @override
  String get smartAnalytics => 'Smart Analytics';

  @override
  String get cashierOperational => 'CASHIER OPERATIONAL';

  @override
  String get cashierPos => 'Cashier (POS)';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get tableMonitoring => 'Table Monitoring';

  @override
  String get tableManagement => 'Table Management';

  @override
  String get manageStock => 'Manage Stock';

  @override
  String get categories => 'Categories';

  @override
  String get settings => 'Settings';

  @override
  String get printAndReceipt => 'Print & Receipt';

  @override
  String get superAdmin => 'SUPER ADMIN';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get selectStore => 'Select Store';

  @override
  String get tapToChangeOutlet => 'Tap to change outlet';

  @override
  String get selectStoreOutlet => 'Select Store / Outlet';

  @override
  String get selectStoreDescription =>
      'Select the store you want to manage now.';

  @override
  String get noStoreFound => 'No store found';

  @override
  String get manageAddStore => 'Manage / Add Store';

  @override
  String failedToLoad(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get homeTab => 'Home';

  @override
  String get cashierTab => 'Cashier';

  @override
  String get historyTab => 'History';

  @override
  String get reportsTab => 'Reports';

  @override
  String get menuTab => 'Menu';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get transactionHistoryTitle => 'Transaction History';

  @override
  String get reportsTitle => 'Analytics Report';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get pressAgainToExit => 'Press once more to exit';

  @override
  String get dashboardHeader => 'DASHBOARD';

  @override
  String get performanceSummary => 'Performance Summary';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get revenueToday => 'Today\'s Revenue';

  @override
  String get revenueThisWeek => 'This Week\'s Revenue';

  @override
  String get revenueThisMonth => 'This Month\'s Revenue';

  @override
  String get transactionsToday => 'Today\'s Transactions';

  @override
  String get transactionsThisWeek => 'This Week\'s Transactions';

  @override
  String get transactionsThisMonth => 'This Month\'s Transactions';

  @override
  String get transactionsCompleted => 'Transactions Completed';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get activeProducts => 'Active Products';

  @override
  String get salesPerformance => 'Sales Performance';

  @override
  String get revenueTrend7Days => 'Revenue trend last 7 days';

  @override
  String get quickAccess => 'QUICK ACCESS';

  @override
  String get transaction => 'Transaction';

  @override
  String get openNewCashier => 'Open new cashier';

  @override
  String get product => 'Product';

  @override
  String get manageProductStock => 'Manage product stock';

  @override
  String get setupTableLayout => 'Set up table layout';

  @override
  String get kitchenMonitor => 'Kitchen Monitor';

  @override
  String get kdsDisplay => 'KDS Display';

  @override
  String get performanceAnalysis => 'Performance analysis';

  @override
  String get appConfiguration => 'App configuration';

  @override
  String productAddedToCart(String name) {
    return '$name has been added to cart.';
  }

  @override
  String get selectTable => 'Select Table';

  @override
  String get reset => 'Reset';

  @override
  String get noTableAvailable => 'No tables available';

  @override
  String get tableOccupied => 'Table Occupied';

  @override
  String get tableOccupiedDesc =>
      'This table is currently occupied. Do you want to add orders to this table?';

  @override
  String get addOrder => 'Add Order';

  @override
  String get searchProduct => 'Search products...';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get table => 'Table';

  @override
  String get all => 'All';

  @override
  String get sortByNameAsc => 'Name (A-Z)';

  @override
  String get sortByNameDesc => 'Name (Z-A)';

  @override
  String get sortByPriceAsc => 'Price: Low to High';

  @override
  String get sortByPriceDesc => 'Price: High to Low';

  @override
  String get sortByStockDesc => 'Stock: High to Low';

  @override
  String get sortBy => 'Sort By';

  @override
  String get stockLow => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get totalBelanja => 'Total Items Price';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get confirmClearCart => 'Clear Cart?';

  @override
  String get confirmClearCartDesc =>
      'Are you sure you want to clear your cart? All items will be removed.';

  @override
  String get viewDetails => 'View Details';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get noProductsYetDesc => 'Add your first product to start selling.';

  @override
  String get addProduct => 'Add Product';

  @override
  String get manageProduct => 'Manage Products';

  @override
  String get productNotFound => 'Product not found';

  @override
  String productAddedScan(String name) {
    return '$name added';
  }

  @override
  String skuNotRegistered(String code) {
    return 'SKU/Barcode \"$code\" is not registered!';
  }

  @override
  String get scanSkuBarcode => 'Scan SKU / Barcode';

  @override
  String get currentScanSession => 'Current Scan Session';

  @override
  String get pointCameraToBarcode => 'Point camera to product barcode';

  @override
  String get totalSession => 'Total Session';

  @override
  String get done => 'Done';

  @override
  String minPurchase(String minPurchase) {
    return 'Min. purchase $minPurchase';
  }

  @override
  String get invalidVoucher => 'Invalid voucher code';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get orderDetail => 'Order Detail';

  @override
  String tableWithColon(String tableName) {
    return 'Table: $tableName';
  }

  @override
  String get cartIsEmpty => 'Cart is empty';

  @override
  String get haveVoucherCode => 'Have a voucher code?';

  @override
  String get apply => 'Apply';

  @override
  String voucherWithColon(String voucherCode) {
    return 'Voucher: $voucherCode';
  }

  @override
  String savedAmount(String amount) {
    return 'Saved $amount';
  }

  @override
  String get subtotal => 'Subtotal';

  @override
  String get voucherDiscount => 'Voucher Discount';

  @override
  String get totalPayment => 'Total Payment';

  @override
  String get saveToTable => 'Save to Table';

  @override
  String get orderSavedToTable => 'Order successfully saved to table.';

  @override
  String failedToSaveOrder(String error) {
    return 'Failed to save order: $error';
  }

  @override
  String get continueToPayment => 'Continue to Payment';

  @override
  String get payment => 'Payment';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cashReceived => 'Cash Received';

  @override
  String get enterAmount => 'Enter amount...';

  @override
  String get confirmAndSaveTransaction => 'Confirm & Save Transaction';

  @override
  String get totalBill => 'TOTAL BILL';

  @override
  String get cash => 'Cash';

  @override
  String get change => 'CHANGE';

  @override
  String get insufficientCash => 'Insufficient Cash';

  @override
  String get cashNotSufficient => 'Cash is not sufficient';

  @override
  String get activeStoreNotFound =>
      'Active store not found. Please select a store first.';

  @override
  String transactionSynced(String amount) {
    return 'Transaction of $amount has been saved & synced.';
  }

  @override
  String transactionSavedLocal(String amount) {
    return 'Transaction of $amount saved locally (Not Synced).';
  }

  @override
  String failedWithReason(String error) {
    return 'Failed: $error';
  }

  @override
  String get paymentSuccess => 'Payment Successful';

  @override
  String get paymentSuccessDesc =>
      'Your transaction has been successfully recorded in the system. Please choose the next step.';

  @override
  String get toHistory => 'To History';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String get receiptPrinting => 'Receipt is printing.';

  @override
  String failedToPrint(String error) {
    return 'Failed to print: $error';
  }

  @override
  String get digitalReceipt => 'Digital Receipt';

  @override
  String get transactionNo => 'Transaction No.';

  @override
  String get date => 'Date';

  @override
  String get method => 'Method';

  @override
  String get cashier => 'Cashier';

  @override
  String get parzelloStaff => 'Parzello Staff';

  @override
  String get paid => 'Paid';

  @override
  String get scanToViewOnlineReceipt => 'Scan to view online receipt';

  @override
  String get share => 'Share';

  @override
  String get printing => 'Printing...';

  @override
  String get setPrinter => 'Setup Printer';

  @override
  String get printReceipt => 'Print Receipt';

  @override
  String get connectPrinter => 'Connect Printer';

  @override
  String get connectPrinterDesc =>
      'Select your Bluetooth printer to print receipt directly.';

  @override
  String get noBluetoothPrinterFound => 'No paired Bluetooth printers found.';

  @override
  String get thermalPrinter => 'Thermal Printer';

  @override
  String get select => 'Select';

  @override
  String splitBillWithTable(String tableName) {
    return 'Split Bill - Table $tableName';
  }

  @override
  String pricePerItem(String price) {
    return '$price / item';
  }

  @override
  String get totalSelected => 'Total Selected';

  @override
  String get revenue => 'Revenue';

  @override
  String get searchTransaction => 'Search transaction...';

  @override
  String get success => 'Success';

  @override
  String get pending => 'Pending';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get selectDate => 'Select Date';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get smartAnalyticsDesc => 'Stock & trend predictions with AI';

  @override
  String get realTimeData => 'Real-time data';

  @override
  String get noSalesData => 'No sales data';

  @override
  String get salesTrend => 'Sales Trend';

  @override
  String get noTopProductsData => 'No top products sold data';

  @override
  String get topProducts => 'Best Sellers';

  @override
  String get highestSalesVolume => 'Highest sales volume';

  @override
  String get sold => 'sold';

  @override
  String get salesTrendToday => 'SALES TREND (TODAY)';

  @override
  String get salesTrend7Days => 'SALES TREND (7 DAYS)';

  @override
  String get salesTrendThisMonth => 'SALES TREND (THIS MONTH)';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get aiProFeature => 'AI PRO FEATURE';

  @override
  String get smartAnalyticsLockedDesc =>
      'The AI-powered Smart Analytics feature is under active development to bring you the best business projections.';

  @override
  String get productCatalog => 'Product Catalog';

  @override
  String get manageYourInventory => 'Manage your item inventory';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String deleteProductConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get productDeletedSuccess => 'Product successfully deleted';

  @override
  String productDeleteFailed(String error) {
    return 'Failed to delete product: $error';
  }

  @override
  String get searchNameOrSku => 'Search name or SKU...';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get productNotFoundDesc =>
      'Try using another keyword or add a new product to your catalog.';

  @override
  String get resetFilter => 'Reset Filter';

  @override
  String lowStockCount(int count) {
    return 'Low: $count';
  }

  @override
  String stockCount(int count) {
    return 'Stock: $count';
  }

  @override
  String get waitingForSync => 'Waiting for cloud sync';

  @override
  String get skuCopied => 'SKU successfully copied to clipboard.';

  @override
  String barcodeShareText(String name, String sku) {
    return 'Barcode for $name ($sku)';
  }

  @override
  String shareFailed(String error) {
    return 'Failed to share: $error';
  }

  @override
  String get productBarcode => 'Product Barcode';

  @override
  String get copySku => 'Copy SKU';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get searchCategory => 'Search category...';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get noCategoriesYetDesc =>
      'Add a new category to start grouping your products.';

  @override
  String get viewProducts => 'View Products';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get addCategory => 'Add Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get fillCategoryInfo => 'Fill category details completely.';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameExample => 'e.g., Food, Beverage...';

  @override
  String get categoryNameEmpty => 'Category name cannot be empty';

  @override
  String get categoryUpdatedSuccess => 'Category successfully updated';

  @override
  String get categoryAddedSuccess => 'Category successfully added';

  @override
  String categoryActionFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String deleteCategoryConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get categoryDeletedSuccess => 'Category successfully deleted';

  @override
  String categoryDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get randomSkuCreated => 'Random SKU successfully created';

  @override
  String barcodeFor(String productName, String sku) {
    return 'Barcode for $productName ($sku)';
  }

  @override
  String get newProduct => 'New Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get productName => 'Product Name';

  @override
  String get enterProductName => 'Enter product name...';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get noCategory => 'No Category';

  @override
  String get loadingCategories => 'Loading categories...';

  @override
  String errorCategories(String error) {
    return 'Error: $error';
  }

  @override
  String get skuBarcode => 'SKU / Barcode';

  @override
  String get scanOrTypeSku => 'Scan or type SKU...';

  @override
  String get generateRandomSku => 'Generate Random SKU';

  @override
  String get scanBarcodeCamera => 'Scan Barcode (Camera)';

  @override
  String get barcodePreview => 'Barcode Preview';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get initialStock => 'Initial Stock';

  @override
  String get saveProduct => 'Save Product';

  @override
  String get tapToAddPhoto => 'Tap to add photo';

  @override
  String get productNameRequired => 'Product name is required';

  @override
  String productSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get monitorAndUpdateStock => 'Monitor and update your product stock';

  @override
  String get allCategories => 'All Categories';

  @override
  String stockUpdated(String productName, int stock) {
    return 'Stock of $productName updated to $stock';
  }

  @override
  String stockUpdateFailed(String error) {
    return 'Failed to update stock: $error';
  }

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle =>
      'Enter your email and password to access the POS dashboard.';

  @override
  String get login => 'Login';

  @override
  String get useRegisteredAccount => 'Use a registered account.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get orContinueWith => 'OR CONTINUE WITH';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUpHere => 'Sign up here';

  @override
  String get emailPasswordRequired => 'Email and Password cannot be empty';

  @override
  String loginFailed(String error) {
    return 'Login Failed: $error';
  }

  @override
  String googleSignInFailed(String error) {
    return 'Google Sign-In Failed: $error';
  }

  @override
  String get createAccount => 'Create New Account';

  @override
  String get registerSubtitle =>
      'Start managing your business with a modern POS system.';

  @override
  String get register => 'Register';

  @override
  String get registerInstructions =>
      'Complete the details below to create an account.';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get registerNow => 'Register Now';

  @override
  String get orRegisterWith => 'OR REGISTER WITH';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get loginHere => 'Login here';

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccess =>
      'Registration successful! Please check your email.';

  @override
  String registrationFailed(String error) {
    return 'Registration Failed: $error';
  }
}

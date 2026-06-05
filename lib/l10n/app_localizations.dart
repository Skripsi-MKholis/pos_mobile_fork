import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @catalogAndStock.
  ///
  /// In en, this message translates to:
  /// **'CATALOG & STOCK'**
  String get catalogAndStock;

  /// No description provided for @productList.
  ///
  /// In en, this message translates to:
  /// **'Product List'**
  String get productList;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Product Category'**
  String get productCategory;

  /// No description provided for @storeSettings.
  ///
  /// In en, this message translates to:
  /// **'STORE SETTINGS'**
  String get storeSettings;

  /// No description provided for @printerConnection.
  ///
  /// In en, this message translates to:
  /// **'Printer Connection'**
  String get printerConnection;

  /// No description provided for @receiptCustomization.
  ///
  /// In en, this message translates to:
  /// **'Receipt Customization'**
  String get receiptCustomization;

  /// No description provided for @storeInformation.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInformation;

  /// No description provided for @employeeManagement.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get employeeManagement;

  /// No description provided for @broadcastNotification.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Notification'**
  String get broadcastNotification;

  /// No description provided for @accountAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & SECURITY'**
  String get accountAndSecurity;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @dataSynchronization.
  ///
  /// In en, this message translates to:
  /// **'Data Synchronization'**
  String get dataSynchronization;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @logoutApp.
  ///
  /// In en, this message translates to:
  /// **'Logout Application'**
  String get logoutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @confirmLogoutDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of the application? Your session will be terminated.'**
  String get confirmLogoutDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yesLogout.
  ///
  /// In en, this message translates to:
  /// **'Yes, Logout'**
  String get yesLogout;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @logoutStore.
  ///
  /// In en, this message translates to:
  /// **'Leave Store'**
  String get logoutStore;

  /// No description provided for @confirmLeaveStore.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave the store {storeName}? You will not be able to access this store again without a new invitation code.'**
  String confirmLeaveStore(String storeName);

  /// No description provided for @yesLeave.
  ///
  /// In en, this message translates to:
  /// **'Yes, Leave'**
  String get yesLeave;

  /// No description provided for @leaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have left the store.'**
  String get leaveSuccess;

  /// No description provided for @leaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave the store: {error}'**
  String leaveFailed(String error);

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS'**
  String get analytics;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @smartAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Smart Analytics'**
  String get smartAnalytics;

  /// No description provided for @cashierOperational.
  ///
  /// In en, this message translates to:
  /// **'CASHIER OPERATIONAL'**
  String get cashierOperational;

  /// No description provided for @cashierPos.
  ///
  /// In en, this message translates to:
  /// **'Cashier (POS)'**
  String get cashierPos;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @tableMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Table Monitoring'**
  String get tableMonitoring;

  /// No description provided for @tableManagement.
  ///
  /// In en, this message translates to:
  /// **'Table Management'**
  String get tableManagement;

  /// No description provided for @manageStock.
  ///
  /// In en, this message translates to:
  /// **'Manage Stock'**
  String get manageStock;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @printAndReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print & Receipt'**
  String get printAndReceipt;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'SUPER ADMIN'**
  String get superAdmin;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @selectStore.
  ///
  /// In en, this message translates to:
  /// **'Select Store'**
  String get selectStore;

  /// No description provided for @tapToChangeOutlet.
  ///
  /// In en, this message translates to:
  /// **'Tap to change outlet'**
  String get tapToChangeOutlet;

  /// No description provided for @selectStoreOutlet.
  ///
  /// In en, this message translates to:
  /// **'Select Store / Outlet'**
  String get selectStoreOutlet;

  /// No description provided for @selectStoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the store you want to manage now.'**
  String get selectStoreDescription;

  /// No description provided for @noStoreFound.
  ///
  /// In en, this message translates to:
  /// **'No store found'**
  String get noStoreFound;

  /// No description provided for @manageAddStore.
  ///
  /// In en, this message translates to:
  /// **'Manage / Add Store'**
  String get manageAddStore;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String failedToLoad(String error);

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @cashierTab.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashierTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @reportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTab;

  /// No description provided for @menuTab.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTab;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @transactionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistoryTitle;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics Report'**
  String get reportsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @pressAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press once more to exit'**
  String get pressAgainToExit;

  /// No description provided for @dashboardHeader.
  ///
  /// In en, this message translates to:
  /// **'DASHBOARD'**
  String get dashboardHeader;

  /// No description provided for @performanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Performance Summary'**
  String get performanceSummary;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @revenueToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get revenueToday;

  /// No description provided for @revenueThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Revenue'**
  String get revenueThisWeek;

  /// No description provided for @revenueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month\'s Revenue'**
  String get revenueThisMonth;

  /// No description provided for @transactionsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Transactions'**
  String get transactionsToday;

  /// No description provided for @transactionsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Transactions'**
  String get transactionsThisWeek;

  /// No description provided for @transactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month\'s Transactions'**
  String get transactionsThisMonth;

  /// No description provided for @transactionsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Transactions Completed'**
  String get transactionsCompleted;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @activeProducts.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProducts;

  /// No description provided for @salesPerformance.
  ///
  /// In en, this message translates to:
  /// **'Sales Performance'**
  String get salesPerformance;

  /// No description provided for @revenueTrend7Days.
  ///
  /// In en, this message translates to:
  /// **'Revenue trend last 7 days'**
  String get revenueTrend7Days;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACCESS'**
  String get quickAccess;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @openNewCashier.
  ///
  /// In en, this message translates to:
  /// **'Open new cashier'**
  String get openNewCashier;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @manageProductStock.
  ///
  /// In en, this message translates to:
  /// **'Manage product stock'**
  String get manageProductStock;

  /// No description provided for @setupTableLayout.
  ///
  /// In en, this message translates to:
  /// **'Set up table layout'**
  String get setupTableLayout;

  /// No description provided for @kitchenMonitor.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Monitor'**
  String get kitchenMonitor;

  /// No description provided for @kdsDisplay.
  ///
  /// In en, this message translates to:
  /// **'KDS Display'**
  String get kdsDisplay;

  /// No description provided for @performanceAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Performance analysis'**
  String get performanceAnalysis;

  /// No description provided for @appConfiguration.
  ///
  /// In en, this message translates to:
  /// **'App configuration'**
  String get appConfiguration;

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{name} has been added to cart.'**
  String productAddedToCart(String name);

  /// No description provided for @selectTable.
  ///
  /// In en, this message translates to:
  /// **'Select Table'**
  String get selectTable;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @noTableAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tables available'**
  String get noTableAvailable;

  /// No description provided for @tableOccupied.
  ///
  /// In en, this message translates to:
  /// **'Table Occupied'**
  String get tableOccupied;

  /// No description provided for @tableOccupiedDesc.
  ///
  /// In en, this message translates to:
  /// **'This table is currently occupied. Do you want to add orders to this table?'**
  String get tableOccupiedDesc;

  /// No description provided for @addOrder.
  ///
  /// In en, this message translates to:
  /// **'Add Order'**
  String get addOrder;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProduct;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @sortByNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortByNameAsc;

  /// No description provided for @sortByNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get sortByNameDesc;

  /// No description provided for @sortByPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get sortByPriceAsc;

  /// No description provided for @sortByPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get sortByPriceDesc;

  /// No description provided for @sortByStockDesc.
  ///
  /// In en, this message translates to:
  /// **'Stock: High to Low'**
  String get sortByStockDesc;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @stockLow.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get stockLow;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @totalBelanja.
  ///
  /// In en, this message translates to:
  /// **'Total Items Price'**
  String get totalBelanja;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @confirmClearCart.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the cart? This action cannot be undone.'**
  String get confirmClearCart;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @noProductsYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start selling.'**
  String get noProductsYetDesc;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @manageProduct.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get manageProduct;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @productAddedScan.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String productAddedScan(String name);

  /// No description provided for @skuNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'SKU/Barcode \"{code}\" is not registered!'**
  String skuNotRegistered(String code);

  /// No description provided for @scanSkuBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan SKU / Barcode'**
  String get scanSkuBarcode;

  /// No description provided for @currentScanSession.
  ///
  /// In en, this message translates to:
  /// **'Current Scan Session'**
  String get currentScanSession;

  /// No description provided for @pointCameraToBarcode.
  ///
  /// In en, this message translates to:
  /// **'Point camera to product barcode'**
  String get pointCameraToBarcode;

  /// No description provided for @totalSession.
  ///
  /// In en, this message translates to:
  /// **'Total Session'**
  String get totalSession;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @minPurchase.
  ///
  /// In en, this message translates to:
  /// **'Min. purchase {minPurchase}'**
  String minPurchase(String minPurchase);

  /// No description provided for @invalidVoucher.
  ///
  /// In en, this message translates to:
  /// **'Invalid voucher code'**
  String get invalidVoucher;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// No description provided for @orderDetail.
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get orderDetail;

  /// No description provided for @tableWithColon.
  ///
  /// In en, this message translates to:
  /// **'Table: {tableName}'**
  String tableWithColon(String tableName);

  /// No description provided for @cartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartIsEmpty;

  /// No description provided for @haveVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Have a voucher code?'**
  String get haveVoucherCode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @voucherWithColon.
  ///
  /// In en, this message translates to:
  /// **'Voucher: {voucherCode}'**
  String voucherWithColon(String voucherCode);

  /// No description provided for @savedAmount.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount}'**
  String savedAmount(String amount);

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @voucherDiscount.
  ///
  /// In en, this message translates to:
  /// **'Voucher Discount'**
  String get voucherDiscount;

  /// No description provided for @totalPayment.
  ///
  /// In en, this message translates to:
  /// **'Total Payment'**
  String get totalPayment;

  /// No description provided for @saveToTable.
  ///
  /// In en, this message translates to:
  /// **'Save to Table'**
  String get saveToTable;

  /// No description provided for @orderSavedToTable.
  ///
  /// In en, this message translates to:
  /// **'Order successfully saved to table.'**
  String get orderSavedToTable;

  /// No description provided for @failedToSaveOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to save order: {error}'**
  String failedToSaveOrder(String error);

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get continueToPayment;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash Received'**
  String get cashReceived;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount...'**
  String get enterAmount;

  /// No description provided for @confirmAndSaveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save Transaction'**
  String get confirmAndSaveTransaction;

  /// No description provided for @totalBill.
  ///
  /// In en, this message translates to:
  /// **'TOTAL BILL'**
  String get totalBill;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'CHANGE'**
  String get change;

  /// No description provided for @insufficientCash.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Cash'**
  String get insufficientCash;

  /// No description provided for @cashNotSufficient.
  ///
  /// In en, this message translates to:
  /// **'Cash is not sufficient'**
  String get cashNotSufficient;

  /// No description provided for @activeStoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'Active store not found. Please select a store first.'**
  String get activeStoreNotFound;

  /// No description provided for @transactionSynced.
  ///
  /// In en, this message translates to:
  /// **'Transaction of {amount} has been saved & synced.'**
  String transactionSynced(String amount);

  /// No description provided for @transactionSavedLocal.
  ///
  /// In en, this message translates to:
  /// **'Transaction of {amount} saved locally (Not Synced).'**
  String transactionSavedLocal(String amount);

  /// No description provided for @failedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWithReason(String error);

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccess;

  /// No description provided for @paymentSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your transaction has been successfully recorded in the system. Please choose the next step.'**
  String get paymentSuccessDesc;

  /// No description provided for @toHistory.
  ///
  /// In en, this message translates to:
  /// **'To History'**
  String get toHistory;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @receiptPrinting.
  ///
  /// In en, this message translates to:
  /// **'Receipt is printing.'**
  String get receiptPrinting;

  /// No description provided for @failedToPrint.
  ///
  /// In en, this message translates to:
  /// **'Failed to print: {error}'**
  String failedToPrint(String error);

  /// No description provided for @digitalReceipt.
  ///
  /// In en, this message translates to:
  /// **'Digital Receipt'**
  String get digitalReceipt;

  /// No description provided for @transactionNo.
  ///
  /// In en, this message translates to:
  /// **'Transaction No.'**
  String get transactionNo;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @cashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashier;

  /// No description provided for @parzelloStaff.
  ///
  /// In en, this message translates to:
  /// **'Parzello Staff'**
  String get parzelloStaff;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @scanToViewOnlineReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan to view online receipt'**
  String get scanToViewOnlineReceipt;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printing;

  /// No description provided for @setPrinter.
  ///
  /// In en, this message translates to:
  /// **'Setup Printer'**
  String get setPrinter;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @connectPrinter.
  ///
  /// In en, this message translates to:
  /// **'Connect Printer'**
  String get connectPrinter;

  /// No description provided for @connectPrinterDesc.
  ///
  /// In en, this message translates to:
  /// **'Select your Bluetooth printer to print receipt directly.'**
  String get connectPrinterDesc;

  /// No description provided for @noBluetoothPrinterFound.
  ///
  /// In en, this message translates to:
  /// **'No paired Bluetooth printers found.'**
  String get noBluetoothPrinterFound;

  /// No description provided for @thermalPrinter.
  ///
  /// In en, this message translates to:
  /// **'Thermal Printer'**
  String get thermalPrinter;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @splitBillWithTable.
  ///
  /// In en, this message translates to:
  /// **'Split Bill - Table {tableName}'**
  String splitBillWithTable(String tableName);

  /// No description provided for @pricePerItem.
  ///
  /// In en, this message translates to:
  /// **'{price} / item'**
  String pricePerItem(String price);

  /// No description provided for @totalSelected.
  ///
  /// In en, this message translates to:
  /// **'Total Selected'**
  String get totalSelected;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @searchTransaction.
  ///
  /// In en, this message translates to:
  /// **'Search transaction...'**
  String get searchTransaction;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @smartAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Stock & trend predictions with AI'**
  String get smartAnalyticsDesc;

  /// No description provided for @realTimeData.
  ///
  /// In en, this message translates to:
  /// **'Real-time data'**
  String get realTimeData;

  /// No description provided for @noSalesData.
  ///
  /// In en, this message translates to:
  /// **'No sales data'**
  String get noSalesData;

  /// No description provided for @salesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales Trend'**
  String get salesTrend;

  /// No description provided for @noTopProductsData.
  ///
  /// In en, this message translates to:
  /// **'No top products sold data'**
  String get noTopProductsData;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get topProducts;

  /// No description provided for @highestSalesVolume.
  ///
  /// In en, this message translates to:
  /// **'Highest sales volume'**
  String get highestSalesVolume;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'sold'**
  String get sold;

  /// No description provided for @salesTrendToday.
  ///
  /// In en, this message translates to:
  /// **'SALES TREND (TODAY)'**
  String get salesTrendToday;

  /// No description provided for @salesTrend7Days.
  ///
  /// In en, this message translates to:
  /// **'SALES TREND (7 DAYS)'**
  String get salesTrend7Days;

  /// No description provided for @salesTrendThisMonth.
  ///
  /// In en, this message translates to:
  /// **'SALES TREND (THIS MONTH)'**
  String get salesTrendThisMonth;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @aiProFeature.
  ///
  /// In en, this message translates to:
  /// **'AI PRO FEATURE'**
  String get aiProFeature;

  /// No description provided for @smartAnalyticsLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'The AI-powered Smart Analytics feature is under active development to bring you the best business projections.'**
  String get smartAnalyticsLockedDesc;

  /// No description provided for @productCatalog.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get productCatalog;

  /// No description provided for @manageYourInventory.
  ///
  /// In en, this message translates to:
  /// **'Manage your item inventory'**
  String get manageYourInventory;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteProductConfirm(String name);

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @productDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product successfully deleted'**
  String get productDeletedSuccess;

  /// No description provided for @productDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product: {error}'**
  String productDeleteFailed(String error);

  /// No description provided for @searchNameOrSku.
  ///
  /// In en, this message translates to:
  /// **'Search name or SKU...'**
  String get searchNameOrSku;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @productNotFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Try using another keyword or add a new product to your catalog.'**
  String get productNotFoundDesc;

  /// No description provided for @resetFilter.
  ///
  /// In en, this message translates to:
  /// **'Reset Filter'**
  String get resetFilter;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'Low: {count}'**
  String lowStockCount(int count);

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String stockCount(int count);

  /// No description provided for @waitingForSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting for cloud sync'**
  String get waitingForSync;

  /// No description provided for @skuCopied.
  ///
  /// In en, this message translates to:
  /// **'SKU successfully copied to clipboard.'**
  String get skuCopied;

  /// No description provided for @barcodeShareText.
  ///
  /// In en, this message translates to:
  /// **'Barcode for {name} ({sku})'**
  String barcodeShareText(String name, String sku);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String shareFailed(String error);

  /// No description provided for @productBarcode.
  ///
  /// In en, this message translates to:
  /// **'Product Barcode'**
  String get productBarcode;

  /// No description provided for @copySku.
  ///
  /// In en, this message translates to:
  /// **'Copy SKU'**
  String get copySku;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @searchCategory.
  ///
  /// In en, this message translates to:
  /// **'Search category...'**
  String get searchCategory;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @noCategoriesYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a new category to start grouping your products.'**
  String get noCategoriesYetDesc;

  /// No description provided for @viewProducts.
  ///
  /// In en, this message translates to:
  /// **'View Products'**
  String get viewProducts;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @fillCategoryInfo.
  ///
  /// In en, this message translates to:
  /// **'Fill category details completely.'**
  String get fillCategoryInfo;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Food, Beverage...'**
  String get categoryNameExample;

  /// No description provided for @categoryNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryNameEmpty;

  /// No description provided for @categoryUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category successfully updated'**
  String get categoryUpdatedSuccess;

  /// No description provided for @categoryAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category successfully added'**
  String get categoryAddedSuccess;

  /// No description provided for @categoryActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String categoryActionFailed(String error);

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @categoryDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category successfully deleted'**
  String get categoryDeletedSuccess;

  /// No description provided for @categoryDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String categoryDeleteFailed(String error);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @randomSkuCreated.
  ///
  /// In en, this message translates to:
  /// **'Random SKU successfully created'**
  String get randomSkuCreated;

  /// No description provided for @barcodeFor.
  ///
  /// In en, this message translates to:
  /// **'Barcode for {productName} ({sku})'**
  String barcodeFor(String productName, String sku);

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name...'**
  String get enterProductName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No Category'**
  String get noCategory;

  /// No description provided for @loadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// No description provided for @errorCategories.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorCategories(String error);

  /// No description provided for @skuBarcode.
  ///
  /// In en, this message translates to:
  /// **'SKU / Barcode'**
  String get skuBarcode;

  /// No description provided for @scanOrTypeSku.
  ///
  /// In en, this message translates to:
  /// **'Scan or type SKU...'**
  String get scanOrTypeSku;

  /// No description provided for @generateRandomSku.
  ///
  /// In en, this message translates to:
  /// **'Generate Random SKU'**
  String get generateRandomSku;

  /// No description provided for @scanBarcodeCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode (Camera)'**
  String get scanBarcodeCamera;

  /// No description provided for @barcodePreview.
  ///
  /// In en, this message translates to:
  /// **'Barcode Preview'**
  String get barcodePreview;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @initialStock.
  ///
  /// In en, this message translates to:
  /// **'Initial Stock'**
  String get initialStock;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProduct;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapToAddPhoto;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get productNameRequired;

  /// No description provided for @productSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String productSaveFailed(String error);

  /// No description provided for @monitorAndUpdateStock.
  ///
  /// In en, this message translates to:
  /// **'Monitor and update your product stock'**
  String get monitorAndUpdateStock;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @stockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock of {productName} updated to {stock}'**
  String stockUpdated(String productName, int stock);

  /// No description provided for @stockUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update stock: {error}'**
  String stockUpdateFailed(String error);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to access the POS dashboard.'**
  String get loginSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @useRegisteredAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a registered account.'**
  String get useRegisteredAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUpHere.
  ///
  /// In en, this message translates to:
  /// **'Sign up here'**
  String get signUpHere;

  /// No description provided for @emailPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and Password cannot be empty'**
  String get emailPasswordRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Failed: {error}'**
  String googleSignInFailed(String error);

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start managing your business with a modern POS system.'**
  String get registerSubtitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerInstructions.
  ///
  /// In en, this message translates to:
  /// **'Complete the details below to create an account.'**
  String get registerInstructions;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNow;

  /// No description provided for @orRegisterWith.
  ///
  /// In en, this message translates to:
  /// **'OR REGISTER WITH'**
  String get orRegisterWith;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @loginHere.
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get loginHere;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please check your email.'**
  String get registrationSuccess;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed: {error}'**
  String registrationFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

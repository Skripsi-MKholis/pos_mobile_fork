import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/features/pos/presentation/widgets/cart_detail_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';
import 'package:intl/intl.dart';

import 'package:pos_mobile/features/pos/providers/table_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  // Optimization: Debouncer prevents expensive UI rebuilds and local filtering on every keystroke.
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _sortOption = 'name_asc';

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchSubmitted(String value, List<Product> products) {
    if (value.trim().isEmpty) return;

    final code = value.trim().toLowerCase();
    Product? foundProduct;
    for (final p in products) {
      if ((p.sku != null && p.sku!.trim().toLowerCase() == code) ||
          (p.barcode != null && p.barcode!.trim().toLowerCase() == code)) {
        foundProduct = p;
        break;
      }
    }

    if (foundProduct != null) {
      ref.read(cartNotifierProvider.notifier).addItem(foundProduct);
      HapticFeedback.lightImpact();

      mySnackBar(
        context: context,
        text: AppLocalizations.of(context)!.productAddedToCart(foundProduct.name),
        status: ToastStatus.success,
      );

      _searchController.clear();
      setState(() {
        _searchQuery = '';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _openBarcodeScanner(List<Product> products) {
    FocusScope.of(context).unfocus();
    final currentLocale = Localizations.localeOf(context).toString();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Show over bottom bar
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BarcodeScannerModal(
        products: products,
        cartNotifier: ref.read(cartNotifierProvider.notifier),
        currencyFormat: NumberFormat.currency(
          locale: currentLocale,
          symbol: 'Rp ',
          decimalDigits: 0,
        ),
      ),
    ).then((_) {
      _searchFocusNode.unfocus();
    });
  }

  Future<void> _showTablePicker(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();
    final currentTable = ref.read(cartNotifierProvider).selectedTable;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Show over bottom bar
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final tablesAsync = ref.watch(tableNotifierProvider);
          return Container(
            decoration: BoxDecoration(
              color: ShadTheme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectTable,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentTable != null)
                      ShadButton.ghost(
                        onPressed: () {
                          ref
                              .read(cartNotifierProvider.notifier)
                              .selectTable(null);
                          Navigator.pop(context);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.reset,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                tablesAsync.when(
                  data: (tables) => tables.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)!.noTableAvailable))
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: tables.map((table) {
                            final isSelected = currentTable?.id == table.id;
                            final isOccupied = table.status == 'occupied';

                            return InkWell(
                              onTap: () async {
                                if (isOccupied) {
                                  final confirmed = await showShadDialog<bool>(
                                    context: context,
                                    builder: (context) => ShadDialog(
                                      title: Text(AppLocalizations.of(context)!.tableOccupied),
                                      description: Text(
                                        AppLocalizations.of(context)!.tableOccupiedDesc,
                                      ),
                                      actions: [
                                        ShadButton.outline(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(AppLocalizations.of(context)!.cancel),
                                        ),
                                        ShadButton(
                                          backgroundColor: Warna.primary,
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(
                                            AppLocalizations.of(context)!.addOrder,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    // Load existing items for this table
                                    final monitoring = ref
                                        .read(tableMonitoringProvider)
                                        .value;
                                    final tableOrder = monitoring?.firstWhere(
                                      (o) => o.table.id == table.id,
                                    );

                                    if (tableOrder != null &&
                                        tableOrder.transaction != null) {
                                      final products =
                                          ref
                                              .read(productNotifierProvider)
                                              .value ??
                                          [];
                                      final List<CartItem> items = [];

                                      for (var item in tableOrder.items) {
                                        final product = products.firstWhere(
                                          (p) =>
                                              p.supabaseId ==
                                              item['product_id'],
                                          orElse: () => Product(
                                            supabaseId: item['product_id'],
                                            storeId: item['store_id'] ?? '',
                                            name: item['product_name'],
                                            price: (item['unit_price'] as num)
                                                .toDouble(),
                                            stockQuantity: 0,
                                          ),
                                        );
                                        items.add(
                                          CartItem(
                                            product: product,
                                            quantity: item['quantity'],
                                          ),
                                        );
                                      }

                                      ref
                                          .read(cartNotifierProvider.notifier)
                                          .clearCart();
                                      ref
                                          .read(cartNotifierProvider.notifier)
                                          .setItems(items);
                                      ref
                                          .read(cartNotifierProvider.notifier)
                                          .setTransactionId(
                                            tableOrder.transaction?['id'],
                                          );
                                    }

                                    ref
                                        .read(cartNotifierProvider.notifier)
                                        .selectTable(table);
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                } else {
                                  ref
                                      .read(cartNotifierProvider.notifier)
                                      .selectTable(table);
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                width: 80,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Warna.primary
                                      : (isOccupied
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : ShadTheme.of(
                                                context,
                                              ).colorScheme.muted),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Warna.primary
                                        : (isOccupied
                                              ? Colors.red.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.transparent),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      TablerIcons.armchair,
                                      size: 24,
                                      color: isSelected
                                          ? Colors.black
                                          : (isOccupied
                                                ? Colors.red
                                                : Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      table.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.black
                                            : (isOccupied ? Colors.red : null),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    ).then((_) => _searchFocusNode.unfocus());
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final isAdmin = role?.toLowerCase() == 'owner';
    final productsAsync = ref.watch(productNotifierProvider);
    final products = productsAsync.value ?? [];
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final cartItems = cartState.items;
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          // Top Toolbar with Table Selection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    placeholder: Text(l10n.searchProduct),
                    leading: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(TablerIcons.search, size: 20),
                    ),
                    decoration: ShadDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.3),
                      border: ShadBorder.all(
                        color: theme.colorScheme.border.withValues(alpha: 0.5),
                        radius: BorderRadius.circular(24),
                      ),
                    ),
                    onChanged: (value) => _debouncer.run(
                      () => setState(() => _searchQuery = value),
                    ),
                    onSubmitted: (value) =>
                        _handleSearchSubmitted(value, products),
                    trailing: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _debouncer
                                  .dispose(); // Cancel any pending debounced search update
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(TablerIcons.x, size: 18),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: l10n.scanBarcode,
                  child: ShadIconButton.outline(
                    onPressed: () => _openBarcodeScanner(products),
                    icon: const Icon(TablerIcons.barcode, size: 20),
                    width: 48,
                    height: 48,
                    decoration: ShadDecoration(
                      border: ShadBorder.all(
                        color: theme.colorScheme.border.withValues(alpha: 0.5),
                        radius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                productsAsync.when(
                  data: (products) {
                    final activeStoreAsync = ref.watch(activeStoreProvider);
                    final activeStore = activeStoreAsync.value;
                    final settings =
                        activeStore?['settings'] as Map<String, dynamic>?;
                    final features =
                        settings?['features'] as Map<String, dynamic>?;
                    final hasTables =
                        features?['tables'] == true &&
                        activeStore ==
                            null; // Sembunyikan untuk sementara waktu

                    if (!hasTables) return const SizedBox.shrink();

                    if (cartState.selectedTable != null) {
                      return ShadButton(
                        onPressed: () => _showTablePicker(context, ref),
                        leading: const Icon(
                          TablerIcons.armchair,
                          size: 18,
                          color: Colors.black,
                        ),
                        child: Text(
                          cartState.selectedTable!.name,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    } else {
                      return ShadButton.outline(
                        onPressed: () => _showTablePicker(context, ref),
                        leading: const Icon(TablerIcons.armchair, size: 18),
                        child: Text(l10n.table),
                      );
                    }
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Category Selector
          _buildCategorySelector(categoriesAsync),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(productNotifierProvider);
                ref.invalidate(categoryNotifierProvider);
                await ref.read(productNotifierProvider.future);
              },
              color: Warna.primary,
              backgroundColor: Colors.white,
              child: productsAsync.when(
                data: (products) {
                  // ⚡ Bolt: Hoist invariant query case conversion outside loop to save O(N) allocations.
                  final query = _searchQuery.toLowerCase();
                  var filteredProducts = products
                      .where(
                        (p) {
                          // ⚡ Bolt: Fast-path for cheap O(1) checks before expensive string operations
                          if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) return false;
                          if (query.isEmpty) return true;

                          return p.name.toLowerCase().contains(query) ||
                                (p.sku?.toLowerCase().contains(query) ?? false);
                        }
                      )
                      .toList();

                  // Apply sorting
                  switch (_sortOption) {
                    case 'name_asc':
                      filteredProducts.sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );
                      break;
                    case 'name_desc':
                      filteredProducts.sort(
                        (a, b) => b.name.toLowerCase().compareTo(
                          a.name.toLowerCase(),
                        ),
                      );
                      break;
                    case 'price_asc':
                      filteredProducts.sort(
                        (a, b) => a.price.compareTo(b.price),
                      );
                      break;
                    case 'price_desc':
                      filteredProducts.sort(
                        (a, b) => b.price.compareTo(a.price),
                      );
                      break;
                    case 'stock_desc':
                      filteredProducts.sort(
                        (a, b) => b.stockQuantity.compareTo(a.stockQuantity),
                      );
                      break;
                  }

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            TablerIcons.package,
                            size: 80,
                            color: Colors.grey[200],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noProductsYet,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noProductsYetDesc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          if (isAdmin) ...[
                            ShadButton(
                              onPressed: () => context.push('/products/add'),
                              leading: const Icon(TablerIcons.plus, size: 18),
                              child: Text(l10n.addProduct),
                            ),
                            const SizedBox(height: 12),
                            ShadButton.outline(
                              onPressed: () => context.push('/products'),
                              leading: const Icon(
                                TablerIcons.settings,
                                size: 18,
                              ),
                              child: Text(l10n.manageProduct),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            TablerIcons.search_off,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.productNotFound,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      cartItems.isNotEmpty ? 190 : 100,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final cartItem = cartItems.firstWhere(
                        (item) => item.product.supabaseId == product.supabaseId,
                        orElse: () => CartItem(product: product, quantity: 0),
                      );

                      return _buildProductCard(
                        context,
                        product,
                        cartItem,
                        cartNotifier,
                        currencyFormat,
                      );
                    },
                  );
                },
                loading: () => _buildProductSkeleton(context),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
                if (cartItems.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildCartSummary(context, cartNotifier, currencyFormat),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) => Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildSortButton(),
            const SizedBox(width: 8),
            _buildCategoryChip(null, AppLocalizations.of(context)!.all),
            ...categories.map((c) => _buildCategoryChip(c.supabaseId, c.name)),
          ],
        ),
      ),
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryChip(String? id, String name) {
    final isSelected = _selectedCategoryId == id;
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryId = id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Warna.primary
                : theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Warna.primary
                  : theme.colorScheme.border,
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : theme.colorScheme.foreground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    final theme = ShadTheme.of(context);
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true, // Show over bottom bar
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => _buildSortBottomSheet(sheetContext),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Icon(
          TablerIcons.arrows_sort,
          size: 18,
          color: theme.colorScheme.foreground,
        ),
      ),
    );
  }

  Widget _buildSortBottomSheet(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'label': l10n.sortByNameAsc, 'value': 'name_asc'},
      {'label': l10n.sortByNameDesc, 'value': 'name_desc'},
      {'label': l10n.sortByPriceAsc, 'value': 'price_asc'},
      {'label': l10n.sortByPriceDesc, 'value': 'price_desc'},
      {'label': l10n.sortByStockDesc, 'value': 'stock_desc'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sortBy,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...options.map(
                (opt) => ListTile(
                  title: Text(opt['label']!),
                  contentPadding: EdgeInsets.zero,
                  trailing: _sortOption == opt['value']
                      ? const Icon(TablerIcons.check, color: Warna.primary)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = opt['value']!);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    dynamic product,
    CartItem cartItem,
    CartNotifier cartNotifier,
    NumberFormat format,
  ) {
    final theme = ShadTheme.of(context);
    final isLowStock = product.stockQuantity < 10;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => cartNotifier.addItem(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: theme.colorScheme.muted.withValues(alpha: 0.3),
                      child: product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              maxHeightDiskCache: 250, // Resizes and caches optimized low-res image
                              maxWidthDiskCache: 250,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: theme.colorScheme.muted.withValues(alpha: 0.5),
                                highlightColor: theme.colorScheme.muted.withValues(alpha: 0.2),
                                child: Container(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  TablerIcons.package_off,
                                  size: 32,
                                  color: theme.colorScheme.mutedForeground.withValues(alpha: 0.4),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                TablerIcons.package,
                                size: 32,
                                color: theme.colorScheme.mutedForeground.withValues(alpha: 0.4),
                              ),
                            ),
                    ),
                    if (cartItem.quantity > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Warna.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${cartItem.quantity}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isLowStock && product.stockQuantity > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.stockLow,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else if (product.stockQuantity <= 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.outOfStock,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            format.format(product.price),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.muted.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.stockQuantity} pcs',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    CartNotifier cartNotifier,
    NumberFormat format,
  ) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalBelanja,
                    style: TextStyle(
                      color: theme.colorScheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    format.format(cartNotifier.totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (cartNotifier.totalItems > 0) ...[
              Tooltip(
                message: l10n.clearCart,
                child: ShadIconButton.outline(
                  onPressed: () => cartNotifier.clearCart(),
                  icon: const Icon(
                    TablerIcons.trash,
                    size: 18,
                    color: Colors.red,
                  ),
                  width: 48,
                  decoration: ShadDecoration(
                    border: ShadBorder.all(
                      color: theme.colorScheme.destructive,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ShadButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true, // Show over bottom bar
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CartDetailSheet(),
                ).then((_) => _searchFocusNode.unfocus());
              },
              child: Text(l10n.viewDetails),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSkeleton(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cartItems = ref.watch(cartNotifierProvider).items;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        cartItems.isNotEmpty ? 190 : 100,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: theme.colorScheme.muted.withOpacity(0.5),
        highlightColor: theme.colorScheme.muted.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _BarcodeScannerModal extends StatefulWidget {
  final List<Product> products;
  final CartNotifier cartNotifier;
  final NumberFormat currencyFormat;

  const _BarcodeScannerModal({
    required this.products,
    required this.cartNotifier,
    required this.currencyFormat,
  });

  @override
  State<_BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<_BarcodeScannerModal>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();

  // Scanned history in this session
  final List<Map<String, dynamic>> _sessionScanned = [];

  // Scanning state
  String? _lastScannedSku;
  DateTime? _lastScanTime;

  // Notification Toast Overlay inside scanner
  String? _notificationText;
  bool _isSuccessNotification = true;

  // Flash / Torch state
  bool _isTorchOn = false;

  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showNotification(String text, bool isSuccess) {
    setState(() {
      _notificationText = text;
      _isSuccessNotification = isSuccess;
    });

    // Auto hide after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _notificationText = null;
        });
      }
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcodeValue = barcodes.first.rawValue;
    if (barcodeValue == null || barcodeValue.trim().isEmpty) return;

    final code = barcodeValue.trim().toLowerCase();
    final now = DateTime.now();

    // 1.5 seconds debounce for the same barcode to prevent accidental multiple scans
    if (_lastScannedSku == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) {
      return;
    }

    _lastScannedSku = code;
    _lastScanTime = now;

    // Search product
    Product? foundProduct;
    for (final p in widget.products) {
      if ((p.sku != null && p.sku!.trim().toLowerCase() == code) ||
          (p.barcode != null && p.barcode!.trim().toLowerCase() == code)) {
        foundProduct = p;
        break;
      }
    }

    if (foundProduct != null) {
      // Add to cart
      widget.cartNotifier.addItem(foundProduct);

      // Haptic Feedback for success scan
      HapticFeedback.lightImpact();

      // Show success notification inside scanner
      _showNotification(AppLocalizations.of(context)!.productAddedScan(foundProduct.name), true);

      // Add to session history or increment if exists
      setState(() {
        final existingIndex = _sessionScanned.indexWhere(
          (item) =>
              (item['product'] as Product).supabaseId ==
              foundProduct!.supabaseId,
        );
        if (existingIndex != -1) {
          _sessionScanned[existingIndex]['quantity'] =
              _sessionScanned[existingIndex]['quantity'] + 1;
        } else {
          _sessionScanned.insert(0, {'product': foundProduct, 'quantity': 1});
        }
      });
    } else {
      // Double heavy vibrate for failed match
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
      });

      _showNotification(AppLocalizations.of(context)!.skuNotRegistered(barcodeValue), false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final size = MediaQuery.of(context).size;
    final totalSessionItems = _sessionScanned.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
    final totalSessionPrice = _sessionScanned.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item['product'] as Product).price * (item['quantity'] as int)),
    );

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            // Camera Scanner View
            Positioned.fill(
              bottom: 275, // Leave space for taller session history drawer
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),

            // Scanner Viewport cutout & glowing red/green scanner line
            Positioned.fill(
              bottom: 275,
              child: Stack(
                children: [
                  // Viewfinder cutout (translucent dark border around camera target)
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: size.width * 0.7,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scanning target corners
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: size.width * 0.7,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Stack(
                        children: [
                          // Custom corner markers
                          _buildCorner(
                            Alignment.topLeft,
                            rotateX: false,
                            rotateY: false,
                          ),
                          _buildCorner(
                            Alignment.topRight,
                            rotateX: true,
                            rotateY: false,
                          ),
                          _buildCorner(
                            Alignment.bottomLeft,
                            rotateX: false,
                            rotateY: true,
                          ),
                          _buildCorner(
                            Alignment.bottomRight,
                            rotateX: true,
                            rotateY: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Neon Green Animated Laser Line
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            -90 + (180 * _laserController.value),
                          ),
                          child: Container(
                            width: size.width * 0.65,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: Warna.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: Warna.primary.withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Top Header: Flash, Switch Camera, Title, Close Button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flash Toggle
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flashlight_off : Icons.flashlight_on,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _controller.toggleTorch();
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                    ),
                    Text(
                      AppLocalizations.of(context)!.scanSkuBarcode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(TablerIcons.x, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // Notifications Banner Overlay inside modal (gorgeous animated glassmorphism toast)
            if (_notificationText != null)
              Positioned(
                top: 70,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isSuccessNotification
                        ? Warna.primary.withOpacity(0.9)
                        : Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccessNotification
                            ? TablerIcons.circle_check
                            : TablerIcons.circle_x,
                        color: _isSuccessNotification
                            ? Colors.black
                            : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _notificationText!,
                          style: TextStyle(
                            color: _isSuccessNotification
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom session history drawer (white/theme background)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 290,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    // Drawer handle / Indicator
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header of the session list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.currentScanSession,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '$totalSessionItems Item',
                          style: TextStyle(
                            color: theme.colorScheme.mutedForeground,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Scanned items horizontally
                    Expanded(
                      child: _sessionScanned.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    TablerIcons.barcode,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.pointCameraToBarcode,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: _sessionScanned.length,
                              itemBuilder: (context, index) {
                                final item = _sessionScanned[index];
                                final Product product = item['product'];
                                final int quantity = item['quantity'];

                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(
                                    right: 12,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.muted.withOpacity(
                                      0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.currencyFormat.format(
                                          product.price,
                                        ),
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Qty: $quantity',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Warna.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              TablerIcons.check,
                                              size: 10,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Total session price & "Selesai" Action Button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.totalSession,
                                style: TextStyle(
                                  color: theme.colorScheme.mutedForeground,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                widget.currencyFormat.format(totalSessionPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ShadButton(
                          onPressed: () => Navigator.pop(context),
                          backgroundColor: Warna.primary,
                          child: Text(
                            AppLocalizations.of(context)!.done,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(
    Alignment alignment, {
    required bool rotateX,
    required bool rotateY,
  }) {
    return Align(
      alignment: alignment,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(rotateX ? -1.0 : 1.0, rotateY ? -1.0 : 1.0),
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Warna.primary, width: 4),
              left: BorderSide(color: Warna.primary, width: 4),
            ),
          ),
        ),
      ),
    );
  }
}

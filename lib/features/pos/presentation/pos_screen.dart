import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/features/pos/presentation/widgets/cart_detail_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

import 'package:pos_mobile/features/pos/providers/table_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _sortOption = 'name_asc';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
                    const Text(
                      'Pilih Meja',
                      style: TextStyle(
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
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                tablesAsync.when(
                  data: (tables) => tables.isEmpty
                      ? const Center(child: Text('Tidak ada meja tersedia'))
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
                                      title: const Text('Meja Terisi'),
                                      description: const Text(
                                        'Meja ini sedang digunakan. Ingin menambah pesanan ke meja ini?',
                                      ),
                                      actions: [
                                        ShadButton.outline(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Batal'),
                                        ),
                                        ShadButton(
                                          backgroundColor: Warna.primary,
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Tambah Pesanan',
                                            style: TextStyle(
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
                                      ? const Color(0xFF98D100)
                                      : (isOccupied
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : ShadTheme.of(
                                                context,
                                              ).colorScheme.muted),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF98D100)
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
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final cartItems = cartState.items;
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
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
                    placeholder: const Text('Cari produk...'),
                    leading: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(TablerIcons.search, size: 20),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                    trailing: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(TablerIcons.x, size: 18),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                productsAsync.when(
                  data: (products) {
                    final activeStoreAsync = ref.watch(activeStoreProvider);
                    final activeStore = activeStoreAsync.value;
                    final settings =
                        activeStore?['settings'] as Map<String, dynamic>?;
                    final features =
                        settings?['features'] as Map<String, dynamic>?;
                    const hasTables =
                        false; // Sembunyikan untuk sementara waktu

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
                        child: const Text('Meja'),
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(productNotifierProvider);
                ref.invalidate(categoryNotifierProvider);
                await ref.read(productNotifierProvider.future);
              },
              color: Warna.primary,
              backgroundColor: Colors.white,
              child: productsAsync.when(
                data: (products) {
                  var filteredProducts = products
                      .where(
                        (p) =>
                            (p.name.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                (p.sku?.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ??
                                    false)) &&
                            (_selectedCategoryId == null ||
                                p.categoryId == _selectedCategoryId),
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
                          const Text(
                            'Belum ada produk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tambahkan produk pertama Anda untuk\nmulai berjualan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          if (isAdmin) ...[
                            ShadButton(
                              onPressed: () => context.push('/products/add'),
                              leading: const Icon(TablerIcons.plus, size: 18),
                              child: const Text('Tambah Produk'),
                            ),
                            const SizedBox(height: 12),
                            ShadButton.outline(
                              onPressed: () => context.push('/products'),
                              leading: const Icon(
                                TablerIcons.settings,
                                size: 18,
                              ),
                              child: const Text('Kelola Produk'),
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
                          const Text(
                            'Produk tidak ditemukan',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
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
          ),
          if (cartItems.isNotEmpty)
            _buildCartSummary(context, cartNotifier, currencyFormat),

          if (cartItems.isEmpty)
            // Spacer for Floating Bottom Bar
            const SizedBox(height: 90),
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
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildSortButton(),
            const SizedBox(width: 8),
            _buildCategoryChip(null, 'Semua'),
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
                ? const Color(0xFF98D100)
                : theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF98D100)
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
    final options = [
      {'label': 'Nama (A-Z)', 'value': 'name_asc'},
      {'label': 'Nama (Z-A)', 'value': 'name_desc'},
      {'label': 'Harga Terendah', 'value': 'price_asc'},
      {'label': 'Harga Tertinggi', 'value': 'price_desc'},
      {'label': 'Stok Terbanyak', 'value': 'stock_desc'},
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
              const Text(
                'Urutkan Berdasarkan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...options.map(
                (opt) => ListTile(
                  title: Text(opt['label']!),
                  contentPadding: EdgeInsets.zero,
                  trailing: _sortOption == opt['value']
                      ? const Icon(TablerIcons.check, color: Color(0xFF98D100))
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

    return ShadCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: product.stockQuantity > 0
            ? () => cartNotifier.addItem(product)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted,
                      image: product.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrl == null
                        ? const Center(
                            child: Icon(
                              TablerIcons.package,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : null,
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
                          color: const Color(0xFF98D100),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
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
                          color: Colors.orange.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Stok Menipis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (product.stockQuantity <= 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: Text(
                            'HABIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        format.format(product.price),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${product.stockQuantity} pcs',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.mutedForeground,
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
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    CartNotifier cartNotifier,
    NumberFormat format,
  ) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.foreground.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Belanja',
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
              ShadIconButton.outline(
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
              child: const Text('Cek Detail'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSkeleton(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
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

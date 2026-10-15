import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/core/widgets/connectivity_status_bar.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';

class _CategoryVisual {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _CategoryVisual({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

_CategoryVisual _getCategoryVisual(String name, {bool isUncategorized = false}) {
  if (isUncategorized) {
    return _CategoryVisual(
      icon: TablerIcons.folder_off,
      bgColor: Colors.grey.shade100,
      iconColor: Colors.grey.shade600,
    );
  }

  final lower = name.toLowerCase().trim();

  // Beverages & Coffee
  if (lower.contains('kopi') ||
      lower.contains('coffee') ||
      lower.contains('espresso') ||
      lower.contains('latte') ||
      lower.contains('cappuccino')) {
    return const _CategoryVisual(
      icon: TablerIcons.coffee,
      bgColor: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
    );
  }
  if (lower.contains('minum') ||
      lower.contains('drink') ||
      lower.contains('jus') ||
      lower.contains('juice') ||
      lower.contains('tea') ||
      lower.contains('teh') ||
      lower.contains('boba') ||
      lower.contains('beverage')) {
    return const _CategoryVisual(
      icon: TablerIcons.cup,
      bgColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
    );
  }

  // Food & Dishes
  if (lower.contains('makan') ||
      lower.contains('food') ||
      lower.contains('nasi') ||
      lower.contains('mie') ||
      lower.contains('ayam') ||
      lower.contains('daging') ||
      lower.contains('soup') ||
      lower.contains('sop') ||
      lower.contains('soto') ||
      lower.contains('bakso')) {
    return const _CategoryVisual(
      icon: TablerIcons.tools_kitchen_2,
      bgColor: Color(0xFFFFEDD5),
      iconColor: Color(0xFFEA580C),
    );
  }

  // Bakery, Dessert, Snacks
  if (lower.contains('snack') ||
      lower.contains('camilan') ||
      lower.contains('roti') ||
      lower.contains('kue') ||
      lower.contains('cake') ||
      lower.contains('pastry') ||
      lower.contains('bakery') ||
      lower.contains('dessert') ||
      lower.contains('donat') ||
      lower.contains('donut')) {
    return const _CategoryVisual(
      icon: TablerIcons.cake,
      bgColor: Color(0xFFFCE7F3),
      iconColor: Color(0xFFDB2777),
    );
  }

  // Retail & Packages
  if (lower.contains('paket') ||
      lower.contains('bundle') ||
      lower.contains('combo') ||
      lower.contains('promo') ||
      lower.contains('hemat')) {
    return const _CategoryVisual(
      icon: TablerIcons.box,
      bgColor: Color(0xFFEDE9FE),
      iconColor: Color(0xFF7C3AED),
    );
  }

  // Fashion & Apparel
  if (lower.contains('baju') ||
      lower.contains('kaos') ||
      lower.contains('pakaian') ||
      lower.contains('fashion') ||
      lower.contains('celana') ||
      lower.contains('dress')) {
    return const _CategoryVisual(
      icon: TablerIcons.hanger,
      bgColor: Color(0xFFF3E8FF),
      iconColor: Color(0xFF9333EA),
    );
  }

  // Electronics & Gadgets
  if (lower.contains('elektronik') ||
      lower.contains('gadget') ||
      lower.contains('aksesoris') ||
      lower.contains('device') ||
      lower.contains('hp') ||
      lower.contains('phone')) {
    return const _CategoryVisual(
      icon: TablerIcons.device_mobile,
      bgColor: Color(0xFFCCFBF1),
      iconColor: Color(0xFF0D9488),
    );
  }

  // Fresh & Groceries
  if (lower.contains('buah') ||
      lower.contains('sayur') ||
      lower.contains('fruit') ||
      lower.contains('vegetable') ||
      lower.contains('fresh') ||
      lower.contains('segar')) {
    return const _CategoryVisual(
      icon: TablerIcons.leaf,
      bgColor: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
    );
  }

  // Service / Jasa
  if (lower.contains('jasa') ||
      lower.contains('service') ||
      lower.contains('ongkir') ||
      lower.contains('cuci')) {
    return const _CategoryVisual(
      icon: TablerIcons.sparkles,
      bgColor: Color(0xFFFEF9C3),
      iconColor: Color(0xFFCA8A04),
    );
  }

  // Default POS / Category
  return const _CategoryVisual(
    icon: TablerIcons.category,
    bgColor: Color(0xFFF2FCDA),
    iconColor: Color(0xFF4D7C0F),
  );
}

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  // Optimization: Debouncer prevents expensive UI rebuilds and local filtering on every keystroke.
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final productsAsync = ref.watch(productNotifierProvider);
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.manageCategories,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                isId
                    ? 'Atur kelompok produk untuk mempermudah transaksi kasir'
                    : 'Organize products to streamline POS transactions',
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.chevron_left, size: 20),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          toolbarHeight: 76,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConnectivityStatusBar(),

              // Search & Add Button Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ShadInput(
                            controller: _searchController,
                            placeholder: Text(
                              isId ? 'Cari kategori...' : l10n.searchCategory,
                            ),
                            leading: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(TablerIcons.search, size: 20),
                            ),
                            trailing: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(TablerIcons.x, size: 18),
                                    ),
                                  )
                                : null,
                            onChanged: (value) => _debouncer.run(
                              () => setState(() => _searchQuery = value),
                            ),
                            decoration: ShadDecoration(
                              border: ShadBorder.none,
                              color: const Color(0xFFF1F5F9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ShadButton(
                          backgroundColor: Warna.primary,
                          onPressed: () => _showCategoryForm(context),
                          leading: const Icon(TablerIcons.plus, size: 18, color: Warna.black),
                          child: Text(
                            isId ? 'Tambah' : 'Add',
                            style: const TextStyle(
                              color: Warna.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // CATEGORY LIST
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) {
                    final products = productsAsync.value ?? [];

                    final filtered = categories.where((c) {
                      return c.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }).toList();

                    final uncategorizedTitle = isId ? 'Tanpa Kategori' : 'Uncategorized';
                    final showUncategorized = _searchQuery.isEmpty ||
                        uncategorizedTitle.toLowerCase().contains(_searchQuery.toLowerCase());

                    if (showUncategorized) {
                      final uncategorizedCategory = Category()
                        ..id = -1
                        ..supabaseId = 'uncategorized'
                        ..storeId = ''
                        ..name = uncategorizedTitle
                        ..isSynced = true
                        ..isDeleted = false;
                      filtered.insert(0, uncategorizedCategory);
                    }

                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(categoryNotifierProvider.notifier)
                            .syncCategories(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.55,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _searchQuery.isNotEmpty
                                        ? TablerIcons.search_off
                                        : TablerIcons.category,
                                    size: 42,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? (isId ? 'Kategori Tidak Ditemukan' : 'Category Not Found')
                                      : l10n.noCategoriesYet,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.foreground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? (isId
                                          ? 'Tidak ada kategori yang cocok dengan "$_searchQuery"'
                                          : 'No categories match "$_searchQuery"')
                                      : l10n.noCategoriesYetDesc,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.mutedForeground,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  ShadButton.outline(
                                    child: Text(isId ? 'Reset Pencarian' : 'Reset Search'),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                                ] else ...[
                                  const SizedBox(height: 18),
                                  ShadButton(
                                    backgroundColor: Warna.primary,
                                    onPressed: () => _showCategoryForm(context),
                                    leading: const Icon(TablerIcons.plus, size: 16, color: Warna.black),
                                    child: Text(
                                      isId ? 'Buat Kategori Pertama' : 'Create First Category',
                                      style: const TextStyle(
                                        color: Warna.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Count total categorized vs uncategorized
                    final totalCustomCategories = categories.length;
                    final totalProducts = products.length;

                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(categoryNotifierProvider.notifier)
                          .syncCategories(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 14, bottom: 80),
                        itemCount: filtered.length + 1, // 1 for stats summary header
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildSummaryHeader(
                              context,
                              totalCustomCategories,
                              totalProducts,
                              isId,
                            );
                          }

                          final category = filtered[index - 1];
                          final productCount = products
                              .where((p) => category.supabaseId == 'uncategorized'
                                  ? p.categoryId == null
                                  : p.categoryId == category.supabaseId)
                              .length;

                          return _buildCategoryCard(
                            context,
                            category,
                            theme,
                            productCount,
                            isId,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    int totalCategories,
    int totalProducts,
    bool isId,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Warna.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(TablerIcons.category, size: 16, color: Color(0xFF3F6212)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCategories',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        isId ? 'Kategori Dibuat' : 'Categories',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(TablerIcons.box, size: 16, color: Color(0xFF0369A1)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalProducts',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        isId ? 'Total Produk' : 'Total Products',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Category category,
    ShadThemeData theme,
    int productCount,
    bool isId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isUncategorized = category.supabaseId == 'uncategorized';
    final visual = _getCategoryVisual(category.name, isUncategorized: isUncategorized);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUncategorized ? Colors.grey.shade200 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Tapping card opens the products in this category
            context.push(
              '/categories/products',
              extra: {'category': category},
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Contextual Colored Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visual.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    visual.icon,
                    size: 22,
                    color: visual.iconColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Middle: Category Name, Badges & Product Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isUncategorized && !category.isSynced)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Tooltip(
                                message: l10n.waitingForSync,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        TablerIcons.cloud_off,
                                        size: 11,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Sync',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: productCount > 0
                                  ? Warna.primary.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isId ? '$productCount Produk' : '$productCount Products',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: productCount > 0
                                    ? const Color(0xFF3F6212)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (isUncategorized) ...[
                            const SizedBox(width: 6),
                            Text(
                              isId ? '• Default sistem' : '• Default system',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right: Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View products shortcut
                    Tooltip(
                      message: l10n.viewProducts,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          TablerIcons.chevron_right,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    if (!isUncategorized) ...[
                      const SizedBox(width: 6),
                      // More Options Menu (Edit & Delete)
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            TablerIcons.dots_vertical,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showCategoryForm(context, category: category);
                          } else if (value == 'delete') {
                            _confirmDelete(context, category);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(TablerIcons.edit, size: 16, color: Colors.black87),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.editCategory,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(TablerIcons.trash, size: 16, color: Colors.red),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.deleteCategory,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, {Category? category}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = category != null;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final nameController = TextEditingController(text: category?.name);

    final suggestedCategories = [
      'Makanan',
      'Minuman',
      'Kopi & Teh',
      'Snack & Camilan',
      'Paket Hemat',
      'Pakaian',
      'Aksesoris',
      'Jasa',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final visual = _getCategoryVisual(nameController.text);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Header with Live Icon Preview
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: visual.bgColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              visual.icon,
                              size: 24,
                              color: visual.iconColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? l10n.editCategory : l10n.addCategory,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isId
                                      ? 'Ikon akan menyesuaikan otomatis sesuai nama'
                                      : 'Icon adapts dynamically based on name',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Input field
                      Text(
                        l10n.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ShadInput(
                        controller: nameController,
                        autofocus: true,
                        placeholder: Text(
                          isId ? 'Contoh: Makanan, Minuman Dingin...' : l10n.categoryNameExample,
                        ),
                        onChanged: (_) {
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 14),

                      // Quick Suggestions Chip
                      if (!isEditing) ...[
                        Text(
                          isId ? 'Saran Kategori Cepat:' : 'Quick Suggestions:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: suggestedCategories.map((sug) {
                            final sugVisual = _getCategoryVisual(sug);
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                nameController.text = sug;
                                setSheetState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(sugVisual.icon, size: 14, color: sugVisual.iconColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      sug,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: ShadButton.outline(
                              child: Text(l10n.cancel),
                              onPressed: () => Navigator.pop(bottomSheetContext),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShadButton(
                              backgroundColor: Warna.primary,
                              child: Text(
                                isEditing ? l10n.save : l10n.add,
                                style: const TextStyle(
                                  color: Warna.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                final text = nameController.text.trim();
                                if (text.isEmpty) {
                                  mySnackBar(
                                    context: context,
                                    text: l10n.categoryNameEmpty,
                                    status: ToastStatus.warning,
                                  );
                                  return;
                                }

                                try {
                                  if (isEditing) {
                                    await ref
                                        .read(categoryNotifierProvider.notifier)
                                        .updateCategory(
                                          supabaseId: category.supabaseId,
                                          name: text,
                                        );
                                  } else {
                                    await ref
                                        .read(categoryNotifierProvider.notifier)
                                        .addCategory(name: text);

                                    // Log to Firebase Analytics
                                    try {
                                      await AnalyticsService.instance.logCategoryCreation(
                                        categoryName: text,
                                      );
                                    } catch (_) {}
                                  }
                                  if (bottomSheetContext.mounted) {
                                    Navigator.pop(bottomSheetContext);
                                    mySnackBar(
                                      context: context,
                                      text: isEditing
                                          ? l10n.categoryUpdatedSuccess
                                          : l10n.categoryAddedSuccess,
                                      status: ToastStatus.success,
                                    );
                                  }
                                } catch (e) {
                                  if (bottomSheetContext.mounted) {
                                    mySnackBar(
                                      context: context,
                                      text: l10n.categoryActionFailed(e.toString()),
                                      status: ToastStatus.error,
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    final l10n = AppLocalizations.of(context)!;
    showShadDialog(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: Text(l10n.deleteCategory),
        description: Text(
          l10n.deleteCategoryConfirm(category.name),
        ),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ShadButton.destructive(
            child: Text(l10n.delete),
            onPressed: () async {
              try {
                await ref
                    .read(categoryNotifierProvider.notifier)
                    .deleteCategory(category.supabaseId);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  mySnackBar(
                    context: context,
                    text: l10n.categoryDeletedSuccess,
                    status: ToastStatus.success,
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  mySnackBar(
                    context: context,
                    text: l10n.categoryDeleteFailed(e.toString()),
                    status: ToastStatus.error,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}


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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.manageCategories,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isId
                    ? 'Kelola pengelompokan produk & etalase'
                    : 'Manage product grouping & catalog',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: const Color(0xFFE2E8F0),
              height: 1,
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.chevron_left, size: 19, color: Color(0xFF334155)),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          toolbarHeight: 70,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showCategoryForm(context),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Warna.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(TablerIcons.plus, size: 16, color: Colors.black),
                      const SizedBox(width: 5),
                      Text(
                        isId ? 'Tambah' : 'Add',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConnectivityStatusBar(),

              // Search Box Row (Matching Stock & Product styling)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: isId ? 'Cari kategori...' : l10n.searchCategory,
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        TablerIcons.search,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 40,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(
                                TablerIcons.x,
                                size: 15,
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 40,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (value) => _debouncer.run(
                      () => setState(() => _searchQuery = value),
                    ),
                  ),
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
                        color: Warna.primary,
                        onRefresh: () => ref.read(categoryNotifierProvider.notifier).syncCategories(),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.55,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _searchQuery.isNotEmpty
                                        ? TablerIcons.search_off
                                        : TablerIcons.category,
                                    size: 38,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? (isId ? 'Kategori Tidak Ditemukan' : 'Category Not Found')
                                      : l10n.noCategoriesYet,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? (isId
                                          ? 'Tidak ada kategori yang cocok dengan "$_searchQuery"'
                                          : 'No categories match "$_searchQuery"')
                                      : l10n.noCategoriesYetDesc,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                if (_searchQuery.isNotEmpty) ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F172A),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(TablerIcons.filter_off, size: 16),
                                    label: Text(isId ? 'Reset Pencarian' : 'Reset Search', style: const TextStyle(fontSize: 12.5)),
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Warna.primary,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _showCategoryForm(context),
                                    icon: const Icon(TablerIcons.plus, size: 16),
                                    label: Text(isId ? 'Buat Kategori' : 'Create Category', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final totalCustomCategories = categories.length;
                    final totalProducts = products.length;

                    return RefreshIndicator(
                      color: Warna.primary,
                      onRefresh: () => ref.read(categoryNotifierProvider.notifier).syncCategories(),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 80),
                        itemCount: filtered.length + 1,
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
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Warna.primary, strokeWidth: 2.5),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(TablerIcons.category, size: 14, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCategories',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isId ? 'Kategori' : 'Categories',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(TablerIcons.box, size: 14, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalProducts',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isId ? 'Total Produk' : 'Products',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: visual.bgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              visual.icon,
              size: 19,
              color: visual.iconColor,
            ),
          ),
          const SizedBox(width: 10),

          // Name & Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isUncategorized && !category.isSynced)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Tooltip(
                          message: l10n.waitingForSync,
                          child: const Icon(TablerIcons.cloud_off, size: 12, color: Color(0xFFF59E0B)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      isId ? '$productCount Produk' : '$productCount Products',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isUncategorized) ...[
                      const SizedBox(width: 4),
                      const Text('•', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                      const SizedBox(width: 4),
                      Text(
                        isId ? 'Default sistem' : 'System default',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Action Shortcuts
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // View Products in Category
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                tooltip: l10n.viewProducts,
                icon: const Icon(TablerIcons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () {
                  context.push(
                    '/categories/products',
                    extra: {'category': category},
                  );
                },
              ),
              if (!isUncategorized) ...[
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  tooltip: l10n.editCategory,
                  icon: const Icon(TablerIcons.edit, size: 16, color: Color(0xFF475569)),
                  onPressed: () => _showCategoryForm(context, category: category),
                ),
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  tooltip: l10n.deleteCategory,
                  icon: const Icon(TablerIcons.trash, size: 16, color: Color(0xFFDC2626)),
                  onPressed: () => _confirmDelete(context, category),
                ),
              ],
            ],
          ),
        ],
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: visual.bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              visual.icon,
                              size: 20,
                              color: visual.iconColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? l10n.editCategory : l10n.addCategory,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isId
                                      ? 'Ikon menyesuaikan otomatis sesuai nama'
                                      : 'Icon adapts dynamically based on name',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        l10n.categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: nameController,
                          autofocus: true,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: isId ? 'Contoh: Makanan, Minuman Dingin...' : l10n.categoryNameExample,
                            hintStyle: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (!isEditing) ...[
                        Text(
                          isId ? 'Saran Kategori Cepat:' : 'Quick Suggestions:',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: suggestedCategories.map((sug) {
                            final sugVisual = _getCategoryVisual(sug);
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                nameController.text = sug;
                                setSheetState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(sugVisual.icon, size: 13, color: sugVisual.iconColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      sug,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => Navigator.pop(bottomSheetContext),
                              child: Text(l10n.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Warna.primary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                isEditing ? l10n.save : l10n.add,
                                style: const TextStyle(fontWeight: FontWeight.w700),
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

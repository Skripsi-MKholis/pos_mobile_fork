import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final Category category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  String _searchQuery = '';

  Future<void> _unlinkProduct(Product product) async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final l10n = AppLocalizations.of(context)!;
    final localContext = context;

    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text(isId ? 'Keluarkan Produk?' : 'Remove from Category?'),
        description: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            isId
                ? 'Apakah Anda yakin ingin mengeluarkan "${product.name}" dari kategori "${widget.category.name}"?'
                : 'Are you sure you want to remove "${product.name}" from "${widget.category.name}"?',
          ),
        ),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text(isId ? 'Keluarkan' : 'Remove'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(productNotifierProvider.notifier)
            .updateProductCategory(product.supabaseId, null);

        if (!localContext.mounted) return;
        mySnackBar(
          context: localContext,
          text: isId
              ? 'Produk berhasil dikeluarkan dari kategori'
              : 'Product successfully removed from category',
          status: ToastStatus.success,
        );
      } catch (e) {
        if (!localContext.mounted) return;
        mySnackBar(
          context: localContext,
          text: 'Gagal: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  void _showAddProductsModal(List<Product> allProducts, List<Category> allCategories) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final localContext = context;
    
    // Filter out products that are already in this category
    final availableProducts = allProducts.where((p) => p.categoryId != widget.category.supabaseId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddProductsBottomSheet(
        availableProducts: availableProducts,
        category: widget.category,
        categories: allCategories,
        onAdd: (selectedProductIds) async {
          try {
            for (final id in selectedProductIds) {
              await ref
                  .read(productNotifierProvider.notifier)
                  .updateProductCategory(id, widget.category.supabaseId);
            }
            if (!localContext.mounted) return;
            mySnackBar(
              context: localContext,
              text: isId
                  ? 'Berhasil menambahkan produk ke kategori'
                  : 'Products successfully added to category',
              status: ToastStatus.success,
            );
          } catch (e) {
            if (!localContext.mounted) return;
            mySnackBar(
              context: localContext,
              text: 'Gagal: $e',
              status: ToastStatus.error,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final allCategories = categoriesAsync.value ?? [];
    final theme = ShadTheme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.currency(
      locale: locale,
      symbol: locale.startsWith('id') ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              isId ? 'Daftar produk terdaftar' : 'List of registered products',
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.chevron_left, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        toolbarHeight: 80,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Actions Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShadInput(
                    placeholder: Text(l10n.searchNameOrSku),
                    leading: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(TablerIcons.search, size: 20),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: ShadDecoration(
                      border: ShadBorder.none,
                      color: theme.colorScheme.muted.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  productsAsync.maybeWhen(
                    data: (products) => widget.category.supabaseId == 'uncategorized'
                        ? const SizedBox.shrink()
                        : SizedBox(
                            width: double.infinity,
                            child: ShadButton(
                              backgroundColor: Warna.primary,
                              onPressed: () => _showAddProductsModal(products, allCategories),
                              leading: const Icon(TablerIcons.plus, size: 18, color: Warna.black),
                              child: Text(
                                isId ? 'Tambah Produk Baru ke Kategori' : 'Add New Products to Category',
                                style: const TextStyle(
                                  color: Warna.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Products list
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // Hoist invariant string conversion outside of the loop for performance
                  final lowerQuery = _searchQuery.toLowerCase();
                  final filtered = products.where((p) {
                    final isInCategory = widget.category.supabaseId == 'uncategorized'
                        ? p.categoryId == null
                        : p.categoryId == widget.category.supabaseId;
                    final matchesSearch = p.name.toLowerCase().contains(lowerQuery) ||
                        (p.sku?.toLowerCase().contains(lowerQuery) ?? false);
                    return isInCategory && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              TablerIcons.package_off,
                              size: 48,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isId ? 'Kategori Kosong' : 'Category Empty',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isId
                                ? 'Belum ada produk terdaftar di kategori ini.'
                                : 'No products registered in this category yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.mutedForeground),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _buildProductItem(context, product, theme, format);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    Product product,
    ShadThemeData theme,
    NumberFormat format,
  ) {
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        maxHeightDiskCache: 120, // Resizes and caches optimized low-res image
                        maxWidthDiskCache: 120,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: theme.colorScheme.muted.withValues(alpha: 0.5),
                          highlightColor: theme.colorScheme.muted.withValues(alpha: 0.2),
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            TablerIcons.package_off,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      )
                    : (product.localImagePath != null
                        ? Image.file(
                            File(product.localImagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Icon(
                            TablerIcons.package,
                            color: theme.colorScheme.mutedForeground,
                            size: 24,
                          )),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format.format(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF5B9E00),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: isId ? 'Edit Produk' : 'Edit Product',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.push('/products/edit', extra: product),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        TablerIcons.edit,
                        size: 16,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                  ),
                ),
                if (widget.category.supabaseId != 'uncategorized') ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: isId ? 'Keluarkan dari Kategori' : 'Remove from Category',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _unlinkProduct(product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          TablerIcons.minus,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProductsBottomSheet extends StatefulWidget {
  final List<Product> availableProducts;
  final Category category;
  final List<Category> categories;
  final Function(List<String>) onAdd;

  const _AddProductsBottomSheet({
    required this.availableProducts,
    required this.category,
    required this.categories,
    required this.onAdd,
  });

  @override
  State<_AddProductsBottomSheet> createState() => _AddProductsBottomSheetState();
}

class _AddProductsBottomSheetState extends State<_AddProductsBottomSheet> {
  final Set<String> _selectedIds = {};
  String _sheetQuery = '';

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final theme = ShadTheme.of(context);

    // Hoist invariant string conversion outside of the loop for performance
    final lowerQuery = _sheetQuery.toLowerCase();
    final filtered = widget.availableProducts.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          (p.sku?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Indicator
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isId ? 'Tambahkan Produk' : 'Add Products',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  isId ? 'Ke "${widget.category.name}"' : 'To "${widget.category.name}"',
                  style: TextStyle(
                    color: theme.colorScheme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search inside Sheet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ShadInput(
              placeholder: Text(isId ? 'Cari nama produk...' : 'Search product name...'),
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(TablerIcons.search, size: 20),
              ),
              onChanged: (val) => setState(() => _sheetQuery = val),
              decoration: ShadDecoration(
                border: ShadBorder.none,
                color: theme.colorScheme.muted.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List of available products
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      isId ? 'Semua produk sudah memiliki kategori ini' : 'All products already have this category',
                      style: TextStyle(color: theme.colorScheme.mutedForeground),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final isSelected = _selectedIds.contains(product.supabaseId);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(product.supabaseId);
                            } else {
                              _selectedIds.add(product.supabaseId);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor: Warna.primary,
                                checkColor: Warna.black,
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.add(product.supabaseId);
                                    } else {
                                      _selectedIds.remove(product.supabaseId);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Builder(
                                      builder: (context) {
                                        Category? currentCat;
                                        if (product.categoryId != null) {
                                          for (final c in widget.categories) {
                                            if (c.supabaseId == product.categoryId) {
                                              currentCat = c;
                                              break;
                                            }
                                          }
                                        }
                                        final hasCat = currentCat != null;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: hasCat
                                                ? Warna.primary.withValues(alpha: 0.15)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            hasCat
                                                ? currentCat.name
                                                : (isId ? 'Tanpa Kategori' : 'No Category'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: hasCat
                                                  ? Colors.black87
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    child: Text(isId ? 'Batal' : 'Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadButton(
                    backgroundColor: Warna.primary,
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            widget.onAdd(_selectedIds.toList());
                            Navigator.pop(context);
                          },
                    child: Text(
                      isId ? 'Tambahkan (${_selectedIds.length})' : 'Add (${_selectedIds.length})',
                      style: const TextStyle(
                        color: Warna.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

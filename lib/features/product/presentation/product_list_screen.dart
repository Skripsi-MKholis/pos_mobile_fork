import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/widgets/parzello_table.dart';
import 'package:pos_mobile/core/widgets/connectivity_status_bar.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const ProductListScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  // Optimization: Debouncer prevents expensive UI rebuilds and local filtering on every keystroke.
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _showDeleteDialog(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Row(
          children: [
            Icon(TablerIcons.alert_triangle, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(l10n.deleteProduct),
          ],
        ),
        description: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l10n.deleteProductConfirm(product.name),
          ),
        ),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text(l10n.deletePermanently),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(productNotifierProvider.notifier)
            .deleteProduct(product.supabaseId);

        // Log to Firebase Analytics
        try {
          final categories = ref.read(categoryNotifierProvider).value;
          final categoryName = categories?.firstWhere(
              (c) => c.supabaseId == product.categoryId,
              orElse: () => Category()..name = 'Tanpa Kategori',
            ).name ?? 'Tanpa Kategori';

          await AnalyticsService.instance.logProductDeletion(categoryName: categoryName);
        } catch (_) {}

        if (mounted) {
          mySnackBar(
            context: context,
            text: l10n.productDeletedSuccess,
            status: ToastStatus.success,
          );
        }
      } catch (e) {
        if (mounted) {
          mySnackBar(
            context: context,
            text: l10n.productDeleteFailed(e.toString()),
            status: ToastStatus.error,
          );
        }
      }
    }
  }

  void _openBarcodeViewer(
    BuildContext context,
    Product product,
    String categoryName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _BarcodeViewerSheet(product: product, categoryName: categoryName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final theme = ShadTheme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.currency(
      locale: locale,
      symbol: locale.startsWith('id') ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.productCatalog,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                l10n.manageYourInventory,
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          toolbarHeight: 80,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ShadButton(
                size: ShadButtonSize.sm,
                backgroundColor: Warna.primary, // Lime Green
                foregroundColor: Colors.black,
                onPressed: () => context.push('/products/add'),
                leading: const Icon(TablerIcons.plus, size: 18),
                child: Text(
                  l10n.add,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

              const SizedBox(height: 8),

              // SEARCH & ACTIONS ROW
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ShadInput(
                        placeholder: Text(l10n.searchNameOrSku),
                        leading: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(TablerIcons.search, size: 20),
                        ),
                        onChanged: (value) => _debouncer.run(
                          () => setState(() => _searchQuery = value),
                        ),
                        decoration: ShadDecoration(
                          border: ShadBorder.none,
                          color: theme.colorScheme.muted.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: l10n.manageCategories,
                      child: ShadButton.outline(
                        onPressed: () => context.push('/categories'),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Icon(TablerIcons.category, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // CATEGORY CHIPS FILTER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: categoriesAsync.maybeWhen(
                  data: (categories) {
                    return SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.all),
                            selected: _selectedCategory == null,
                            selectedColor: Warna.primary,
                            backgroundColor: theme.colorScheme.muted
                                .withOpacity(0.3),
                            labelStyle: TextStyle(
                              color: _selectedCategory == null
                                  ? Colors.black
                                  : theme.colorScheme.foreground,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: _selectedCategory == null
                                    ? Colors.transparent
                                    : theme.colorScheme.border.withOpacity(0.3),
                              ),
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedCategory = null),
                          ),
                          ...categories.map((c) {
                            final isSelected =
                                _selectedCategory == c.supabaseId;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(c.name),
                                selected: isSelected,
                                selectedColor: Warna.primary,
                                backgroundColor: theme.colorScheme.muted
                                    .withOpacity(0.3),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : theme.colorScheme.foreground,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : theme.colorScheme.border.withOpacity(
                                            0.3,
                                          ),
                                  ),
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected
                                        ? c.supabaseId
                                        : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 4),

              // PRODUCT LIST
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filteredProducts = products.where((p) {
                      final matchesSearch =
                          p.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          (p.sku?.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ??
                              false);
                      final matchesCategory =
                          _selectedCategory == null ||
                          p.categoryId == _selectedCategory;
                      return matchesSearch && matchesCategory;
                    }).toList();

                    final categoryMap = categoriesAsync.maybeWhen(
                      data: (categories) => {
                        for (var c in categories) c.supabaseId: c.name,
                      },
                      orElse: () => <String, String>{},
                    );

                    if (filteredProducts.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(productNotifierProvider.notifier)
                            .syncProducts(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: _buildEmptyState(theme),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(productNotifierProvider.notifier)
                          .syncProducts(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final categoryName =
                              categoryMap[product.categoryId] ??
                              'Tanpa Kategori';
                          return _buildProductCard(
                            context,
                            product,
                            categoryName,
                            theme,
                            format,
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator(int stock, ShadThemeData theme) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (stock == 0) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = AppLocalizations.of(context)!.outOfStock;
      icon = TablerIcons.circle_x;
    } else if (stock <= 10) {
      bgColor = Colors.amber.shade50;
      textColor = Colors.amber.shade700;
      label = AppLocalizations.of(context)!.lowStockCount(stock);
      icon = TablerIcons.alert_triangle;
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      label = AppLocalizations.of(context)!.stockCount(stock);
      icon = TablerIcons.circle_check;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    String categoryName,
    ShadThemeData theme,
    NumberFormat format,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Product Image with beautiful border radius and shadow
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.border.withOpacity(0.6),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        maxHeightDiskCache: 150, // Resizes and caches optimized low-res image
                        maxWidthDiskCache: 150,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: theme.colorScheme.muted.withOpacity(0.5),
                          highlightColor: theme.colorScheme.muted.withOpacity(0.2),
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            TablerIcons.package_off,
                            color: Colors.grey,
                            size: 28,
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
                            size: 28,
                          )),
              ),
            ),
            const SizedBox(width: 14),

            // Product info: disusun per baris memakai lebar penuh agar
            // SKU panjang tidak menjepit nama/kategori/harga.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: nama + sync + aksi edit/hapus
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!product.isSynced)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Tooltip(
                            message: AppLocalizations.of(context)!.waitingForSync,
                            child: const Icon(
                              TablerIcons.cloud_off,
                              size: 14,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: AppLocalizations.of(context)!.edit,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              context.push('/products/edit', extra: product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted.withOpacity(0.3),
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
                      const SizedBox(width: 8),
                      Tooltip(
                        message: AppLocalizations.of(context)!.deleteProduct,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showDeleteDialog(product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              TablerIcons.trash,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 2: kategori + status stok
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.muted.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStockIndicator(product.stockQuantity, theme),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: harga + chip SKU (SKU di-ellipsis bila panjang)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          format.format(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF5B9E00), // Nice dark green
                          ),
                        ),
                      ),
                      if (product.sku != null && product.sku!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _openBarcodeViewer(context, product, categoryName);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    TablerIcons.barcode,
                                    size: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      product.sku!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.muted.withOpacity(0.5),
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
          AppLocalizations.of(context)!.productNotFound,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.productNotFoundDesc,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
        const SizedBox(height: 24),
        ShadButton.outline(
          onPressed: () {
            _debouncer.dispose(); // Cancel pending updates
            setState(() {
              _searchQuery = '';
              _selectedCategory = null;
            });
          },
          child: Text(AppLocalizations.of(context)!.resetFilter),
        ),
      ],
    );
  }
}

class _BarcodeViewerSheet extends StatefulWidget {
  final Product product;
  final String categoryName;

  const _BarcodeViewerSheet({
    required this.product,
    required this.categoryName,
  });

  @override
  State<_BarcodeViewerSheet> createState() => _BarcodeViewerSheetState();
}

class _BarcodeViewerSheetState extends State<_BarcodeViewerSheet> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareBarcodeCard() async {
    setState(() => _isSharing = true);
    try {
      // Small delay to allow the repaint boundary to layout fully
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/barcode_${widget.product.sku}.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await Share.shareXFiles([
        XFile(file.path),
      ], text: l10n.barcodeShareText(widget.product.name, widget.product.sku ?? ''));
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: AppLocalizations.of(context)!.shareFailed(e.toString()),
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.product.sku ?? ''));
    HapticFeedback.lightImpact();

    mySnackBar(
      context: context,
      text: AppLocalizations.of(context)!.skuCopied,
      status: ToastStatus.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final sku = widget.product.sku ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Indicator
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
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.productBarcode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(TablerIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // RepaintBoundary card to capture for download/share
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Store/Product info
                      Text(
                        widget.product.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.categoryName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barcode itself
                      Container(
                        height: 90,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: sku,
                          width: double.infinity,
                          height: 70,
                          color: Colors.black,
                          drawText:
                              false, // We render SKU in our custom styled font below
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Readable SKU code
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sku,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: _copyToClipboard,
                      leading: const Icon(TablerIcons.copy, size: 18),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(AppLocalizations.of(context)!.copySku),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadButton(
                      backgroundColor: Warna.primary,
                      foregroundColor: Colors.black,
                      onPressed: _isSharing ? null : _shareBarcodeCard,
                      leading: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(TablerIcons.share, size: 18),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppLocalizations.of(context)!.share,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/core/widgets/connectivity_status_bar.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  // Optimization: Debouncer prevents expensive UI rebuilds and local filtering on every keystroke.
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String _searchQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final productsAsync = ref.watch(productNotifierProvider);
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                l10n.manageCategories,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                Localizations.localeOf(context).languageCode == 'id'
                    ? 'Atur kelompok produk untuk mempermudah penjualan'
                    : 'Organize products to simplify transactions',
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
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConnectivityStatusBar(),

              // HEADER & SEARCH
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShadInput(
                      placeholder: Text(l10n.searchCategory),
                      leading: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(TablerIcons.search, size: 20),
                      ),
                      onChanged: (value) => _debouncer.run(
                        () => setState(() => _searchQuery = value),
                      ),
                      decoration: ShadDecoration(
                        border: ShadBorder.none,
                        color: theme.colorScheme.muted.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ShadButton(
                        backgroundColor: Warna.primary,
                        onPressed: () => _showCategoryForm(context),
                        leading: const Icon(
                          TablerIcons.plus,
                          size: 18,
                          color: Warna.black,
                        ),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'id'
                              ? 'Tambah Kategori Baru'
                              : 'Add New Category',
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

              // CATEGORY LIST
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) {
                    // ⚡ Bolt: Hoist invariant toLowerCase() outside the loop
                    // This prevents redundant O(N) string allocations during filtering
                    final lowerQuery = _searchQuery.toLowerCase();

                    final filtered = categories.where((c) {
                      return c.name.toLowerCase().contains(lowerQuery);
                    }).toList();

                    final products = productsAsync.value ?? [];

                    final isId =
                        Localizations.localeOf(context).languageCode == 'id';
                    final uncategorizedTitle = isId
                        ? 'Tanpa Kategori'
                        : 'Uncategorized';
                    final showUncategorized =
                        _searchQuery.isEmpty ||
                        uncategorizedTitle.toLowerCase().contains(lowerQuery);

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
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.muted.withValues(
                                      alpha: 0.5,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    TablerIcons.category,
                                    size: 48,
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.noCategoriesYet,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.foreground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.noCategoriesYetDesc,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(categoryNotifierProvider.notifier)
                          .syncCategories(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final category = filtered[index];
                          final productCount = products
                              .where(
                                (p) => category.supabaseId == 'uncategorized'
                                    ? p.categoryId == null
                                    : p.categoryId == category.supabaseId,
                              )
                              .length;
                          return _buildCategoryCard(
                            context,
                            category,
                            theme,
                            productCount,
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Category category,
    ShadThemeData theme,
    int productCount,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            // Left: Premium modern container icon (NOT Circle Avatar)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.supabaseId == 'uncategorized'
                    ? Colors.grey.shade100
                    : Warna.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.supabaseId == 'uncategorized'
                    ? TablerIcons.folder_off
                    : TablerIcons.category,
                size: 20,
                color: category.supabaseId == 'uncategorized'
                    ? Colors.grey.shade600
                    : Colors.black87,
              ),
            ),
            const SizedBox(width: 16),

            // Middle: Category Name, Product Count & Sync Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (category.supabaseId != 'uncategorized' &&
                          !category.isSynced)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Tooltip(
                            message: l10n.waitingForSync,
                            child: const Icon(
                              TablerIcons.cloud_off,
                              size: 14,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Localizations.localeOf(context).languageCode == 'id'
                        ? '$productCount Produk'
                        : '$productCount Products',
                    style: theme.textTheme.muted.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right: Actions (Edit, Delete)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: l10n.viewProducts,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      context.push(
                        '/categories/products',
                        extra: {'category': category},
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Warna.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        TablerIcons.packages,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                if (category.supabaseId != 'uncategorized') ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.editCategory,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _showCategoryForm(context, category: category),
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
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.deleteCategory,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _confirmDelete(context, category),
                      child: Container(
                        padding: const EdgeInsets.all(8),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, {Category? category}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name);

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(isEditing ? l10n.editCategory : l10n.addCategory),
        description: Text(l10n.fillCategoryInfo),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ShadInput(
              controller: nameController,
              placeholder: Text(l10n.categoryNameExample),
            ),
          ],
        ),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          ShadButton(
            backgroundColor: Warna.primary,
            child: Text(
              isEditing ? l10n.save : l10n.add,
              style: const TextStyle(
                color: Warna.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              if (nameController.text.isEmpty) {
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
                        name: nameController.text,
                      );
                } else {
                  await ref
                      .read(categoryNotifierProvider.notifier)
                      .addCategory(name: nameController.text);

                  // Log to Firebase Analytics
                  try {
                    await AnalyticsService.instance.logCategoryCreation(
                      categoryName: nameController.text,
                    );
                  } catch (_) {}
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  mySnackBar(
                    context: context,
                    text: isEditing
                        ? l10n.categoryUpdatedSuccess
                        : l10n.categoryAddedSuccess,
                    status: ToastStatus.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  mySnackBar(
                    context: context,
                    text: l10n.categoryActionFailed(e.toString()),
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

  void _confirmDelete(BuildContext context, Category category) {
    final l10n = AppLocalizations.of(context)!;
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(l10n.deleteCategory),
        description: Text(l10n.deleteCategoryConfirm(category.name)),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          ShadButton.destructive(
            child: Text(l10n.delete),
            onPressed: () async {
              try {
                await ref
                    .read(categoryNotifierProvider.notifier)
                    .deleteCategory(category.supabaseId);
                if (context.mounted) {
                  Navigator.pop(context);
                  mySnackBar(
                    context: context,
                    text: l10n.categoryDeletedSuccess,
                    status: ToastStatus.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
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

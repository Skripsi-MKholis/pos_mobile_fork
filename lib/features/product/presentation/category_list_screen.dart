import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
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
    final theme = ShadTheme.of(context);

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
          title: const Text('Kelola Kategori'),
          backgroundColor: theme.colorScheme.background,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(TablerIcons.chevron_left),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConnectivityStatusBar(),

              // HEADER & SEARCH
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ShadInput(
                        placeholder: const Text('Cari kategori...'),
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
                    const SizedBox(width: 12),
                    ShadButton(
                      backgroundColor: const Color(0xFF98D100), // Lime Green
                      onPressed: () => _showCategoryForm(context),
                      leading: const Icon(TablerIcons.plus, size: 18),
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
              ),

              // CATEGORY LIST
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) {
                    // Hoist search query lowercase conversion outside loop for better performance
                    final lowerQuery = _searchQuery.toLowerCase();
                    final filtered = categories.where((c) {
                      return c.name.toLowerCase().contains(
                        lowerQuery,
                      );
                    }).toList();

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
                                    color: theme.colorScheme.muted.withOpacity(
                                      0.5,
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
                                  'Belum ada kategori',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.foreground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tambah kategori baru untuk mulai\nmengelompokkan produk Anda.',
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
                          return _buildCategoryCard(context, category, theme);
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

  Color _getCategoryColor(String name) {
    final int hash = name.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.45, 0.93).toColor();
  }

  Color _getCategoryTextColor(String name) {
    final int hash = name.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.35).toColor();
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Category category,
    ShadThemeData theme,
  ) {
    final firstLetter = category.name.isNotEmpty
        ? category.name[0].toUpperCase()
        : '?';
    final avatarBgColor = _getCategoryColor(category.name);
    final avatarTextColor = _getCategoryTextColor(category.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
          children: [
            // Left: Dynamic Pastel Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: avatarTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Middle: Category Name & Sync Status
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (!category.isSynced)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message: 'Menunggu sinkronisasi ke cloud',
                        child: Icon(
                          TablerIcons.cloud_off,
                          size: 14,
                          color: Colors.orange,
                        ),
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
                  message: 'Lihat Produk',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      context.push(
                        '/products',
                        extra: {'categoryId': category.supabaseId},
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        TablerIcons.packages,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Edit Kategori',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showCategoryForm(context, category: category),
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
                  message: 'Hapus Kategori',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _confirmDelete(context, category),
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
          ],
        ),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, {Category? category}) {
    final theme = ShadTheme.of(context);
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name);

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(isEditing ? 'Edit Kategori' : 'Tambah Kategori'),
        description: const Text('Isi informasi kategori dengan lengkap.'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nama Kategori',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ShadInput(
              controller: nameController,
              placeholder: const Text('Contoh: Makanan, Minuman...'),
            ),
          ],
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ShadButton(
            backgroundColor: const Color(0xFF98D100),
            child: Text(isEditing ? 'Simpan' : 'Tambah'),
            onPressed: () async {
              if (nameController.text.isEmpty) {
                mySnackBar(
                  context: context,
                  text: 'Nama kategori tidak boleh kosong',
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
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  mySnackBar(
                    context: context,
                    text: isEditing
                        ? 'Kategori berhasil diperbarui'
                        : 'Kategori berhasil ditambahkan',
                    status: ToastStatus.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  mySnackBar(
                    context: context,
                    text: 'Gagal: $e',
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
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Kategori'),
        description: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ShadButton.destructive(
            child: const Text('Hapus'),
            onPressed: () async {
              try {
                await ref
                    .read(categoryNotifierProvider.notifier)
                    .deleteCategory(category.supabaseId);
                if (context.mounted) {
                  Navigator.pop(context);
                  mySnackBar(
                    context: context,
                    text: 'Kategori berhasil dihapus',
                    status: ToastStatus.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  mySnackBar(
                    context: context,
                    text: 'Gagal menghapus: $e',
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

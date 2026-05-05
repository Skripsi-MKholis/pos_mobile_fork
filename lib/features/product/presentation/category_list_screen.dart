import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  String _searchQuery = '';

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
                      onChanged: (value) => setState(() => _searchQuery = value),
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

            // TABLE HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Nama Kategori', style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(flex: 4, child: Text('Deskripsi', style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 80, child: Center(child: Text('Aksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),

            const Divider(indent: 24, endIndent: 24),

            // CATEGORY LIST
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(categoryNotifierProvider.notifier).syncCategories(),
                child: categoriesAsync.when(
                  data: (categories) {
                    final filtered = categories.where((c) {
                      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(TablerIcons.category, size: 64, color: theme.colorScheme.muted),
                            const SizedBox(height: 16),
                            Text('Belum ada kategori', style: TextStyle(color: theme.colorScheme.mutedForeground)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: theme.colorScheme.border.withValues(alpha: 0.5))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  category.description ?? '-',
                                  style: theme.textTheme.muted.copyWith(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(TablerIcons.edit, size: 18),
                                      onPressed: () => _showCategoryForm(context, category: category),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(TablerIcons.trash, size: 18, color: Colors.red),
                                      onPressed: () => _confirmDelete(context, category),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showCategoryForm(BuildContext context, {Category? category}) {
    final theme = ShadTheme.of(context);
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name);
    final descController = TextEditingController(text: category?.description);

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(isEditing ? 'Edit Kategori' : 'Tambah Kategori'),
        description: const Text('Isi informasi kategori dengan lengkap.'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ShadInput(
              controller: nameController,
              placeholder: const Text('Contoh: Makanan, Minuman...'),
            ),
            const SizedBox(height: 16),
            const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ShadInput(
              controller: descController,
              placeholder: const Text('Penjelasan singkat...'),
              maxLines: 3,
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
                ShadToaster.of(context).show(const ShadToast(description: Text('Nama kategori tidak boleh kosong')));
                return;
              }

              try {
                if (isEditing) {
                  await ref.read(categoryNotifierProvider.notifier).updateCategory(
                        supabaseId: category.supabaseId,
                        name: nameController.text,
                        description: descController.text,
                      );
                } else {
                  await ref.read(categoryNotifierProvider.notifier).addCategory(
                        name: nameController.text,
                        description: descController.text,
                      );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ShadToaster.of(context).show(ShadToast(
                    description: Text(isEditing ? 'Kategori berhasil diperbarui' : 'Kategori berhasil ditambahkan'),
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ShadToaster.of(context).show(ShadToast(description: Text('Gagal: $e')));
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
        description: Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ShadButton.destructive(
            child: const Text('Hapus'),
            onPressed: () async {
              try {
                await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.supabaseId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ShadToaster.of(context).show(const ShadToast(description: Text('Kategori berhasil dihapus')));
                }
              } catch (e) {
                if (context.mounted) {
                  ShadToaster.of(context).show(ShadToast(description: Text('Gagal menghapus: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

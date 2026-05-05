import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

class StoreSelectionScreen extends ConsumerWidget {
  const StoreSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final storesAsync = ref.watch(userStoresProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Toko',
                style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih outlet yang ingin Anda kelola hari ini.',
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: storesAsync.when(
                  data: (stores) {
                    if (stores.isEmpty) {
                      return _buildEmptyState(context, theme);
                    }
                    
                    return ListView.separated(
                      itemCount: stores.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        return _buildStoreCard(context, ref, theme, store);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
              const SizedBox(height: 24),
              ShadButton.outline(
                width: double.infinity,
                onPressed: () {
                  // Implementasi tambah toko nanti
                  ShadToaster.of(context).show(const ShadToast(description: Text('Fitur tambah toko segera hadir di mobile')));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(TablerIcons.plus, size: 20),
                    SizedBox(width: 8),
                    Text('Tambah Toko Baru'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, WidgetRef ref, ShadThemeData theme, Map<String, dynamic> store) {
    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          await ref.read(activeStoreProvider.notifier).selectStore(store);
          if (context.mounted) {
            context.go('/dashboard');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(TablerIcons.building_store, color: theme.colorScheme.foreground),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store['name'] ?? 'Toko Tanpa Nama',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store['address'] ?? 'Alamat tidak diatur',
                      style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ShadThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.building, size: 64, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 24),
          const Text(
            'Belum ada toko',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anda perlu membuat toko pertama Anda untuk memulai.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

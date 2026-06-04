import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/models/customer_cart_item.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_catalog_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class CustomerMenuPage extends ConsumerWidget {
  const CustomerMenuPage({super.key, this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStoreId = (storeId != null && storeId!.isNotEmpty)
        ? storeId
        : ref.watch(customerStoreIdProvider);
    final cartItems = ref.watch(customerCartProvider);
    final catalogAsync = ref.watch(customerCatalogProvider(activeStoreId));

    if (activeStoreId != null && activeStoreId.isNotEmpty) {
      ref.read(customerStoreIdProvider.notifier).state = activeStoreId;
    }

    final totalItems = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Digital'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Badge(
              isLabelVisible: totalItems > 0,
              label: Text(totalItems.toString()),
              child: IconButton(
                onPressed: () => context.push('/customer/cart'),
                icon: const Icon(TablerIcons.shopping_cart),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _HintBanner(
            icon: TablerIcons.qrcode,
            title: activeStoreId == null || activeStoreId.isEmpty
                ? 'Scan QR toko'
                : 'Toko aktif terdeteksi',
            description: activeStoreId == null || activeStoreId.isEmpty
                ? 'Tambahkan store_id pada deep link agar katalog pelanggan bisa dimuat dari toko yang benar.'
                : 'store_id: $activeStoreId',
          ),
          const SizedBox(height: 14),
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari menu favorit...',
              prefixIcon: const Icon(TablerIcons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FilterChip(label: 'Semua', selected: true),
              _FilterChip(label: 'Minuman'),
              _FilterChip(label: 'Makanan'),
              _FilterChip(label: 'Snack'),
              _FilterChip(label: 'Promo'),
            ],
          ),
          const SizedBox(height: 16),
          catalogAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return _EmptyState(
                  icon: TablerIcons.menu_2,
                  title: 'Katalog belum tersedia',
                  description:
                      'Tidak ada produk aktif untuk toko ini atau katalog belum tersinkron.',
                  actionLabel: 'Muat Ulang',
                  onAction: () =>
                      ref.invalidate(customerCatalogProvider(activeStoreId)),
                );
              }

              return Column(
                children: [
                  for (final product in products)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProductCard(
                        product: product,
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          final cartNotifier = ref.read(
                            customerCartProvider.notifier,
                          );
                          showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            backgroundColor: Colors.white,
                            builder: (sheetContext) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  28,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.description ??
                                          'Detail produk akan tampil di sini saat katalog penuh tersinkron.',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: product.isOutOfStock
                                            ? null
                                            : () {
                                                cartNotifier.addItem(
                                                  CustomerCartItem(
                                                    id: product.id,
                                                    name: product.name,
                                                    price: product.price,
                                                    badge: product.isOutOfStock
                                                        ? 'Habis'
                                                        : 'Ready',
                                                  ),
                                                );
                                                Navigator.of(
                                                  sheetContext,
                                                ).pop();
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${product.name} ditambahkan ke keranjang.',
                                                    ),
                                                  ),
                                                );
                                              },
                                        icon: const Icon(
                                          TablerIcons.shopping_cart_plus,
                                        ),
                                        label: Text(
                                          product.isOutOfStock
                                              ? 'Stok Habis'
                                              : 'Tambah ke Keranjang',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => _EmptyState(
              icon: TablerIcons.alert_circle,
              title: 'Gagal memuat katalog',
              description: '$error',
              actionLabel: 'Coba Lagi',
              onAction: () =>
                  ref.invalidate(customerCatalogProvider(activeStoreId)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final CustomerCatalogProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSoldOut = product.isOutOfStock;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Warna.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isSoldOut ? TablerIcons.mood_sad : TablerIcons.bowl,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(product.price),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(isSoldOut ? 'Habis' : 'Ready'),
              backgroundColor: isSoldOut
                  ? Colors.red.withValues(alpha: 0.12)
                  : Warna.primary.withValues(alpha: 0.14),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: selected
          ? Warna.primary.withValues(alpha: 0.18)
          : Colors.white,
      side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 68, color: Colors.black54),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}

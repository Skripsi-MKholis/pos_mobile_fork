import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/models/customer_cart_item.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key, this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (storeId != null && storeId!.isNotEmpty) {
      ref.read(customerStoreIdProvider.notifier).state = storeId;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pelanggan',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
        actions: [
          if (storeId != null && storeId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text(
                  storeId!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: Warna.primary.withValues(alpha: 0.18),
                side: BorderSide(color: Warna.primary.withValues(alpha: 0.3)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Warna.primary.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang di mode pelanggan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  storeId == null || storeId!.isEmpty
                      ? 'Silakan pilih toko, scan QR meja, atau lanjut sebagai tamu untuk melihat katalog.'
                      : 'Toko sudah terdeteksi. Lanjutkan ke menu digital atau pantau pesanan yang masuk.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAction(
                      icon: TablerIcons.menu_2,
                      label: 'Menu Digital',
                      onTap: () => context.push(
                        '/customer/menu?store_id=${storeId ?? ''}',
                      ),
                    ),
                    _QuickAction(
                      icon: TablerIcons.shopping_cart,
                      label: 'Keranjang',
                      onTap: () => context.push('/customer/cart'),
                    ),
                    _QuickAction(
                      icon: TablerIcons.history,
                      label: 'Riwayat',
                      onTap: () => context.push('/customer/history'),
                    ),
                    _QuickAction(
                      icon: TablerIcons.user_circle,
                      label: 'Profil',
                      onTap: () => context.push('/customer/profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(
            title: 'Akses cepat',
            subtitle: 'Rute awal yang sudah disiapkan untuk alur pelanggan.',
          ),
          const SizedBox(height: 12),
          _NavigationCard(
            icon: TablerIcons.bolt,
            title: 'Mulai pesanan baru',
            description: 'Buka katalog menu dan tambahkan item ke keranjang.',
            onTap: () => context.push(
              '/customer/menu?store_id=${storeId ?? ''}',
            ),
          ),
          _NavigationCard(
            icon: TablerIcons.ticket,
            title: 'Gunakan kode QR meja',
            description:
                'Rute ini sudah siap menerima store_id dari deep link.',
            onTap: () =>
                context.push('/customer/menu?store_id=${storeId ?? ''}'),
          ),
          _NavigationCard(
            icon: TablerIcons.receipt,
            title: 'Lihat struk digital',
            description:
                'Struk, status pesanan, dan notifikasi disiapkan sebagai route terpisah.',
            onTap: () => context.push('/customer/receipt/demo-transaction'),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(
            title: 'Status fase awal',
            subtitle:
                'Fondasi navigasi customer sudah tersedia. Fitur transaksi akan menyusul di milestone berikutnya.',
          ),
          const SizedBox(height: 12),
          const _StatusChipRow(),
        ],
      ),
    );
  }
}

class CustomerMenuScreen extends ConsumerWidget {
  const CustomerMenuScreen({super.key, this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalItems = ref
        .watch(customerCartProvider)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final products = <_DemoProduct>[
      const _DemoProduct(
        'Kopi Susu Aren',
        'Rp 24.000',
        'Promo',
        TablerIcons.coffee,
      ),
      const _DemoProduct(
        'Es Matcha Latte',
        'Rp 28.000',
        'Terlaris',
        TablerIcons.glass_full,
      ),
      const _DemoProduct(
        'Chicken Rice Bowl',
        'Rp 31.000',
        'Ready',
        TablerIcons.bowl,
      ),
      const _DemoProduct(
        'Crispy Fries',
        'Rp 18.000',
        'Habis',
        TablerIcons.mood_sad,
      ),
    ];

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
          if (storeId != null && storeId!.isNotEmpty)
            _HintBanner(
              icon: TablerIcons.qrcode,
              title: 'Toko aktif terdeteksi',
              description: 'store_id: $storeId',
            ),
          if (storeId != null && storeId!.isNotEmpty)
            const SizedBox(height: 12),
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductCard(
                product: product,
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final cartNotifier = ref.read(customerCartProvider.notifier);
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    backgroundColor: Colors.white,
                    builder: (sheetContext) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
                              'Detail produk, varian, dan tombol tambah ke keranjang akan dihubungkan pada milestone katalog.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  cartNotifier.addItem(
                                    CustomerCartItem(
                                      id: product.name,
                                      name: product.name,
                                      price: _parsePrice(product.price),
                                      badge: product.badge,
                                      iconCodePoint: product.icon.codePoint,
                                    ),
                                  );
                                  Navigator.of(sheetContext).pop();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} ditambahkan ke keranjang demo.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  TablerIcons.shopping_cart_plus,
                                ),
                                label: const Text('Tambah ke Keranjang'),
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
          ),
        ],
      ),
    );
  }
}

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CustomerCartView();
  }
}

class _CustomerCartView extends ConsumerWidget {
  const _CustomerCartView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(customerCartProvider);
    final cartNotifier = ref.read(customerCartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: cartNotifier.clear,
              child: const Text('Kosongkan'),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: _EmptyState(
                icon: TablerIcons.shopping_cart_off,
                title: 'Keranjang masih kosong',
                description:
                    'Item yang dipilih dari menu akan tampil di sini setelah state keranjang pelanggan dihubungkan.',
                actionLabel: 'Lihat Menu',
                onAction: () => context.push('/customer/menu'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Warna.primary.withValues(
                            alpha: 0.14,
                          ),
                          child: Icon(
                            item.badge == 'Habis'
                                ? TablerIcons.mood_sad
                                : TablerIcons.shopping_cart,
                            color: Colors.black87,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${_formatCurrency(item.price)} x ${item.quantity} = ${_formatCurrency(item.lineTotal)}',
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => cartNotifier.decrement(item.id),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: () => cartNotifier.increment(item.id),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _CartSummary(
                  total: items.fold<double>(
                    0,
                    (sum, item) => sum + item.lineTotal,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push('/customer/checkout'),
                  child: const Text('Checkout'),
                ),
              ],
            ),
    );
  }
}

class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = <_HistoryItem>[
      const _HistoryItem(
        'INV-2026-021',
        '#INV-2026-021',
        '2 Juni 2026',
        'Rp 72.000',
        'Selesai',
      ),
      const _HistoryItem(
        'INV-2026-018',
        '#INV-2026-018',
        '29 Mei 2026',
        'Rp 41.000',
        'Selesai',
      ),
      const _HistoryItem(
        'INV-2026-014',
        '#INV-2026-014',
        '24 Mei 2026',
        'Rp 54.500',
        'Dibatalkan',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _SectionTitle(
            title: 'Transaksi sebelumnya',
            subtitle:
                'Daftar ini akan dihubungkan ke riwayat transaksi pelanggan setelah model dan query siap.',
          ),
          const SizedBox(height: 12),
          ...history.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  title: Text(
                    item.referenceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${item.date} - ${item.status}'),
                  trailing: Text(
                    item.amount,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () =>
                      context.push('/customer/receipt/${item.transactionId}'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/customer/menu'),
            icon: const Icon(TablerIcons.repeat),
            label: const Text('Pesan Ulang'),
          ),
        ],
      ),
    );
  }
}

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFEFF7EC),
                  child: Icon(
                    TablerIcons.user_circle,
                    size: 34,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelanggan Tamu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Akun belum terhubung'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingTile(
            icon: TablerIcons.bell,
            title: 'Notifikasi',
            subtitle: 'Atur preferensi promo dan status pesanan',
            onTap: () => context.push('/customer/notifications'),
          ),
          _SettingTile(
            icon: TablerIcons.sparkles,
            title: 'Program loyalitas',
            subtitle: 'Lihat poin dan reward yang tersedia',
            onTap: () => context.push('/customer/loyalty'),
          ),
          _SettingTile(
            icon: TablerIcons.logout,
            title: 'Keluar',
            subtitle: 'Kembali ke layar login staf',
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}

class CustomerCheckoutScreen extends StatelessWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailPage(
      title: 'Checkout',
      icon: TablerIcons.credit_card,
      description:
          'Halaman checkout sudah disiapkan sebagai endpoint terpisah untuk pilihan pembayaran, meja, dan konfirmasi pesanan.',
    );
  }
}

class CustomerOrderTrackingScreen extends StatelessWidget {
  const CustomerOrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Lacak Pesanan',
      icon: TablerIcons.timeline_event_text,
      description:
          'Order $orderId akan memakai realtime update ketika tabel pesanan pelanggan dihubungkan ke Supabase Realtime.',
    );
  }
}

class CustomerReceiptScreen extends StatelessWidget {
  const CustomerReceiptScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Struk Digital',
      icon: TablerIcons.receipt_2,
      description:
          'Struk untuk transaksi $transactionId siap menerima layout final, QR validasi, dan tombol bagikan.',
    );
  }
}

class CustomerLoyaltyScreen extends StatelessWidget {
  const CustomerLoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailPage(
      title: 'Loyalty',
      icon: TablerIcons.heart_handshake,
      description:
          'Halaman poin, tier, dan reward pelanggan sudah disiapkan sebagai ruang untuk program loyalitas pada milestone berikutnya.',
    );
  }
}

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailPage(
      title: 'Notifikasi',
      icon: TablerIcons.bell_ringing,
      description:
          'Pusat notifikasi pelanggan akan digunakan untuk pesan transaksi, promo, dan update loyalitas.',
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: Colors.black87),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade700, height: 1.35),
        ),
      ],
    );
  }
}

class _StatusChipRow extends StatelessWidget {
  const _StatusChipRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _MiniStatusChip(label: 'Route shell siap'),
        _MiniStatusChip(label: 'Guest mode aktif'),
        _MiniStatusChip(label: 'Deep link QR didukung'),
        _MiniStatusChip(label: 'Milestone berikutnya: checkout'),
      ],
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black87),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(TablerIcons.chevron_right, size: 18),
            ],
          ),
        ),
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

  final _DemoProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSoldOut = product.badge == 'Habis';
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
              child: Icon(product.icon, color: Colors.black87),
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
                    product.price,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(product.badge),
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

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Warna.primary.withValues(alpha: 0.14),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(TablerIcons.chevron_right),
      ),
    );
  }
}

class _DemoProduct {
  const _DemoProduct(this.name, this.price, this.badge, this.icon);

  final String name;
  final String price;
  final String badge;
  final IconData icon;
}

double _parsePrice(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits) ?? 0;
}

String _formatCurrency(double value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(
            _formatCurrency(total),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem {
  const _HistoryItem(
    this.transactionId,
    this.referenceLabel,
    this.date,
    this.amount,
    this.status,
  );

  final String transactionId;
  final String referenceLabel;
  final String date;
  final String amount;
  final String status;
}

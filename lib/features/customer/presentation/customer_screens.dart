import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/models/customer_cart_item.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:shadcn_ui/shadcn_ui.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key, this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (storeId != null && storeId!.isNotEmpty) {
      ref.read(customerStoreIdProvider.notifier).state = storeId;
    }

    final theme = ShadTheme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        const _LocationSelector(),
        const SizedBox(height: 16),
        const _MockSearchBar(),
        const SizedBox(height: 20),
        const _PromoCarousel(),
        const SizedBox(height: 24),
        Text(
          'LAYANAN UTAMA',
          style: theme.textTheme.muted.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        _ServiceGrid(storeId: storeId),
        const SizedBox(height: 24),
        const _RecommendedStores(),
      ],
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Warna.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            TablerIcons.map_pin,
            size: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cari di sekitar',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Yogyakarta',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  TablerIcons.chevron_down,
                  size: 14,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _MockSearchBar extends StatelessWidget {
  const _MockSearchBar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Halaman pencarian akan segera hadir!'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              TablerIcons.search,
              size: 18,
              color: Colors.black54,
            ),
            const SizedBox(width: 10),
            Text(
              'Cari toko, menu, atau produk...',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _promos = [
    {
      'title': 'Promo Gajian\nDiskon s.d 50%',
      'subtitle': 'Khusus pemesanan via Menu Digital',
      'color1': const Color(0xFFFACC15),
      'color2': const Color(0xFFEAB308),
      'imageIcon': TablerIcons.ticket,
    },
    {
      'title': 'Gratis Ongkir\nTanpa Min. Belanja',
      'subtitle': 'Nikmati kopi favoritmu di rumah',
      'color1': const Color(0xFF38BDF8),
      'color2': const Color(0xFF0284C7),
      'imageIcon': TablerIcons.truck,
    },
    {
      'title': 'Sarapan Hemat\nMulai Rp 12.000',
      'subtitle': 'Senin s.d Jumat jam 07:00 - 10:00',
      'color1': const Color(0xFFF87171),
      'color2': const Color(0xFFDC2626),
      'imageIcon': TablerIcons.coffee,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [promo['color1'], promo['color2']],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: promo['color2'].withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          promo['imageIcon'],
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              promo['title'],
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              promo['subtitle'],
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.black87 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Pesan Antar',
        'subtitle': 'Kirim langsung',
        'icon': TablerIcons.truck,
        'color': Colors.blue.shade50,
        'iconColor': Colors.blue.shade700,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Layanan antar segera hadir')),
            ),
      },
      {
        'title': 'Ambil Sendiri',
        'subtitle': 'Tanpa antre',
        'icon': TablerIcons.shopping_bag,
        'color': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF047857),
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Layanan pickup segera hadir')),
            ),
      },
      {
        'title': 'Scan QR Meja',
        'subtitle': 'Pesan di tempat',
        'icon': TablerIcons.qrcode,
        'color': Colors.amber.shade50,
        'iconColor': Colors.amber.shade700,
        'onTap': () => context.push('/customer/menu?store_id=${storeId ?? ''}'),
      },
      {
        'title': 'Katalog Menu',
        'subtitle': 'Menu digital',
        'icon': TablerIcons.menu_2,
        'color': Colors.orange.shade50,
        'iconColor': Colors.orange.shade700,
        'onTap': () => context.push('/customer/menu?store_id=${storeId ?? ''}'),
      },
      {
        'title': 'Kupon Promo',
        'subtitle': 'Hemat belanja',
        'icon': TablerIcons.ticket,
        'color': const Color(0xFFFFF1F2),
        'iconColor': const Color(0xFFBE123C),
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kupon promo segera hadir')),
            ),
      },
      {
        'title': 'Loyalti Poin',
        'subtitle': 'Kumpul reward',
        'icon': TablerIcons.award,
        'color': Colors.indigo.shade50,
        'iconColor': Colors.indigo.shade700,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loyalti reward segera hadir')),
            ),
      },
      {
        'title': 'Struk Digital',
        'subtitle': 'Riwayat transaksi',
        'icon': TablerIcons.receipt,
        'color': Colors.teal.shade50,
        'iconColor': Colors.teal.shade700,
        'onTap': () => context.push('/customer/receipt/demo-transaction'),
      },
      {
        'title': 'Bantuan',
        'subtitle': 'Hubungi kami',
        'icon': TablerIcons.help_circle,
        'color': Colors.grey.shade100,
        'iconColor': Colors.grey.shade700,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bantuan layanan segera hadir')),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        return ShadCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: service['onTap'],
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: service['color'],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          service['icon'],
                          size: 18,
                          color: service['iconColor'],
                        ),
                      ),
                      Icon(
                        TablerIcons.arrow_right,
                        size: 14,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    service['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  Text(
                    service['subtitle'],
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecommendedStores extends StatelessWidget {
  const _RecommendedStores();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final stores = [
      {
        'name': 'Kopi Kenangan - Plaza Ambarrukmo',
        'category': 'Minuman, Kopi',
        'rating': '4.8',
        'distance': '1.2 km',
        'bannerColor': Colors.amber.shade700,
      },
      {
        'name': 'Mie Gacoan - Sudirman',
        'category': 'Makanan, Mie, Pedas',
        'rating': '4.7',
        'distance': '2.5 km',
        'bannerColor': Colors.red.shade700,
      },
      {
        'name': 'Warmindo Prima - Gejayan',
        'category': 'Makanan, Mie Instan, Kopi',
        'rating': '4.5',
        'distance': '0.8 km',
        'bannerColor': const Color(0xFF047857),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'REKOMENDASI TOKO POPULER',
              style: theme.textTheme.muted.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stores.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final store = stores[index];
            return ShadCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Toko ${store['name']} terpilih')),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: store['bannerColor'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            TablerIcons.building_store,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store['category'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  TablerIcons.star_filled,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  store['rating'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•  ${store['distance']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        TablerIcons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class CustomerMenuScreen extends ConsumerWidget {
  const CustomerMenuScreen({super.key, this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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

    if (items.isEmpty) {
      return Center(
        child: _EmptyState(
          icon: TablerIcons.shopping_cart_off,
          title: 'Keranjang masih kosong',
          description:
              'Item yang dipilih dari menu akan tampil di sini setelah state keranjang pelanggan dihubungkan.',
          actionLabel: 'Lihat Menu',
          onAction: () => context.push('/customer/menu'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
      );
  }
}

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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

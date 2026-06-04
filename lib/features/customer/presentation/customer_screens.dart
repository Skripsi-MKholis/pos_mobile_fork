import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/models/customer_cart_item.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
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
          const SizedBox(height: 40),
          const _RecommendedStores(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          heroTag: 'customer_scan_fab',
          onPressed: () => context.push('/customer/scan'),
          backgroundColor: Warna.primary,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(TablerIcons.scan, color: Warna.black, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

final customerLocationProvider = StateProvider<String>((ref) => 'Yogyakarta');

class _LocationSelector extends ConsumerWidget {
  const _LocationSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final location = ref.watch(customerLocationProvider);

    return InkWell(
      onTap: () => context.push('/customer/select-location'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.border.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Warna.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TablerIcons.map_pin,
                size: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cari di sekitar',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.mutedForeground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              TablerIcons.chevron_right,
              size: 18,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _MockSearchBar extends StatelessWidget {
  const _MockSearchBar();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return InkWell(
      onTap: () => context.push('/customer/search'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              TablerIcons.search,
              size: 20,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 10),
            Text(
              'Cari toko, menu, atau produk...',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 14,
                fontWeight: FontWeight.normal,
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _promos.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

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
        'title': 'Scan QR Meja',
        'subtitle': 'Pesan di tempat',
        'icon': TablerIcons.qrcode,
        'color': Warna.primary.withValues(alpha: 0.12),
        'iconColor': Warna.primary,
        'onTap': () => context.push('/customer/scan'),
      },
      {
        'title': 'Katalog Menu',
        'subtitle': 'Menu digital',
        'icon': TablerIcons.menu_2,
        'color': Warna.primary.withValues(alpha: 0.12),
        'iconColor': Warna.primary,
        'onTap': () {
          final sId = storeId;
          if (sId != null && sId.isNotEmpty) {
            context.push(
              Uri(
                path: '/customer/store-detail',
                queryParameters: {
                  'store_name': sId,
                  'category': 'Makanan & Minuman',
                  'distance': '10 m',
                  'banner_color': 'FF9AE600',
                },
              ).toString(),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Silakan pilih gerai toko terlebih dahulu di halaman utama!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      },
      {
        'title': 'Struk Digital',
        'subtitle': 'Riwayat transaksi',
        'icon': TablerIcons.receipt,
        'color': Warna.primary.withValues(alpha: 0.12),
        'iconColor': Warna.primary,
        'onTap': () => context.push('/customer/receipt/demo-transaction'),
      },
      {
        'title': 'Bantuan',
        'subtitle': 'Hubungi kami',
        'icon': TablerIcons.help_circle,
        'color': Warna.primary.withValues(alpha: 0.12),
        'iconColor': Warna.primary,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bantuan layanan segera hadir')),
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B9E00),
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
                  final bannerColorHex = '#${(store['bannerColor'] as Color).value.toRadixString(16).substring(2)}';
                  context.push(
                    Uri(
                      path: '/customer/store-detail',
                      queryParameters: {
                        'store_name': store['name'] as String,
                        'category': store['category'] as String,
                        'distance': store['distance'] as String,
                        'banner_color': bannerColorHex,
                      },
                    ).toString(),
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
        if (storeId != null && storeId!.isNotEmpty) const SizedBox(height: 12),
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
                              icon: const Icon(TablerIcons.shopping_cart_plus),
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

class CustomerCartScreen extends ConsumerStatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  ConsumerState<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends ConsumerState<CustomerCartScreen> {
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isDineIn = true;

  @override
  void dispose() {
    _tableController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  IconData _getProductIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('kopi') || name.contains('coffee') || name.contains('latte') || name.contains('americano')) {
      return TablerIcons.coffee;
    } else if (name.contains('mie') || name.contains('noodle') || name.contains('setan') || name.contains('hompimpa') || name.contains('suit') || name.contains('bakso') || name.contains('soup')) {
      return TablerIcons.soup;
    } else if (name.contains('roti') || name.contains('bread') || name.contains('cake') || name.contains('cokelat') || name.contains('cookie') || name.contains('keju')) {
      return TablerIcons.cookie;
    } else if (name.contains('teh') || name.contains('tea') || name.contains('es') || name.contains('jeruk') || name.contains('sundelbolong') || name.contains('gobak') || name.contains('minuman') || name.contains('jus')) {
      return TablerIcons.glass_full;
    }
    return TablerIcons.shopping_bag;
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(customerCartProvider);
    final cartNotifier = ref.read(customerCartProvider.notifier);
    final activeStoreId = ref.watch(customerStoreIdProvider);

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Warna.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TablerIcons.shopping_cart_off,
                    size: 72,
                    color: Warna.black,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Keranjang Belanja Kosong',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda belum menambahkan produk apa pun ke keranjang. Jelajahi menu gerai toko kami untuk menemukan hidangan favorit Anda!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    backgroundColor: Warna.primary,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/customer/home');
                      }
                    },
                    child: const Text(
                      'Mulai Belanja',
                      style: TextStyle(color: Warna.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final tax = subtotal * 0.11; // 11% Tax
    const serviceFee = 2000.0; // Biaya Layanan Rp 2.000
    
    final grandTotal = (subtotal + tax + serviceFee).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Keranjang Belanja',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(TablerIcons.trash_x, color: Colors.redAccent),
              onPressed: () {
                showShadDialog(
                  context: context,
                  builder: (context) => ShadDialog(
                    title: const Text('Kosongkan Keranjang'),
                    description: const Text('Apakah Anda yakin ingin menghapus semua item dari keranjang belanja?'),
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ShadButton.destructive(
                        onPressed: () {
                          cartNotifier.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Hapus Semua'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Store Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Warna.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Warna.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(TablerIcons.building_store, size: 20, color: Warna.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeStoreId != null && activeStoreId.isNotEmpty
                          ? 'Daftar belanja Anda di $activeStoreId'
                          : 'Daftar Belanja Pelanggan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cart Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Item Icon
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Warna.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProductIcon(item.name),
                          color: Warna.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Item Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatCurrency(item.price)} x ${item.quantity}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(item.lineTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Controls: Counter and Delete
                      Row(
                        children: [
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(TablerIcons.minus, size: 12, color: Colors.black87),
                                  onPressed: () {
                                    cartNotifier.decrement(item.id);
                                  },
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(TablerIcons.plus, size: 12, color: Colors.black87),
                                  onPressed: () {
                                    cartNotifier.increment(item.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(TablerIcons.trash, size: 18, color: Colors.redAccent),
                            onPressed: () {
                              cartNotifier.removeItem(item.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Order Type Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipe Pesanan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isDineIn = true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isDineIn ? Warna.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDineIn ? Warna.primary : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    TablerIcons.tools_kitchen_2,
                                    size: 16,
                                    color: _isDineIn ? Colors.black : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Makan di Sini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isDineIn ? Colors.black : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isDineIn = false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isDineIn ? Warna.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isDineIn ? Warna.primary : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    TablerIcons.shopping_bag,
                                    size: 16,
                                    color: !_isDineIn ? Colors.black : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bawa Pulang',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: !_isDineIn ? Colors.black : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isDineIn) ...[
                    const SizedBox(height: 16),
                    ShadInput(
                      controller: _tableController,
                      placeholder: const Text('Masukkan Nomor Meja Anda'),
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(TablerIcons.qrcode, size: 16),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(TablerIcons.info_circle, color: Colors.amber.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pesanan Anda akan dikemas dengan rapi untuk dibawa pulang.',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cooking Notes Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Pesanan (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  ShadInput(
                    controller: _notesController,
                    placeholder: const Text('Contoh: Es batu sedikit, tidak pakai sendok plastik...'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Billing Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  _buildBillingRow('Subtotal produk', _formatCurrency(subtotal)),
                  const SizedBox(height: 8),
                  _buildBillingRow('PPN (11%)', _formatCurrency(tax)),
                  const SizedBox(height: 8),
                  _buildBillingRow('Biaya Layanan & Aplikasi', _formatCurrency(serviceFee)),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87),
                      ),
                      Text(
                        _formatCurrency(grandTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ShadButton(
              backgroundColor: Warna.primary,
              onPressed: () {
                if (_isDineIn && _tableController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan masukkan nomor meja Anda terlebih dahulu!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                final table = _isDineIn ? _tableController.text.trim() : 'Takeaway';
                final notes = _notesController.text.trim();
                
                context.push(
                  Uri(
                    path: '/customer/checkout',
                    queryParameters: {
                      'table': table,
                      'notes': notes,
                    },
                  ).toString(),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Konfirmasi Pesanan',
                    style: TextStyle(
                      color: Warna.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatCurrency(grandTotal),
                        style: const TextStyle(
                          color: Warna.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(TablerIcons.chevron_right, size: 16, color: Warna.black),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _activeOrders = [
    {
      'transactionId': 'INV-2026-024',
      'storeName': 'Kopi Kenangan - Plaza Ambarrukmo',
      'date': 'Hari ini, 15:40',
      'amount': 'Rp 24.000',
      'status': 'Diproses',
      'statusColor': const Color(0xFFD97706),
      'statusBg': const Color(0xFFFEF3C7),
      'items': '1 Kopi Susu Aren',
    },
    {
      'transactionId': 'INV-2026-023',
      'storeName': 'Mie Gacoan - Sudirman',
      'date': 'Hari ini, 15:10',
      'amount': 'Rp 36.000',
      'status': 'Siap Diambil',
      'statusColor': const Color(0xFF2563EB),
      'statusBg': const Color(0xFFDBEAFE),
      'items': '2 Mie Setan Level 2, 1 Es Sundelbolong',
    },
  ];

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'transactionId': 'INV-2026-021',
      'storeName': 'Kopi Kenangan - Plaza Ambarrukmo',
      'date': '2 Juni 2026, 14:32',
      'amount': 'Rp 72.000',
      'status': 'Selesai',
      'statusColor': const Color(0xFF059669),
      'statusBg': const Color(0xFFECFDF5),
      'items': '2 Kopi Aren, 1 Roti Cokelat',
    },
    {
      'transactionId': 'INV-2026-018',
      'storeName': 'Mie Gacoan - Sudirman',
      'date': '29 Mei 2026, 19:15',
      'amount': 'Rp 41.000',
      'status': 'Selesai',
      'statusColor': const Color(0xFF059669),
      'statusBg': const Color(0xFFECFDF5),
      'items': '1 Mie Iblis Level 3, 1 Es Genderuwo',
    },
    {
      'transactionId': 'INV-2026-014',
      'storeName': 'Warmindo Prima - Gejayan',
      'date': '24 Mei 2026, 12:05',
      'amount': 'Rp 54.500',
      'status': 'Dibatalkan',
      'statusColor': const Color(0xFFE11D48),
      'statusBg': const Color(0xFFFFF1F2),
      'items': '3 Indomie Goreng, 2 Es Teh Manis',
    },
  ];

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders,
    ShadThemeData theme,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: _EmptyState(
            icon: TablerIcons.receipt_off,
            title: 'Belum ada pesanan',
            description: 'Mulai belanja menu favoritmu sekarang!',
            actionLabel: 'Pesan Sekarang',
            onAction: () => context.go('/customer/home'),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length + 1,
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/customer/home'),
                icon: const Icon(TablerIcons.repeat, size: 16),
                label: const Text(
                  'Pesan Menu Baru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                ),
              ),
            ),
          );
        }

        final item = orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShadCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () =>
                  context.push('/customer/receipt/${item['transactionId']}'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['transactionId'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.black45,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item['statusBg'] as Color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['status'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: item['statusColor'] as Color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['storeName'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['items'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['date'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                        Text(
                          item['amount'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PESANAN SAYA',
                style: theme.textTheme.muted.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black38,
          indicatorColor: Warna.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.black.withValues(alpha: 0.05),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            fontFamily: 'Plus Jakarta Sans',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'Plus Jakarta Sans',
          ),
          tabs: const [
            Tab(text: 'Dalam Proses'),
            Tab(text: 'Riwayat'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(_activeOrders, theme),
              _buildOrderList(_pastOrders, theme),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildCustomerHeader(context, theme),
        const SizedBox(height: 32),
        _buildMenuSection(theme, 'AKTIVITAS & PROMO', [
          _buildMenuItem(
            context,
            theme,
            TablerIcons.bell,
            'Notifikasi',
            'Atur preferensi promo & status pesanan',
            () => context.push('/customer/notifications'),
          ),
          _buildMenuItem(
            context,
            theme,
            TablerIcons.sparkles,
            'Program Loyalitas',
            'Lihat poin dan reward yang tersedia',
            () => context.push('/customer/loyalty'),
          ),
        ]),
        const SizedBox(height: 24),
        _buildMenuSection(theme, 'PENGATURAN APLIKASI', [
          _buildMenuItem(
            context,
            theme,
            TablerIcons.language,
            'Bahasa',
            'Pilih bahasa tampilan aplikasi',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bahasa default diset ke Bahasa Indonesia'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            trailingText: 'Bahasa Indonesia',
          ),
          _buildMenuItem(
            context,
            theme,
            TablerIcons.help_circle,
            'Pusat Bantuan',
            'Hubungi tim dukungan kami',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menghubungi Pusat Bantuan POS...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ]),
        const SizedBox(height: 32),
        ShadButton.destructive(
          width: double.infinity,
          onPressed: () {
            showShadDialog(
              context: context,
              builder: (context) => ShadDialog(
                title: const Text('Keluar Sesi Pelanggan'),
                description: const Text(
                  'Apakah Anda yakin ingin keluar dan kembali ke halaman login staf?',
                ),
                actions: [
                  ShadButton.outline(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ShadButton.destructive(
                    child: const Text('Keluar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            );
          },
          child: const Text('Keluar Sesi Pelanggan'),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Antigravity POS • Versi Pelanggan 1.0.0',
            style: theme.textTheme.muted.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerHeader(BuildContext context, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Warna.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Warna.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              TablerIcons.user_circle,
              color: Colors.black,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pelanggan Tamu',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: CS-MEMBER-882 • Belum Terhubung',
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    ShadThemeData theme,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.muted.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
              color: theme.colorScheme.mutedForeground.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    ShadThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color,
    String? trailingText,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              color?.withValues(alpha: 0.1) ??
              theme.colorScheme.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Colors.black, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: theme.textTheme.muted.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            TablerIcons.chevron_right,
            size: 16,
            color: color?.withValues(alpha: 0.5) ?? Colors.black26,
          ),
        ],
      ),
      onTap: onTap,
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


class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String _query = '';

  final List<String> _history = [
    'Kopi Aren Kenangan',
    'Mie Gacoan',
    'Warmindo',
  ];

  final List<String> _popularSearches = [
    'Kopi Kenangan',
    'Mie Gacoan',
    'Roti Bakar',
    'Es Sundelbolong',
    'Warmindo',
    'Promo Hari Ini',
  ];

  final List<Map<String, dynamic>> _allItems = [
    {
      'name': 'Kopi Kenangan - Plaza Ambarrukmo',
      'type': 'Outlet Mitra',
      'category': 'Kopi & Roti',
      'rating': '4.8',
      'distance': '1.2 km',
      'icon': TablerIcons.building_store,
      'color': const Color(0xFFFEF3C7),
      'iconColor': const Color(0xFFD97706),
    },
    {
      'name': 'Mie Gacoan - Sudirman',
      'type': 'Outlet Mitra',
      'category': 'Mie Pedas & Dimsum',
      'rating': '4.7',
      'distance': '2.5 km',
      'icon': TablerIcons.building_store,
      'color': const Color(0xFFFEE2E2),
      'iconColor': const Color(0xFFDC2626),
    },
    {
      'name': 'Warmindo Prima - Gejayan',
      'type': 'Outlet Mitra',
      'category': 'Warmindo & Minuman',
      'rating': '4.5',
      'distance': '3.1 km',
      'icon': TablerIcons.building_store,
      'color': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF059669),
    },
    {
      'name': 'Kopi Aren Kenangan Mantan',
      'type': 'Menu Produk',
      'price': 'Rp 24.000',
      'store': 'Kopi Kenangan',
      'icon': TablerIcons.coffee,
      'color': const Color(0xFFFEF3C7),
      'iconColor': const Color(0xFFD97706),
    },
    {
      'name': 'Roti Cokelat Keju Premium',
      'type': 'Menu Produk',
      'price': 'Rp 18.000',
      'store': 'Kopi Kenangan',
      'icon': TablerIcons.slice,
      'color': const Color(0xFFFEF3C7),
      'iconColor': const Color(0xFFD97706),
    },
    {
      'name': 'Mie Setan Level 2',
      'type': 'Menu Produk',
      'price': 'Rp 14.500',
      'store': 'Mie Gacoan',
      'icon': TablerIcons.soup,
      'color': const Color(0xFFFEE2E2),
      'iconColor': const Color(0xFFDC2626),
    },
    {
      'name': 'Es Sundelbolong',
      'type': 'Menu Produk',
      'price': 'Rp 10.000',
      'store': 'Mie Gacoan',
      'icon': TablerIcons.glass_full,
      'color': const Color(0xFFDBEAFE),
      'iconColor': const Color(0xFF2563EB),
    },
    {
      'name': 'Indomie Goreng Tante (Tanpa Telur)',
      'type': 'Menu Produk',
      'price': 'Rp 12.000',
      'store': 'Warmindo Prima',
      'icon': TablerIcons.bowl,
      'color': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF059669),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearch(String value, {bool debounce = false}) {
    if (debounce) {
      _debouncer.run(() {
        setState(() {
          _query = value.trim();
        });
      });
    } else {
      _debouncer.dispose();
      setState(() {
        _query = value.trim();
      });
    }
  }

  void _addHistory(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    setState(() {
      _history.remove(clean);
      _history.insert(0, clean);
      if (_history.length > 5) {
        _history.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    final filteredItems = _allItems.where((item) {
      final name = item['name'].toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final store = (item['store'] ?? '').toString().toLowerCase();
      final type = item['type'].toString().toLowerCase();
      final q = _query.toLowerCase();
      return name.contains(q) ||
          category.contains(q) ||
          store.contains(q) ||
          type.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (val) => _onSearch(val, debounce: true),
          onSubmitted: (val) {
            _addHistory(val);
          },
          decoration: InputDecoration(
            hintText: 'Cari toko, menu, atau produk...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      TablerIcons.x,
                      size: 16,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      body: _query.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_history.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RIWAYAT PENCARIAN',
                        style: theme.textTheme.muted.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          TablerIcons.trash,
                          size: 14,
                          color: Colors.black38,
                        ),
                        onPressed: () {
                          setState(() {
                            _history.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _history.map((h) {
                      return InkWell(
                        onTap: () {
                          _searchController.text = h;
                          _onSearch(h);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                TablerIcons.history,
                                size: 12,
                                color: Colors.black38,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                h,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                ],
                Text(
                  'PENCARIAN POPULER',
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularSearches.map((pop) {
                    return ActionChip(
                      label: Text(pop),
                      backgroundColor: Colors.white,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () {
                        _searchController.text = pop;
                        _onSearch(pop);
                        _addHistory(pop);
                      },
                    );
                  }).toList(),
                ),
              ],
            )
          : filteredItems.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TablerIcons.search_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hasil tidak ditemukan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coba cari dengan kata kunci lain',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isStore = item['type'] == 'Outlet Mitra';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['iconColor'] as Color,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isStore
                                ? Colors.indigo.shade50
                                : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['type'] as String,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isStore
                                  ? Colors.indigo.shade700
                                  : Colors.amber.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isStore
                            ? '${item['category']} • ⭐ ${item['rating']} (${item['distance']})'
                            : 'Menu di ${item['store']} • ${item['price']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      isStore ? TablerIcons.chevron_right : TablerIcons.plus,
                      size: 18,
                      color: Warna.primary,
                    ),
                    onTap: () {
                      _addHistory(item['name'] as String);
                      if (isStore) {
                        final colorVal = item['iconColor'] as Color;
                        final hex = '#${colorVal.value.toRadixString(16).substring(2)}';
                        context.push(
                          Uri(
                            path: '/customer/store-detail',
                            queryParameters: {
                              'store_name': item['name'] as String,
                              'category': item['category'] as String,
                              'distance': item['distance'] as String,
                              'banner_color': hex,
                            },
                          ).toString(),
                        );
                      } else {
                        // Product clicked: find matching store details
                        final storeLabel = (item['store'] ?? 'Kopi Kenangan') as String;
                        String storeName = 'Kopi Kenangan - Plaza Ambarrukmo';
                        String category = 'Kopi & Roti';
                        String distance = '1.2 km';
                        String hex = '#D97706';
                        
                        if (storeLabel.contains('Gacoan')) {
                          storeName = 'Mie Gacoan - Sudirman';
                          category = 'Mie Pedas & Dimsum';
                          distance = '2.5 km';
                          hex = '#DC2626';
                        } else if (storeLabel.contains('Warmindo')) {
                          storeName = 'Warmindo Prima - Gejayan';
                          category = 'Warmindo & Minuman';
                          distance = '3.1 km';
                          hex = '#059669';
                        }
                        
                        context.push(
                          Uri(
                            path: '/customer/store-detail',
                            queryParameters: {
                              'store_name': storeName,
                              'category': category,
                              'distance': distance,
                              'banner_color': hex,
                            },
                          ).toString(),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

const List<Map<String, String>> demoLocations = [
  {'city': 'Yogyakarta', 'region': 'Daerah Istimewa Yogyakarta'},
  {'city': 'Jakarta Selatan', 'region': 'DKI Jakarta'},
  {'city': 'Jakarta Pusat', 'region': 'DKI Jakarta'},
  {'city': 'Jakarta Barat', 'region': 'DKI Jakarta'},
  {'city': 'Bandung', 'region': 'Jawa Barat'},
  {'city': 'Surabaya', 'region': 'Jawa Timur'},
  {'city': 'Semarang', 'region': 'Jawa Tengah'},
  {'city': 'Solo', 'region': 'Jawa Tengah'},
  {'city': 'Malang', 'region': 'Jawa Timur'},
  {'city': 'Medan', 'region': 'Sumatera Utara'},
  {'city': 'Makassar', 'region': 'Sulawesi Selatan'},
  {'city': 'Denpasar', 'region': 'Bali'},
  {'city': 'Palembang', 'region': 'Sumatera Selatan'},
];

class CustomerSelectLocationScreen extends ConsumerStatefulWidget {
  const CustomerSelectLocationScreen({super.key});

  @override
  ConsumerState<CustomerSelectLocationScreen> createState() =>
      _CustomerSelectLocationScreenState();
}

class _CustomerSelectLocationScreenState
    extends ConsumerState<CustomerSelectLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final currentLocation = ref.watch(customerLocationProvider);

    final filteredLocations = demoLocations.where((loc) {
      final query = _searchQuery.toLowerCase();
      return loc['city']!.toLowerCase().contains(query) ||
          loc['region']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pilih Lokasi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Field Container
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Cari kota atau wilayah...'),
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(TablerIcons.search, size: 20),
              ),
              decoration: ShadDecoration(
                color: theme.colorScheme.muted.withValues(alpha: 0.3),
                border: ShadBorder.all(
                  color: theme.colorScheme.border.withValues(alpha: 0.5),
                  radius: BorderRadius.circular(24),
                ),
              ),
              onChanged: (val) {
                _debouncer.run(() {
                  setState(() {
                    _searchQuery = val;
                  });
                });
              },
              trailing: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _debouncer.dispose();
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(TablerIcons.x, size: 18),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // GPS Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      ref.read(customerLocationProvider.notifier).state =
                          'Yogyakarta';
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi disesuaikan dengan GPS Anda'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      context.pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Warna.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Warna.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Warna.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              TablerIcons.navigation,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gunakan Lokasi Saat Ini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Temukan gerai terdekat dengan GPS Anda',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            TablerIcons.chevron_right,
                            size: 18,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _searchQuery.isEmpty ? 'KOTA POPULER' : 'HASIL PENCARIAN',
                    style: theme.textTheme.muted.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (filteredLocations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          TablerIcons.map_pin_off,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Lokasi tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredLocations.map((loc) {
                    final isSelected = currentLocation == loc['city'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Warna.primary.withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          TablerIcons.map_pin,
                          size: 18,
                          color: isSelected ? Warna.primary : Colors.grey,
                        ),
                      ),
                      title: Text(
                        loc['city']!,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        loc['region']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              TablerIcons.check,
                              color: Warna.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        ref.read(customerLocationProvider.notifier).state =
                            loc['city']!;
                        context.pop();
                      },
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

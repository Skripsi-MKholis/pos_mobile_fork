import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/customer/models/customer_cart_item.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
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
                  'store_id': sId,
                  'store_name': 'Gerai Aktif',
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
        'id': 'c249606a-cbbb-4e40-9015-4754003c4a0f',
        'name': 'Parzello Tech',
        'category': 'Teknologi & Kuliner',
        'rating': '4.9',
        'distance': '0.1 km',
        'bannerColor': Colors.amber.shade700,
      },
      {
        'id': 'f2effb9f-671a-433c-a76b-e980b4c901e7',
        'name': 'Test Lagii',
        'category': 'Makanan & Restoran',
        'rating': '4.7',
        'distance': '1.5 km',
        'bannerColor': Colors.red.shade700,
      },
      {
        'id': 'cece9918-fa08-4296-bf4e-dd0facc8559b',
        'name': 'Nebula Nosh',
        'category': 'Kafe & Kopi',
        'rating': '4.5',
        'distance': '2.3 km',
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
            InkWell(
              onTap: () => context.push('/customer/all-stores'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B9E00),
                  ),
                ),
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
                        'store_id': store['id'] as String,
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
class CustomerHistoryScreen extends ConsumerStatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  ConsumerState<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends ConsumerState<CustomerHistoryScreen>
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

  String _formatItemsText(List<dynamic> items) {
    if (items.isEmpty) return 'Tidak ada item';
    return items.map((i) => '${i['quantity']}x ${i['product_name']}').join(', ');
  }

  String _formatDateTime(String? createdAtStr) {
    if (createdAtStr == null) return '-';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final minutes = dt.minute.toString().padLeft(2, '0');
        final hours = dt.hour.toString().padLeft(2, '0');
        return 'Hari ini, $hours:$minutes';
      }
      final day = dt.day;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final month = months[dt.month - 1];
      final year = dt.year;
      final minutes = dt.minute.toString().padLeft(2, '0');
      final hours = dt.hour.toString().padLeft(2, '0');
      return '$day $month $year, $hours:$minutes';
    } catch (_) {
      return createdAtStr;
    }
  }

  String _formatRupiah(num number) {
    final str = number.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      buffer.write(str[i]);
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ' + buffer.toString().split('').reversed.join('');
  }

  Map<String, dynamic> _getStatusDecorations(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'label': 'Menunggu',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
        };
      case 'cooking':
        return {
          'label': 'Memasak',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
        };
      case 'served':
        return {
          'label': 'Selesai',
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFECFDF5),
        };
      case 'cancelled':
        return {
          'label': 'Dibatalkan',
          'color': const Color(0xFFE11D48),
          'bg': const Color(0xFFFFF1F2),
        };
      default:
        return {
          'label': status,
          'color': const Color(0xFF6B7280),
          'bg': const Color(0xFFF3F4F6),
        };
    }
  }

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
        final id = item['id'] as String;
        final status = item['status'] as String? ?? 'Pending';
        final dec = _getStatusDecorations(status);
        final storeData = item['stores'] as Map<String, dynamic>?;
        final storeName = storeData?['name'] as String? ?? 'Gerai POS';
        final itemsList = item['transaction_items'] as List<dynamic>? ?? [];
        final itemsStr = _formatItemsText(itemsList);
        final dateStr = _formatDateTime(item['created_at'] as String?);
        final totalAmount = item['total_amount'] as num? ?? 0;
        final amountStr = _formatRupiah(totalAmount);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShadCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () {
                if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'cooking') {
                  context.push('/customer/order/$id');
                } else {
                  context.push('/customer/receipt/$id');
                }
              },
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
                          id,
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
                            color: dec['bg'] as Color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dec['label'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: dec['color'] as Color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itemsStr,
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
                          dateStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                        Text(
                          amountStr,
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
    final transactionsAsync = ref.watch(customerTransactionsProvider);

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
          child: transactionsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Warna.primary),
              ),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Gagal memuat pesanan: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (transactions) {
              final active = transactions
                  .where((t) =>
                      t['status']?.toString().toLowerCase() == 'pending' ||
                      t['status']?.toString().toLowerCase() == 'cooking')
                  .toList();
              final past = transactions
                  .where((t) =>
                      t['status']?.toString().toLowerCase() != 'pending' &&
                      t['status']?.toString().toLowerCase() != 'cooking')
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(active, theme),
                  _buildOrderList(past, theme),
                ],
              );
            },
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
        _buildCustomerHeader(context, theme, ref),
        const SizedBox(height: 32),
        _buildMenuSection(theme, 'AKTIVITAS & LAYANAN', [
          _buildMenuItem(
            context,
            theme,
            TablerIcons.bell,
            'Notifikasi',
            'Lihat pemberitahuan & info promo terbaru',
            () => context.push('/notifications'),
          ),
          _buildMenuItem(
            context,
            theme,
            TablerIcons.scan,
            'Pindai QR / Barcode',
            'Pindai kode QR meja gerai atau struk belanja',
            () => context.push('/customer/scan'),
          ),
          _buildMenuItem(
            context,
            theme,
            TablerIcons.map_pin,
            'Lokasi Gerai',
            'Cari dan pilih gerai toko terdekat',
            () => context.push('/customer/select-location'),
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

  Widget _buildCustomerHeader(BuildContext context, ShadThemeData theme, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Warna.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.primary.withValues(alpha: 0.2)),
      ),
      child: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Warna.primary),
          ),
        ),
        error: (err, stack) => Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(TablerIcons.user_off, color: Colors.red),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Gagal memuat profil',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        data: (profile) {
          final fullName = profile?['full_name'] as String? ?? 'Pelanggan Tamu';
          final email = profile?['email'] as String? ?? 'Belum Terhubung';
          final avatarUrl = profile?['avatar_url'] as String?;

          return Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Warna.primary,
                  borderRadius: BorderRadius.circular(14),
                  image: avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(
                        TablerIcons.user_circle,
                        color: Colors.black,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
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
          );
        },
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

class CustomerOrderTrackingScreen extends ConsumerWidget {
  const CustomerOrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionStreamProvider(orderId));
    final itemsAsync = ref.watch(transactionItemsStreamProvider(orderId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lacak Pesanan', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: transactionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Warna.primary)),
        ),
        error: (err, stack) => Center(child: Text('Gagal melacak pesanan: $err')),
        data: (transaction) {
          if (transaction == null) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }

          final status = transaction['status'] as String? ?? 'Pending';
          final paymentMethod = transaction['payment_method'] as String? ?? 'Tunai';
          final totalAmount = (transaction['total_amount'] ?? 0).toDouble();
          final notes = transaction['notes'] as String?;
          final createdAt = DateTime.tryParse(transaction['created_at'] ?? '') ?? DateTime.now();

          return itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Warna.primary))),
            error: (err, stack) => Center(child: Text('Gagal memuat detail item: $err')),
            data: (items) {
              final hasNotPendingItems = items.any((item) => item['status'] != 'Pending');
              final isCooking = items.any((item) => item['status'] == 'Cooking');
              final isReady = items.any((item) => item['status'] == 'Ready' || item['status'] == 'Served');
              final allServed = items.isNotEmpty && items.every((item) => item['status'] == 'Served');

              final isConfirmed = status == 'Berhasil' || hasNotPendingItems || isCooking || isReady;
              final isPreparing = isCooking || isReady || status == 'Berhasil';
              final isCompleted = status == 'Berhasil' || allServed;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ShadCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order ID: #${orderId.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            _buildBadge(status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              _formatCurrency(totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Warna.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Metode Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ShadCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Pemesanan',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        _buildTimelineStep(
                          title: 'Pesanan Diterima',
                          subtitle: 'Pesanan Anda telah masuk antrean kasir.',
                          time: '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                          isActive: true,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Dikonfirmasi Kasir',
                          subtitle: 'Kasir telah menerima dan memproses pesanan.',
                          isActive: isConfirmed,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Sedang Disiapkan',
                          subtitle: 'Koki sedang memasak makanan pesanan Anda.',
                          isActive: isPreparing,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Selesai',
                          subtitle: 'Pesanan telah disajikan / dibayar.',
                          isActive: isCompleted,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ShadCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daftar Item',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        for (final item in items) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['product_name']} x${item['quantity']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      if (item['status'] != null)
                                        Text(
                                          'Status: ${item['status']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _getItemStatusColor(item['status'] as String),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatCurrency((item['subtotal'] ?? 0).toDouble()),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (status == 'Berhasil')
                    ShadButton(
                      size: ShadButtonSize.lg,
                      backgroundColor: Warna.primary,
                      onPressed: () {
                        context.go('/customer/receipt/$orderId');
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(TablerIcons.receipt_2, color: Warna.black),
                          SizedBox(width: 8),
                          Text('Lihat Struk Digital', style: TextStyle(color: Warna.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    ShadButton.outline(
                      size: ShadButtonSize.lg,
                      onPressed: () {
                        context.go('/customer/store-detail');
                      },
                      child: const Text('Kembali ke Toko'),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _getItemStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey.shade600;
      case 'Cooking':
        return Colors.orange.shade700;
      case 'Ready':
        return Colors.blue.shade700;
      case 'Served':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    String label = status;

    if (status == 'Pending') {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade800;
      label = 'Pending';
    } else if (status == 'Berhasil') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade800;
      label = 'Berhasil';
    } else if (status == 'Dibatalkan') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade800;
      label = 'Batal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    String? time,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isActive ? Warna.primary : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Warna.primary.withOpacity(0.3) : Colors.transparent,
                  width: 4,
                ),
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 10, color: Warna.black)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive ? Warna.primary : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.black87 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  if (time != null)
                    Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isActive ? Colors.grey.shade700 : Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomerReceiptScreen extends ConsumerWidget {
  const CustomerReceiptScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionStreamProvider(transactionId));
    final itemsAsync = ref.watch(transactionItemsStreamProvider(transactionId));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Struk Digital', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: transactionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Warna.primary)),
        ),
        error: (err, stack) => Center(child: Text('Gagal memuat struk: $err')),
        data: (transaction) {
          if (transaction == null) {
            return const Center(child: Text('Transaksi tidak ditemukan.'));
          }

          final status = transaction['status'] as String? ?? 'Pending';
          final paymentMethod = transaction['payment_method'] as String? ?? 'Tunai';
          final totalAmount = (transaction['total_amount'] ?? 0).toDouble();
          final createdAt = DateTime.tryParse(transaction['created_at'] ?? '') ?? DateTime.now();

          final storeDetailsAsync = ref.watch(customerStoreDetailsProvider);
          final storeDetails = storeDetailsAsync.value;
          final storeName = storeDetails?['name'] ?? 'Toko Mitra';
          final storeAddress = storeDetails?['address'] ?? 'Alamat tidak tersedia';
          final storePhone = storeDetails?['phone'] ?? '-';

          return itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Warna.primary))),
            error: (err, stack) => Center(child: Text('Gagal memuat item struk: $err')),
            data: (items) {
              final subtotal = items.fold<double>(0, (sum, item) => sum + (item['subtotal'] ?? 0).toDouble());
              final settings = storeDetails?['settings'] as Map<String, dynamic>?;
              final financial = settings?['financial'] as Map<String, dynamic>?;

              final taxEnabled = financial?['tax_enabled'] ?? false;
              final taxRate = (financial?['tax_rate'] ?? 0).toDouble();
              final serviceChargeEnabled = financial?['service_charge_enabled'] ?? false;
              final serviceChargeRate = (financial?['service_charge_rate'] ?? 0).toDouble();

              final serviceCharge = serviceChargeEnabled ? (subtotal * serviceChargeRate / 100.0) : 0.0;
              final tax = taxEnabled ? (subtotal * taxRate / 100.0) : 0.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                              child: Column(
                                children: [
                                  Text(
                                    storeName,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    storeAddress,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Telp: $storePhone',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(TablerIcons.discount_check_filled, color: Colors.green.shade700, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'LUNAS',
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 10,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            _buildTicketSeparator(),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TGL: ${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                      Text(
                                        'ID: ${transactionId.substring(0, 8).toUpperCase()}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  for (final item in items) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['product_name'] as String? ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                              ),
                                              Text(
                                                '${item['quantity']} x ${_formatCurrency((item['unit_price'] ?? 0).toDouble())}',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency((item['subtotal'] ?? 0).toDouble()),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  const SizedBox(height: 4),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      Text(_formatCurrency(subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  if (serviceChargeEnabled) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Biaya Layanan (${serviceChargeRate.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text(_formatCurrency(serviceCharge), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                  if (taxEnabled) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Pajak (${taxRate.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text(_formatCurrency(tax), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                      Text(_formatCurrency(totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('METODE BAYAR', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      Text(paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            _buildTicketSeparator(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              child: Column(
                                children: [
                                  const Icon(TablerIcons.qrcode, size: 64, color: Colors.black54),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Terima Kasih atas Kunjungan Anda!',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ShadButton.outline(
                              size: ShadButtonSize.lg,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Struk berhasil dibagikan.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(TablerIcons.share, size: 18),
                                  SizedBox(width: 8),
                                  Text('Bagikan Struk'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShadButton(
                              size: ShadButtonSize.lg,
                              backgroundColor: Warna.primary,
                              onPressed: () {
                                context.go('/customer/store-detail');
                              },
                              child: const Text('Selesai', style: TextStyle(color: Warna.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketSeparator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
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

class CustomerAllStoresScreen extends ConsumerStatefulWidget {
  const CustomerAllStoresScreen({super.key});

  @override
  ConsumerState<CustomerAllStoresScreen> createState() => _CustomerAllStoresScreenState();
}

class _CustomerAllStoresScreenState extends ConsumerState<CustomerAllStoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerAllStoresProvider.notifier).fetchStores();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getStoreColor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFFD97706),
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
      const Color(0xFFEA580C),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getColorHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final storesState = ref.watch(customerAllStoresProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Semua Gerai Toko',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Cari nama atau jenis toko...'),
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(TablerIcons.search, size: 20),
              ),
              decoration: ShadDecoration(
                color: Colors.white,
                border: ShadBorder.all(
                  color: theme.colorScheme.border.withValues(alpha: 0.5),
                  radius: BorderRadius.circular(24),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              onChanged: (val) {
                _debouncer.run(() {
                  ref.read(customerAllStoresProvider.notifier).updateSearchQuery(val);
                });
              },
              trailing: storesState.searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref.read(customerAllStoresProvider.notifier).updateSearchQuery('');
                      },
                      child: const Icon(TablerIcons.x, size: 18),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: _buildBody(context, storesState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, CustomerAllStoresState state, ShadThemeData theme) {
    if (state.isLoading && state.stores.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Warna.primary),
        ),
      );
    }

    if (state.errorMessage != null && state.stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Gagal memuat daftar toko:\n${state.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ShadButton(
              onPressed: () => ref.read(customerAllStoresProvider.notifier).fetchStores(refresh: true),
              backgroundColor: Warna.primary,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state.stores.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(customerAllStoresProvider.notifier).fetchStores(refresh: true),
        color: Warna.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      TablerIcons.building_store,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toko tidak ditemukan',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customerAllStoresProvider.notifier).fetchStores(refresh: true),
      color: Warna.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.stores.length + (state.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.stores.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Warna.primary),
                ),
              ),
            );
          }

          final store = state.stores[index];
          final storeId = store['id'] as String;
          final name = store['name'] as String? ?? 'Toko POS';
          final type = store['business_type'] as String? ?? 'Makanan & Minuman';
          final address = store['address'] as String? ?? 'Alamat tidak tersedia';
          final color = _getStoreColor(name);
          final hex = _getColorHex(color);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShadCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  ref.read(customerStoreIdProvider.notifier).state = storeId;
                  context.push(
                    Uri(
                      path: '/customer/store-detail',
                      queryParameters: {
                        'store_id': storeId,
                        'store_name': name,
                        'category': type,
                        'distance': '0.1 km',
                        'banner_color': hex,
                      },
                    ).toString(),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            TablerIcons.building_store,
                            color: color,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type,
                              style: TextStyle(
                                color: Warna.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  TablerIcons.map_pin,
                                  size: 13,
                                  color: Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                      color: theme.colorScheme.mutedForeground,
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        TablerIcons.chevron_right,
                        size: 18,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

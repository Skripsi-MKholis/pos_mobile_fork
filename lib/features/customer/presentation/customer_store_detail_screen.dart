import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/models/customer_cart_item.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';

// Mock Products Catalog Data grouped by store name matches
final Map<String, List<Map<String, dynamic>>> mockStoreProducts = {
  'kopi kenangan': [
    {'id': 'kk1', 'name': 'Kopi Kenangan Mantan', 'price': 22000.0, 'category': 'Minuman', 'badge': 'Terlaris', 'icon': TablerIcons.coffee},
    {'id': 'kk2', 'name': 'Dua Shot Iced Shaken', 'price': 28000.0, 'category': 'Minuman', 'badge': 'Rekomendasi', 'icon': TablerIcons.coffee},
    {'id': 'kk3', 'name': 'Avocoffee Blend', 'price': 30000.0, 'category': 'Minuman', 'icon': TablerIcons.coffee},
    {'id': 'kk4', 'name': 'Americano Klasik Dingin', 'price': 18000.0, 'category': 'Minuman', 'icon': TablerIcons.coffee},
    {'id': 'kk5', 'name': 'Roti Tjokelat Klasik', 'price': 12000.0, 'category': 'Makanan', 'badge': 'Baru', 'icon': TablerIcons.cookie},
    {'id': 'kk6', 'name': 'Roti Keju Manis', 'price': 12000.0, 'category': 'Makanan', 'icon': TablerIcons.cookie},
  ],
  'mie gacoan': [
    {'id': 'mg1', 'name': 'Mie Suit (Gurih No Pedas)', 'price': 12000.0, 'category': 'Makanan', 'icon': TablerIcons.soup},
    {'id': 'mg2', 'name': 'Mie Hompimpa (Pedas Asin)', 'price': 13500.0, 'category': 'Makanan', 'badge': 'Terlaris', 'icon': TablerIcons.soup},
    {'id': 'mg3', 'name': 'Mie Gacoan (Pedas Manis)', 'price': 13500.0, 'category': 'Makanan', 'badge': 'Favorit', 'icon': TablerIcons.soup},
    {'id': 'mg4', 'name': 'Siomay Dimsum (3 pcs)', 'price': 11000.0, 'category': 'Cemilan', 'icon': TablerIcons.meat},
    {'id': 'mg5', 'name': 'Udang Keju Crispy (3 pcs)', 'price': 12500.0, 'category': 'Cemilan', 'badge': 'Rekomendasi', 'icon': TablerIcons.meat},
    {'id': 'mg6', 'name': 'Es Gobak Sodor Segar', 'price': 10500.0, 'category': 'Minuman', 'icon': TablerIcons.glass_full},
    {'id': 'mg7', 'name': 'Es Teklek Manis', 'price': 9000.0, 'category': 'Minuman', 'icon': TablerIcons.glass_full},
  ],
  'warmindo': [
    {'id': 'wm1', 'name': 'Indomie Goreng Double + Telur', 'price': 15000.0, 'category': 'Makanan', 'badge': 'Terlaris', 'icon': TablerIcons.soup},
    {'id': 'wm2', 'name': 'Indomie Kuah Soto Special', 'price': 14000.0, 'category': 'Makanan', 'icon': TablerIcons.soup},
    {'id': 'wm3', 'name': 'Nasi Goreng Magelangan', 'price': 16000.0, 'category': 'Makanan', 'badge': 'Favorit', 'icon': TablerIcons.tools_kitchen_2},
    {'id': 'wm4', 'name': 'Telur Setengah Matang (2 pcs)', 'price': 8000.0, 'category': 'Cemilan', 'icon': TablerIcons.egg},
    {'id': 'wm5', 'name': 'Es Teh Manis Jumbo', 'price': 5000.0, 'category': 'Minuman', 'icon': TablerIcons.glass_full},
    {'id': 'wm6', 'name': 'Es Jeruk Nipis Peras', 'price': 6000.0, 'category': 'Minuman', 'icon': TablerIcons.glass_full},
  ],
};

final List<Map<String, dynamic>> defaultMockProducts = [
  {'id': 'g1', 'name': 'Premium Coffee Latte', 'price': 25000.0, 'category': 'Minuman', 'badge': 'Rekomendasi', 'icon': TablerIcons.coffee},
  {'id': 'g2', 'name': 'Chocolate Lava Cake', 'price': 20000.0, 'category': 'Cemilan', 'icon': TablerIcons.cookie},
  {'id': 'g3', 'name': 'Spaghetti Bolognese', 'price': 35000.0, 'category': 'Makanan', 'badge': 'Terlaris', 'icon': TablerIcons.tools_kitchen_2},
  {'id': 'g4', 'name': 'Iced Peach Tea Segar', 'price': 15000.0, 'category': 'Minuman', 'icon': TablerIcons.glass_full},
];

class CustomerStoreDetailScreen extends ConsumerStatefulWidget {
  const CustomerStoreDetailScreen({
    super.key,
    required this.storeName,
    this.category,
    this.distance,
    this.bannerColorHex,
  });

  final String storeName;
  final String? category;
  final String? distance;
  final String? bannerColorHex;

  @override
  ConsumerState<CustomerStoreDetailScreen> createState() =>
      _CustomerStoreDetailScreenState();
}

class _CustomerStoreDetailScreenState
    extends ConsumerState<CustomerStoreDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 200));
  
  String _searchQuery = '';
  String _selectedCategoryTab = 'Semua';
  String _sortBy = 'default'; // 'default', 'price_asc', 'price_desc'
  bool _isLiked = false;
  bool _hasConfirmedExit = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Keluar dari Toko?'),
        description: const Text(
          'Keranjang belanja Anda di toko ini akan otomatis dikosongkan jika Anda meninggalkan halaman.',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ShadButton.destructive(
            child: const Text('Ya, Keluar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void _handleShare(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Bagikan Toko'),
        description: Text('Bagikan link toko "${widget.storeName}" ke teman Anda.'),
        actions: [
          ShadButton(
            backgroundColor: Warna.primary,
            child: const Text(
              'Salin Link',
              style: TextStyle(color: Warna.black, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan berhasil disalin ke clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(TablerIcons.link, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'https://posmobile.id/store/${widget.storeName.replaceAll(' ', '-').toLowerCase()}',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cartItems = ref.watch(customerCartProvider);
    final cartNotifier = ref.read(customerCartProvider.notifier);

    // Get catalog based on store name search
    final nameLower = widget.storeName.toLowerCase();
    List<Map<String, dynamic>> rawProducts = defaultMockProducts;
    for (final entry in mockStoreProducts.entries) {
      if (nameLower.contains(entry.key)) {
        rawProducts = entry.value;
        break;
      }
    }

    // Filter catalog products
    var filteredProducts = rawProducts.where((prod) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = prod['name'].toString().toLowerCase().contains(q) ||
          prod['category'].toString().toLowerCase().contains(q);
      
      final matchesCategory = _selectedCategoryTab == 'Semua' ||
          prod['category'] == _selectedCategoryTab;

      return matchesQuery && matchesCategory;
    }).toList();

    // Sort catalog products
    if (_sortBy == 'price_asc') {
      filteredProducts.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortBy == 'price_desc') {
      filteredProducts.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
    }

    // Unique Categories list from catalog products
    final categories = ['Semua', ...rawProducts.map((p) => p['category'] as String).toSet()];

    // Custom Banner Color
    Color bannerColor = Warna.primary; // Default primary green tint
    if (widget.bannerColorHex != null) {
      try {
        final hexString = widget.bannerColorHex!.replaceFirst('#', '');
        bannerColor = Color(int.parse('FF$hexString', radix: 16));
      } catch (_) {}
    }

    return PopScope(
      canPop: cartItems.isEmpty || _hasConfirmedExit,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit == true) {
          cartNotifier.clear();
          setState(() {
            _hasConfirmedExit = true;
          });
          if (context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Silver Header Banner with Back & Actions
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: bannerColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(TablerIcons.chevron_left, color: Colors.white, size: 20),
                    ),
                    onPressed: () async {
                      if (cartItems.isEmpty) {
                        context.pop();
                      } else {
                        final shouldExit = await _showExitConfirmation(context);
                        if (shouldExit == true) {
                          cartNotifier.clear();
                          if (context.mounted) {
                            context.pop();
                          }
                        }
                      }
                    },
                  ),
                  actions: [
                    // Loved/Liked Toggle Action
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isLiked ? TablerIcons.heart_filled : TablerIcons.heart,
                          color: _isLiked ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isLiked = !_isLiked;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isLiked 
                                  ? 'Toko ditambahkan ke Favorit Anda' 
                                  : 'Toko dihapus dari Favorit Anda',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    // Share Action
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(TablerIcons.share, color: Colors.white, size: 20),
                      ),
                      onPressed: () => _handleShare(context),
                    ),
                    const SizedBox(width: 12),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            bannerColor,
                            bannerColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          TablerIcons.building_store,
                          color: Colors.white.withValues(alpha: 0.15),
                          size: 100,
                        ),
                      ),
                    ),
                  ),
                ),

                // Store Detail Block
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        // Store Detail Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.storeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: const Text(
                                      'Buka',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.category ?? 'Minuman, Makanan Ringan, Kopi',
                                style: TextStyle(
                                  color: theme.colorScheme.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(TablerIcons.star_filled, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.8',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(TablerIcons.map_pin, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.distance ?? '1.2 km',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const Spacer(),
                                  // Contact phone simulated action
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Menghubungi gerai toko...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Warna.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(TablerIcons.phone, size: 13, color: Warna.black),
                                          SizedBox(width: 4),
                                          Text(
                                            'Hubungi',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Warna.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Jl. Kaliurang KM 5.2, Caturtunggal, Depok, Sleman, Yogyakarta',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Search & Sort bar
                        Row(
                          children: [
                            Expanded(
                              child: ShadInput(
                                controller: _searchController,
                                placeholder: const Text('Cari menu di gerai ini...'),
                                leading: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(TablerIcons.search, size: 18),
                                ),
                                decoration: ShadDecoration(
                                  color: Colors.white,
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
                                        child: const Icon(TablerIcons.x, size: 16),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sort selection popup
                            PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.border.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Icon(TablerIcons.arrows_sort, size: 18, color: Colors.black87),
                              ),
                              onSelected: (val) {
                                setState(() {
                                  _sortBy = val;
                                });
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Text('Default / Rekomendasi'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_asc',
                                  child: Text('Harga Terendah'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_desc',
                                  child: Text('Harga Tertinggi'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Category Horizontal Tabs
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: categories.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategoryTab == cat;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryTab = cat;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Warna.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected 
                                          ? Warna.primary 
                                          : theme.colorScheme.border.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? Colors.black : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Catalog Products Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: filteredProducts.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(TablerIcons.search_off, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'Menu tidak ditemukan',
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final prod = filteredProducts[index];
                              final cartItem = cartItems.firstWhere(
                                (item) => item.id == prod['id'],
                                orElse: () => CustomerCartItem(id: '', name: '', price: 0),
                              );
                              final quantity = cartItem.id.isNotEmpty ? cartItem.quantity : 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.01),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Product icon placeholder
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: bannerColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        prod['icon'] as IconData? ?? TablerIcons.soup,
                                        color: bannerColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (prod['badge'] != null)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Warna.primary.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                prod['badge'] as String,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            prod['name'] as String,
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
                                            'Rp ${(prod['price'] as double).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Action
                                    if (quantity == 0)
                                      ShadButton(
                                        size: ShadButtonSize.sm,
                                        backgroundColor: Warna.primary,
                                        onPressed: () {
                                          cartNotifier.addItem(
                                            CustomerCartItem(
                                              id: prod['id'] as String,
                                              name: prod['name'] as String,
                                              price: prod['price'] as double,
                                              quantity: 1,
                                            ),
                                          );
                                        },
                                        child: const Row(
                                          children: [
                                            Icon(TablerIcons.plus, size: 14, color: Colors.black87),
                                            SizedBox(width: 4),
                                            Text(
                                              'Tambah',
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Warna.primary,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(TablerIcons.minus, size: 12, color: Colors.black87),
                                              onPressed: () {
                                                cartNotifier.decrement(prod['id'] as String);
                                              },
                                            ),
                                            Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                                fontSize: 12,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(TablerIcons.plus, size: 12, color: Colors.black87),
                                              onPressed: () {
                                                cartNotifier.increment(prod['id'] as String);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                            childCount: filteredProducts.length,
                          ),
                        ),
                ),
              ],
            ),

            // Bottom Floating Cart Summary
            if (cartItems.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Warna.black, // Dark themed floating cart summary
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${cartItems.fold(0, (sum, i) => sum + i.quantity)} Items',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${cartNotifier.subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      // View Cart navigates directly to GoRouter Shell Branch for Cart (index 2)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Warna.primary,
                          foregroundColor: Warna.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // In GoRouter StatefulShellRoute, we route to '/customer/cart'
                          context.push('/customer/cart');
                        },
                        child: const Row(
                          children: [
                            Icon(TablerIcons.shopping_cart, size: 16, color: Warna.black),
                            SizedBox(width: 6),
                            Text(
                              'Keranjang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Warna.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

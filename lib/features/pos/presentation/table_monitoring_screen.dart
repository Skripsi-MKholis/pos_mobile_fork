import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:intl/intl.dart';

class TableMonitoringScreen extends ConsumerStatefulWidget {
  const TableMonitoringScreen({super.key});

  @override
  ConsumerState<TableMonitoringScreen> createState() => _TableMonitoringScreenState();
}

class _TableMonitoringScreenState extends ConsumerState<TableMonitoringScreen> {
  bool _loggedView = false;

  @override
  Widget build(BuildContext context) {
    final monitoringAsync = ref.watch(tableMonitoringProvider);
    final theme = ShadTheme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Track analytics after the data is loaded
    if (!_loggedView) {
      monitoringAsync.whenData((orders) {
        _loggedView = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final activeTablesCount = orders.where((o) => o.table.status == 'occupied').length;
            final waitingOrdersCount = orders.where((o) => o.table.status == 'occupied' && o.items.isNotEmpty).length;
            await AnalyticsService.instance.logTableMonitoringView(
              activeTablesCount: activeTablesCount,
              waitingOrdersCount: waitingOrdersCount,
            );
          } catch (_) {}
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Monitoring Meja',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.refresh),
            onPressed: () => ref.invalidate(tableMonitoringProvider),
          ),
        ],
      ),
      body: monitoringAsync.when(
        data: (orders) => orders.isEmpty
            ? _buildEmptyState(theme)
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildTableCard(context, ref, order, currencyFormat);
                },
              ),
        loading: () => _buildSkeleton(context),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.armchair,
            size: 80,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada meja',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan meja di pengaturan untuk mulai monitoring.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    WidgetRef ref,
    TableOrder order,
    NumberFormat format,
  ) {
    final theme = ShadTheme.of(context);
    final status = order.table.status;
    final isOccupied = status == 'occupied';
    
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'available':
        statusColor = Warna.success;
        statusLabel = 'Tersedia';
        break;
      case 'occupied':
        statusColor = Warna.destructive;
        statusLabel = 'Terisi';
        break;
      case 'cleaning':
        statusColor = Colors.blue;
        statusLabel = 'Dibersihkan';
        break;
      case 'reserved':
        statusColor = Colors.orange;
        statusLabel = 'Dipesan';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    final totalAmount = order.transaction?['total_amount'] ?? 0.0;

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _showOrderDetails(context, ref, order, format),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  TablerIcons.users,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  '${order.table.capacity}',
                  style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Icon(
                TablerIcons.table,
                size: 48,
                color: isOccupied ? statusColor : theme.colorScheme.muted,
              ),
            ),
            const Spacer(),
            Text(
              order.table.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            if (isOccupied) ...[
              const SizedBox(height: 4),
              Text(
                format.format(totalAmount),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ] else
              Text(
                'Meja Kosong',
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _showOrderDetails(
    BuildContext context,
    WidgetRef ref,
    TableOrder order,
    NumberFormat format,
  ) {
    final theme = ShadTheme.of(context);
    final isOccupied = order.table.status == 'occupied';

    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meja ${order.table.name}',
                      style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isOccupied ? 'Pesanan Aktif' : 'Status: Tersedia',
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
                ShadButton.ghost(
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(TablerIcons.x),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isOccupied && order.items.isNotEmpty) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item['quantity']}x',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['product_name'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            format.format(item['subtotal']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    format.format(order.transaction?['total_amount'] ?? 0),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () {
                        Navigator.pop(context);
                        
                        // Load existing items for this table
                        final products = ref.read(productNotifierProvider).value ?? [];
                        final List<CartItem> cartItems = [];
                        
                        for (var item in order.items) {
                          final product = products.firstWhere(
                            (p) => p.supabaseId == item['product_id'],
                            orElse: () => Product(
                              supabaseId: item['product_id'],
                              storeId: order.table.storeId,
                              name: item['product_name'],
                              price: (item['unit_price'] as num).toDouble(),
                              stockQuantity: 0,
                            ),
                          );
                          cartItems.add(CartItem(product: product, quantity: item['quantity']));
                        }

                        final cartNotifier = ref.read(cartNotifierProvider.notifier);
                        cartNotifier.clearCart();
                        cartNotifier.selectTable(order.table);
                        cartNotifier.setItems(cartItems);
                        cartNotifier.setTransactionId(order.transaction?['id']);
                        
                        context.go('/pos');
                      },
                      leading: const Icon(TablerIcons.plus, size: 18),
                      child: const Text('Tambah Item'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadButton(
                      backgroundColor: Warna.primary,
                      onPressed: () {
                        Navigator.pop(context);
                        _handleCheckout(context, ref, order);
                      },
                      child: const Text(
                        'Bayar',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('Belum ada pesanan aktif di meja ini.'),
                ),
              ),
              ShadButton(
                width: double.infinity,
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(cartNotifierProvider.notifier).selectTable(order.table);
                  context.go('/pos');
                },
                child: const Text('Buka Pesanan Baru'),
              ),
            ],
            const SizedBox(height: 12),
            if (isOccupied)
               ShadButton.ghost(
                 width: double.infinity,
                 onPressed: () {
                   // Clear table status
                   ref.read(tableMonitoringProvider.notifier).updateTableStatus(order.table.id, 'available');
                   Navigator.pop(context);
                 },
                 child: const Text('Kosongkan Meja (Tanpa Bayar)', style: TextStyle(color: Colors.red)),
               ),
          ],
        ),
      ),
    );
  }

  void _handleCheckout(BuildContext context, WidgetRef ref, TableOrder order) {
    // Show choice: Pay All or Split Bill
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Pilih Metode Pembayaran'),
        description: const Text('Apakah ingin membayar seluruh tagihan atau memisah pembayaran?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to Split Bill
                    context.push('/split-bill', extra: order);
                  },
                  child: const Text('Bayar Pisah'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadButton(
                  backgroundColor: Warna.primary,
                  onPressed: () {
                    Navigator.pop(context);
                    // Prepare cart with table items and go to payment
                    _prepareCartForPayment(ref, order);
                    context.push('/payment');
                  },
                  child: const Text('Bayar Semua', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _prepareCartForPayment(WidgetRef ref, TableOrder order) {
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final products = ref.read(productNotifierProvider).value ?? [];
    
    final List<CartItem> cartItems = [];
    for (var item in order.items) {
      final product = products.firstWhere(
        (p) => p.supabaseId == item['product_id'],
        orElse: () => Product(
          supabaseId: item['product_id'],
          storeId: item['store_id'] ?? '',
          name: item['product_name'],
          price: (item['unit_price'] as num).toDouble(),
          stockQuantity: 0,
        ),
      );
      cartItems.add(CartItem(product: product, quantity: item['quantity']));
    }

    cartNotifier.clearCart();
    cartNotifier.selectTable(order.table);
    cartNotifier.setItems(cartItems);
    
    // Apply voucher if exists
    if (order.transaction?['voucher_info'] != null) {
      // Re-apply voucher logic could go here if needed
    }
  }

  Widget _buildSkeleton(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

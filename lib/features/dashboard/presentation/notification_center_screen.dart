import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_provider.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  String _selectedFilter = 'all'; // 'all', 'unread', 'low_stock', 'transaction_void'

  Future<void> _refresh() async {
    ref.invalidate(notificationNotifierProvider);
    await ref.read(notificationNotifierProvider.future);
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h lalu';
    } else {
      return DateFormat('d MMM, HH:mm').format(date);
    }
  }

  String _formatDateGroup(DateTime? date) {
    if (date == null) return 'Lainnya';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDate = DateTime(date.year, date.month, date.day);

    if (notifDate == today) {
      return 'Hari Ini';
    } else if (notifDate == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'low_stock':
      case 'warning':
        return TablerIcons.alert_triangle;
      case 'transaction_void':
      case 'danger':
        return TablerIcons.receipt_off;
      case 'success':
        return TablerIcons.circle_check;
      case 'announcement':
        return TablerIcons.speakerphone;
      case 'promo':
        return TablerIcons.ticket;
      case 'technical':
        return TablerIcons.tool;
      default:
        return TablerIcons.bell;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'low_stock':
        return const Color(0xFFEA580C); // Warm Orange/Amber
      case 'danger':
      case 'transaction_void':
        return const Color(0xFFE11D48); // Rose red
      case 'warning':
        return const Color(0xFFD97706); // Amber
      case 'success':
        return const Color(0xFF10B981); // Emerald
      case 'announcement':
        return const Color(0xFF2563EB); // Blue
      case 'promo':
        return const Color(0xFF7C3AED); // Purple
      case 'technical':
        return const Color(0xFF4B5563); // Cool Gray
      default:
        return const Color(0xFF0D9488); // Teal
    }
  }

  void _handleNotificationTap(NotificationLocalModel notif) {
    if (!notif.isRead) {
      ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notif.supabaseId);
    }

    if (notif.type == 'low_stock' || notif.type == 'danger') {
      context.push('/products');
    } else if (notif.type == 'transaction_void' || notif.type == 'warning') {
      context.push('/transactions');
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    await ref.read(notificationNotifierProvider.notifier).markAllAsRead();
    if (!mounted) return;
    mySnackBar(
      context: context,
      text: 'Semua notifikasi ditandai dibaca',
      status: ToastStatus.success,
    );
  }

  void _showClearAllConfirmDialog() {
    showShadDialog(
      context: context,
      builder: (dialogCtx) => ShadDialog(
        title: const Text('Hapus Semua Notifikasi?'),
        description: const Text(
          'Tindakan ini akan menghapus riwayat notifikasi secara permanen.',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          ShadButton(
            backgroundColor: Warna.destructive,
            pressedBackgroundColor: Colors.red.shade800,
            child: const Text('Hapus Semua'),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref
                  .read(notificationNotifierProvider.notifier)
                  .clearAll();
              if (!mounted) return;
              mySnackBar(
                context: context,
                text: 'Semua notifikasi dihapus',
                status: ToastStatus.success,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    int? count,
  }) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Pusat Notifikasi',
                  style: theme.textTheme.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Warna.destructive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount baru',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Warna.destructive,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unreadCount > 0)
                    IconButton(
                      icon: const Icon(TablerIcons.checks, size: 20, color: Colors.black87),
                      tooltip: 'Tandai Semua Dibaca',
                      onPressed: _handleMarkAllAsRead,
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(TablerIcons.dots_vertical, size: 20, color: Colors.black87),
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'read_all') {
                        _handleMarkAllAsRead();
                      } else if (value == 'clear_all') {
                        _showClearAllConfirmDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      if (unreadCount > 0)
                        const PopupMenuItem(
                          value: 'read_all',
                          height: 40,
                          child: Row(
                            children: [
                              Icon(TablerIcons.checks, size: 16),
                              SizedBox(width: 10),
                              Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'clear_all',
                        height: 40,
                        child: Row(
                          children: [
                            Icon(TablerIcons.trash, size: 16, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              'Hapus Semua',
                              style: TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        error: (error, stack) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(TablerIcons.alert_triangle, size: 36, color: Colors.red.shade700),
              ),
              const SizedBox(height: 16),
              Text('Gagal memuat notifikasi', style: theme.textTheme.large),
              const SizedBox(height: 8),
              SelectableText(
                error.toString(),
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ShadButton.outline(
                child: const Text('Coba Lagi'),
                onPressed: () => ref.invalidate(notificationNotifierProvider),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.black87,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            TablerIcons.bell_off,
                            size: 38,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Notifikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pemberitahuan stok dan void transaksi\nakan muncul secara real-time di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Apply selected filter
          final filteredList = list.where((n) {
            if (_selectedFilter == 'unread') {
              return !n.isRead;
            } else if (_selectedFilter == 'low_stock') {
              return n.type == 'low_stock';
            } else if (_selectedFilter == 'transaction_void') {
              return n.type == 'transaction_void';
            }
            return true;
          }).toList();

          // Count badges for tabs
          final stockCount = list.where((n) => n.type == 'low_stock' && !n.isRead).length;
          final voidCount = list.where((n) => n.type == 'transaction_void' && !n.isRead).length;

          // Mengelompokkan notifikasi terfilter berdasarkan tanggal
          final Map<String, List<NotificationLocalModel>> grouped = {};
          for (var notif in filteredList) {
            final groupKey = _formatDateGroup(notif.createdAt);
            if (grouped[groupKey] == null) {
              grouped[groupKey] = [];
            }
            grouped[groupKey]!.add(notif);
          }

          final groupKeys = grouped.keys.toList();

          return Column(
            children: [
              // Filter Chips Bar (Hemat Space & Intuitif)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Semua',
                        value: 'all',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Belum Dibaca',
                        value: 'unread',
                        count: unreadCount,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Stok Tipis',
                        value: 'low_stock',
                        count: stockCount,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Void Kasir',
                        value: 'transaction_void',
                        count: voidCount,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

              // Content List
              Expanded(
                child: filteredList.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refresh,
                        color: Colors.black87,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.20),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    TablerIcons.filter_off,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada notifikasi pada filter ini',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: Colors.black87,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(top: 8, bottom: 40),
                          itemCount: groupKeys.length,
                          itemBuilder: (context, groupIndex) {
                            final groupKey = groupKeys[groupIndex];
                            final groupItems = grouped[groupKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                                  child: Text(
                                    groupKey.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                ...groupItems.map((notif) {
                                  final notifColor = _getColor(notif.type);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14.0,
                                      vertical: 3.5,
                                    ),
                                    child: Dismissible(
                                      key: Key('notif_${notif.supabaseId}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20.0),
                                        decoration: BoxDecoration(
                                          color: Warna.destructive,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Hapus',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              TablerIcons.trash,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                      onDismissed: (direction) {
                                        ref
                                            .read(notificationNotifierProvider.notifier)
                                            .deleteNotification(notif.supabaseId);
                                        mySnackBar(
                                          context: context,
                                          text: 'Notifikasi dihapus',
                                          status: ToastStatus.success,
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: notif.isRead
                                                ? Colors.black.withValues(alpha: 0.05)
                                                : notifColor.withValues(alpha: 0.3),
                                            width: notif.isRead ? 0.8 : 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: notif.isRead
                                                  ? Colors.black.withValues(alpha: 0.015)
                                                  : notifColor.withValues(alpha: 0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          child: InkWell(
                                            onTap: () => _handleNotificationTap(notif),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12.0,
                                                vertical: 10.0,
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Compact Category Icon
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 2),
                                                    padding: const EdgeInsets.all(7),
                                                    decoration: BoxDecoration(
                                                      color: notifColor.withValues(alpha: 0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      _getIcon(notif.type),
                                                      color: notifColor,
                                                      size: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Notification Info & Message
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                notif.title,
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(
                                                                  fontWeight: notif.isRead
                                                                      ? FontWeight.w600
                                                                      : FontWeight.w800,
                                                                  fontSize: 13,
                                                                  color: Colors.grey.shade900,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              _formatRelativeTime(notif.createdAt),
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: notif.isRead
                                                                    ? FontWeight.w500
                                                                    : FontWeight.w700,
                                                                color: notif.isRead
                                                                    ? Colors.grey.shade400
                                                                    : notifColor,
                                                              ),
                                                            ),
                                                            if (!notif.isRead) ...[
                                                              const SizedBox(width: 6),
                                                              Container(
                                                                width: 6,
                                                                height: 6,
                                                                decoration: BoxDecoration(
                                                                  color: notifColor,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        const SizedBox(height: 3),
                                                        Text(
                                                          notif.message,
                                                          style: TextStyle(
                                                            color: notif.isRead
                                                                ? Colors.grey.shade600
                                                                : Colors.grey.shade800,
                                                            fontSize: 11.5,
                                                            height: 1.35,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

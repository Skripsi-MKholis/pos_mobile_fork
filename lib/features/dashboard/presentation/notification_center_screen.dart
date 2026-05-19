import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  Future<void> _refresh() async {
    // Memaksa reload provider untuk menyinkronkan data terbaru dari Supabase
    ref.invalidate(notificationNotifierProvider);
    await ref.read(notificationNotifierProvider.future);
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
        return TablerIcons.alert_circle;
      case 'success':
        return TablerIcons.circle_check;
      case 'announcement':
        return TablerIcons.speakerphone;
      case 'promo':
        return TablerIcons.ticket;
      case 'technical':
        return TablerIcons.tool;
      default:
        return TablerIcons.info_circle;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'low_stock':
      case 'danger':
        return Colors.red;
      case 'transaction_void':
      case 'warning':
        return Colors.amber.shade800;
      case 'success':
        return Colors.green;
      case 'announcement':
        return Colors.blue;
      case 'promo':
        return Colors.indigo;
      case 'technical':
        return Colors.orange;
      default:
        return Colors.lightGreen;
    }
  }

  void _handleNotificationTap(NotificationLocalModel notif) {
    // 1. Tandai sebagai dibaca secara lokal & remote
    if (!notif.isRead) {
      ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notif.supabaseId);
    }

    // 2. Navigasi berdasarkan jenis notifikasi
    if (notif.type == 'low_stock' || notif.type == 'danger') {
      context.push('/products');
    } else if (notif.type == 'transaction_void' || notif.type == 'warning') {
      context.push('/transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin =
        role?.toLowerCase() == 'owner' || user?.appMetadata['role'] == 'admin';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notifikasi',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(TablerIcons.dots_vertical),
                onSelected: (value) async {
                  if (value == 'read_all') {
                    await ref
                        .read(notificationNotifierProvider.notifier)
                        .markAllAsRead();
                    if (mounted) {
                      mySnackBar(
                        context: context,
                        text: 'Semua notifikasi ditandai dibaca',
                        status: ToastStatus.success,
                      );
                    }
                  } else if (value == 'clear_all') {
                    // Tampilkan dialog konfirmasi sebelum menghapus semua
                    showShadDialog(
                      context: context,
                      builder: (context) => ShadDialog(
                        title: const Text('Hapus Semua Notifikasi?'),
                        description: const Text(
                          'Tindakan ini akan menghapus seluruh riwayat notifikasi secara permanen.',
                        ),
                        actions: [
                          ShadButton.outline(
                            child: const Text('Batal'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ShadButton(
                            backgroundColor: Colors.red,
                            pressedBackgroundColor: Colors.red.shade800,
                            child: const Text('Hapus'),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await ref
                                  .read(notificationNotifierProvider.notifier)
                                  .clearAll();
                              if (mounted) {
                                mySnackBar(
                                  context: context,
                                  text: 'Semua notifikasi dihapus',
                                  status: ToastStatus.success,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(TablerIcons.checks, size: 18),
                        SizedBox(width: 8),
                        Text('Tandai Semua Dibaca'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(TablerIcons.trash, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Hapus Semua',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                TablerIcons.alert_triangle,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text('Gagal memuat notifikasi', style: theme.textTheme.large),
              const SizedBox(height: 8),
              SelectableText(
                error.toString(),
                style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ShadButton(
                child: const Text('Coba Lagi'),
                onPressed: () => ref.invalidate(notificationNotifierProvider),
              ),
              const SizedBox(height: 24),
              SelectableText(
                stack.toString(),
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            TablerIcons.bell_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Belum Ada Notifikasi',
                          style: theme.textTheme.large.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pemberitahuan stok menipis dan pembatalan\ntransaksi akan ditampilkan di sini.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Mengelompokkan notifikasi berdasarkan tanggal
          final Map<String, List<NotificationLocalModel>> grouped = {};
          for (var notif in list) {
            final groupKey = _formatDateGroup(notif.createdAt);
            if (grouped[groupKey] == null) {
              grouped[groupKey] = [];
            }
            grouped[groupKey]!.add(notif);
          }

          final groupKeys = grouped.keys.toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: groupKeys.length,
              itemBuilder: (context, index) {
                final groupKey = groupKeys[index];
                final groupItems = grouped[groupKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 20.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        groupKey.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...groupItems.map((notif) {
                      final notifColor = _getColor(notif.type);
                      return Dismissible(
                        key: Key('notif_${notif.supabaseId}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          color: Colors.red,
                          child: const Icon(
                            TablerIcons.trash,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          ref
                              .read(notificationNotifierProvider.notifier)
                              .deleteNotification(notif.supabaseId);
                          mySnackBar(
                            context: context,
                            text: 'Notifikasi telah dihapus',
                            status: ToastStatus.success,
                          );
                        },
                        child: InkWell(
                          onTap: () => _handleNotificationTap(notif),
                          child: Container(
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? Colors.transparent
                                  : notifColor.withOpacity(0.04),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 14.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ikon Notifikasi Berwarna
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: notifColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIcon(notif.type),
                                    color: notifColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Isi Notifikasi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: theme.textTheme.large
                                                  .copyWith(
                                                    fontWeight: notif.isRead
                                                        ? FontWeight.normal
                                                        : FontWeight.bold,
                                                    color: Colors.grey.shade900,
                                                  ),
                                            ),
                                          ),
                                          // Indikator Titik Belum Dibaca
                                          if (!notif.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: notifColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: theme.textTheme.muted.copyWith(
                                          color: notif.isRead
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif.createdAt != null
                                            ? DateFormat(
                                                'HH:mm',
                                              ).format(notif.createdAt!)
                                            : '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/broadcast-notification'),
              backgroundColor: Warna.primary,
              child: const Icon(TablerIcons.speakerphone, color: Colors.black),
            )
          : null,
    );
  }
}

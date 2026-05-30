import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:pos_mobile/core/widgets/app_drawer.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/features/pos/providers/transaction_history_provider.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_provider.dart';
import 'package:pos_mobile/core/services/fcm_service.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? lastPressed;
  int? _lastIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      FCMService.instance.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin =
        role?.toLowerCase() == 'owner' || user?.appMetadata['role'] == 'admin';

    // Listener untuk notifikasi real-time yang masuk untuk menampilkan Toast instan
    ref.listen<NotificationLocalModel?>(lastReceivedNotificationProvider, (
      previous,
      next,
    ) {
      if (next != null) {
        final isDestructive = next.type == 'low_stock' || next.type == 'danger';
        final isWarning =
            next.type == 'warning' || next.type == 'transaction_void';
        final isSuccess = next.type == 'success';

        final ToastStatus toastStatus;
        if (isDestructive) {
          toastStatus = ToastStatus.error;
        } else if (isWarning) {
          toastStatus = ToastStatus.warning;
        } else if (isSuccess) {
          toastStatus = ToastStatus.success;
        } else {
          toastStatus = ToastStatus.success;
        }

        mySnackBar(
          context: context,
          text: '${next.title}: ${next.message}',
          status: toastStatus,
        );

        // Reset agar tidak memicu ulang toast pada rebuild UI berikutnya
        Future.microtask(() {
          ref.read(lastReceivedNotificationProvider.notifier).state = null;
        });
      }
    });

    // Auto-refresh transaction history when switching to Riwayat tab/branch (index 2)
    final currentIndex = widget.navigationShell.currentIndex;
    if (_lastIndex != currentIndex) {
      _lastIndex = currentIndex;
      if (currentIndex == 2) {
        Future.microtask(() {
          if (mounted) {
            ref.read(transactionHistoryProvider.notifier).refresh();
          }
        });
      }
    }

    // Reset ke Dashboard saat ganti toko
    ref.listen(activeStoreProvider, (previous, next) {
      if (previous?.value != null && next.value != null) {
        if (previous?.value?['id'] != next.value?['id']) {
          widget.navigationShell.goBranch(0);
        }
      }
    });

    // Tentukan item navigasi berdasarkan Role dengan pemetaan Branch yang eksplisit
    final List<Map<String, dynamic>> navItems = isAdmin
        ? [
            {'icon': TablerIcons.chart_pie, 'label': l10n.homeTab, 'branch': 0},
            {'icon': TablerIcons.shopping_cart, 'label': l10n.cashierTab, 'branch': 1},
            {'icon': TablerIcons.history, 'label': l10n.historyTab, 'branch': 2},
            {'icon': TablerIcons.report_money, 'label': l10n.reportsTab, 'branch': 3},
            {'icon': TablerIcons.layout_grid, 'label': l10n.menuTab, 'branch': 4},
          ]
        : [
            {
              'icon': TablerIcons.layout_dashboard,
              'label': l10n.homeTab,
              'branch': 0,
            },
            {'icon': TablerIcons.shopping_cart, 'label': l10n.cashierTab, 'branch': 1},
            {'icon': TablerIcons.history, 'label': l10n.historyTab, 'branch': 2},
            {'icon': TablerIcons.layout_grid, 'label': l10n.menuTab, 'branch': 4},
          ];

    // Judul AppBar berdasarkan branch yang aktif (bukan berdasarkan index bottom bar)
    final String pageTitle;
    switch (widget.navigationShell.currentIndex) {
      case 0:
        pageTitle = l10n.dashboardTitle;
        break;
      case 1:
        pageTitle = l10n.cashierTab;
        break;
      case 2:
        pageTitle = l10n.transactionHistoryTitle;
        break;
      case 3:
        pageTitle = l10n.reportsTitle;
        break;
      case 4:
        pageTitle = l10n.settingsTitle;
        break;
      default:
        pageTitle = 'Parzello POS';
    }

    // Cari index yang terpilih di GNav berdasarkan branch yang aktif di GoRouter
    final int selectedIndex = navItems.indexWhere(
      (item) => item['branch'] == widget.navigationShell.currentIndex,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Jika tidak di tab pertama (Dashboard), kembali ke tab pertama dulu
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
          return;
        }

        final now = DateTime.now();
        final backButtonHasNotBeenPressedRecently =
            lastPressed == null ||
            now.difference(lastPressed!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedRecently) {
          lastPressed = now;
          if (mounted) {
            mySnackBar(
              context: context,
              text: l10n.pressAgainToExit,
              status: ToastStatus.warning,
            );
          }
          return;
        }

        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            pageTitle,
            style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(TablerIcons.menu_2),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final status = ref.watch(connectivityNotifierProvider);
                return status.when(
                  data: (s) {
                    if (s == ConnectivityStatus.online) {
                      return const SizedBox.shrink();
                    }
                    return InkWell(
                      onTap: () {
                        context.push('/settings/sync-monitoring');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Offline',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(
                    unreadNotificationCountProvider,
                  );
                  return Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    child: const Icon(TablerIcons.bell),
                  );
                },
              ),
              onPressed: () {
                context.push('/notifications');
              },
            ),
          ],
        ),
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          height: 100, // Extra height to allow floating
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.9,
                    ), // Modern opacity
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withValues(alpha: .2),
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GNav(
                      rippleColor: Colors.white10,
                      hoverColor: Colors.white10,
                      gap: 4,
                      activeColor: Colors.white,
                      iconSize: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      duration: const Duration(milliseconds: 300),
                      tabBackgroundColor: Warna.primary.withValues(alpha: 0.8),
                      color: Colors.white54,
                      tabs: navItems
                          .map(
                            (item) => GButton(
                              icon: item['icon'],
                              text: item['label'],
                              textStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                      selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
                      onTabChange: (index) {
                        final item = navItems[index];
                        if (item['branch'] != null) {
                          widget.navigationShell.goBranch(
                            item['branch'] as int,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

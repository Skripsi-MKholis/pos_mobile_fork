import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class StoreSelectionScreen extends ConsumerStatefulWidget {
  const StoreSelectionScreen({super.key});

  @override
  ConsumerState<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends ConsumerState<StoreSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Clear active store when entering this screen
    Future.microtask(() {
      ref.read(activeStoreProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final storesAsync = ref.watch(userStoresProvider);
    final connectivity = ref.watch(connectivityNotifierProvider).value;
    final isOffline = connectivity == ConnectivityStatus.offline;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pilih Toko',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.logout, color: Colors.redAccent),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable List Area
            Expanded(
              child: storesAsync.when(
                data: (stores) {
                  if (stores.isEmpty) {
                    if (isOffline) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildOfflineEmptyState(context, theme),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildEmptyState(context, theme),
                    );
                  }
                  
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // Beautiful bouncing physics!
                    itemCount: stores.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      // Show section label above the first card!
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center, // Centered title!
                              children: [
                                const Icon(TablerIcons.building_store, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  'OUTLET ANDA',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 16),
                            _buildStoreCard(context, ref, theme, store, Warna.primary),
                          ],
                        );
                      }
                      return _buildStoreCard(context, ref, theme, store, Warna.primary);
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: Warna.primary,
                  ),
                ),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),

            // Sticky Bottom Buttons Container
            Container(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0, top: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Join with Invite Code Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isOffline
                          ? null
                          : () => _showJoinStoreDialog(context, Warna.primary, theme),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOffline
                            ? Colors.grey.shade100
                            : Warna.primary, // Solid brand green primary!
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            TablerIcons.ticket,
                            size: 18,
                            color: isOffline ? Colors.grey : Colors.black,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Punya Kode Undangan?',
                            style: TextStyle(
                              color: isOffline ? Colors.grey : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 1,
                        width: 40,
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'atau kelola toko baru',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 1,
                        width: 40,
                        color: Colors.grey.shade200,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                   // Register New Store Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isOffline
                          ? null
                          : () => context.push('/create-store'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isOffline ? Colors.grey.shade300 : Warna.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        '+ Daftarkan Toko / Outlet Baru',
                        style: TextStyle(
                          color: isOffline ? Colors.grey : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    WidgetRef ref,
    ShadThemeData theme,
    Map<String, dynamic> store,
    Color primaryColor,
  ) {
    final String role = store['user_role'] ?? 'Staff';
    final bool isOwner = role.toLowerCase() == 'owner';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await ref.read(activeStoreProvider.notifier).selectStore(store);
            if (context.mounted) {
              context.go('/dashboard');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Tighter padding!
            child: Row(
              children: [
                // Store Logo/Icon
                Container(
                  width: 44, // More compact size!
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(22), // Completely circular/capsule avatar!
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: (store['logo_url'] != null && store['logo_url'].toString().isNotEmpty)
                        ? Image.network(
                            store['logo_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(TablerIcons.building_store, size: 20),
                          )
                        : const Icon(TablerIcons.building_store, size: 20),
                  ),
                ),
                const SizedBox(width: 12), // Tighter gap
                // Store Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'] ?? 'Toko Tanpa Nama',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Tighter font size
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4), // Tighter vertical gap
                      Row(
                        children: [
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Tighter badge!
                            decoration: BoxDecoration(
                              color: isOwner
                                  ? Warna.primary // brand primary green!
                                  : Colors.grey.shade100, // clean gray background
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: isOwner
                                    ? Colors.black // maximum readability on primary green
                                    : Colors.grey.shade700, // clean gray text
                                fontWeight: FontWeight.bold,
                                fontSize: 9, // Smaller font
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Outlet',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11, // Smaller outlet label
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(TablerIcons.chevron_right, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _joinStore(String code) async {
    final supabase = sb.Supabase.instance.client;

    try {
      final response = await supabase.rpc(
        'join_store_by_code',
        params: {'p_code': code},
      );

      if (response == null) {
        if (mounted) {
          mySnackBar(
            context: context,
            text: 'Kode undangan tidak valid.',
            status: ToastStatus.error,
          );
        }
        return;
      }

      // Refresh stores list
      ref.invalidate(userStoresProvider);

      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Berhasil bergabung ke toko!',
          status: ToastStatus.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal bergabung: $e',
          status: ToastStatus.error,
        );
      }
    }
  }


  void _showJoinStoreDialog(
    BuildContext context,
    Color primaryColor,
    ShadThemeData theme,
  ) {
    final codeController = TextEditingController();

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(TablerIcons.ticket, color: Colors.black, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Gabung ke Toko'),
            ],
          ),
        ),
        description: const Text(
          'Masukkan 8 karakter kode undangan yang diberikan oleh pemilik toko Anda.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final code = codeController.text.trim();
                if (code.isEmpty) return;
                _joinStore(code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Warna.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Gabung Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KODE UNDANGAN',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ShadInput(
                controller: codeController,
                placeholder: const Text('CONTOH: X7H2K9A1'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: ShadDecoration(
                  color: Colors.grey[50],
                  border: ShadBorder.all(
                    color: Colors.grey[300]!,
                    width: 1,
                    radius: const BorderRadius.all(Radius.circular(30)),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context, ShadThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(TablerIcons.building, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'Belum ada toko',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anda perlu membuat toko pertama Anda untuk memulai.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineEmptyState(BuildContext context, ShadThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(TablerIcons.cloud_off, size: 64, color: Colors.redAccent),
          const SizedBox(height: 24),
          const Text(
            'Koneksi Internet Diperlukan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          const Text(
            'Untuk penggunaan pertama kali, wajib terhubung ke internet agar data toko dapat disinkronkan ke perangkat Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

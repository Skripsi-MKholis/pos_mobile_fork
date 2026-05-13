import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
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
    final primaryColor = theme.colorScheme.primary;
    final storesAsync = ref.watch(userStoresProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(TablerIcons.building_store, size: 48, color: primaryColor),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                'Pilih Toko',
                style: theme.textTheme.h1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Silakan pilih toko untuk mulai mengelola operasional.',
                textAlign: TextAlign.center,
                style: theme.textTheme.muted.copyWith(fontSize: 16),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),

              // Section Label
              Row(
                children: [
                  Icon(TablerIcons.building_store, size: 20, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'OUTLET ANDA',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              // Store List
              storesAsync.when(
                data: (stores) {
                  if (stores.isEmpty) {
                    return _buildEmptyState(context, theme);
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stores.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return _buildStoreCard(context, ref, theme, store, primaryColor);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 48),

              // Bottom Buttons
              Column(
                children: [
                  // Join with Invite Code Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () =>
                          _showJoinStoreDialog(context, primaryColor, theme),
                      style: TextButton.styleFrom(
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(TablerIcons.ticket, size: 20, color: primaryColor),
                          const SizedBox(width: 12),
                          Text(
                            'Punya Kode Undangan?',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Ingin mengelola toko baru?',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 12),

                   // Register New Store Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/create-store'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        side: BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Text(
                        '+ Daftarkan Toko / Outlet Baru',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
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
        borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Store Logo/Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (store['logo_url'] != null && store['logo_url'].toString().isNotEmpty)
                        ? Image.network(
                            store['logo_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(TablerIcons.building_store, size: 28),
                          )
                        : const Icon(TablerIcons.building_store, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                // Store Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'] ?? 'Toko Tanpa Nama',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          text: role.toUpperCase(),
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: ' • Toko',
                              style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
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
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('Error'),
              description: const Text('Kode undangan tidak valid.'),
            ),
          );
        }
        return;
      }

      // Refresh stores list
      ref.invalidate(userStoresProvider);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Berhasil'),
            description: Text('Berhasil bergabung ke toko!'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Gagal bergabung: $e'),
          ),
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
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(TablerIcons.ticket, color: primaryColor, size: 32),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: ShadDecoration(
                  color: Colors.grey[50],
                  border: ShadBorder.all(
                    color: Colors.grey[300]!,
                    width: 1,
                    radius: const BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
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
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
}

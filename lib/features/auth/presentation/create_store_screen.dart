import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';

class CreateStoreScreen extends ConsumerStatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  ConsumerState<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends ConsumerState<CreateStoreScreen> {
  int _currentStep = 0;
  String _selectedModel = 'Restaurant';
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _businessModels = [
    {
      'id': 'Restaurant',
      'title': 'Restoran / F&B',
      'subtitle': 'Mendukung Meja, KDS, & Reservasi',
      'icon': TablerIcons.tools_kitchen_2,
      'color': const Color(0xFFE9FCD4),
      'iconColor': const Color(0xFF9AE600),
    },
    {
      'id': 'Retail',
      'title': 'Toko Ritel / Dagang',
      'subtitle': 'Fokus pada kecepatan & stok produk',
      'icon': TablerIcons.building_store,
      'color': const Color(0xFFE0F2FE),
      'iconColor': const Color(0xFF0EA5E9),
    },
    {
      'id': 'Cafe',
      'title': 'Kedai Kopi / Cafe',
      'subtitle': 'Sistem antrean & display dapur',
      'icon': TablerIcons.flame,
      'color': const Color(0xFFFEF3C7),
      'iconColor': const Color(0xFFF59E0B),
    },
  ];

  Future<void> _handleCreateStore() async {
    if (_nameController.text.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(description: Text('Nama toko tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(activeStoreProvider.notifier).createStore(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            businessType: _selectedModel,
          );
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal membuat toko: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Header Icon
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Warna.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Warna.primary.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(TablerIcons.building_store,
                          size: 28, color: Colors.black),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  Text(
                    'Selamat Datang!',
                    style: theme.textTheme.h2.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'Satu langkah lagi untuk memulai bisnis Anda. Mari buat toko pertama Anda.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.muted.copyWith(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  // Step Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Progress Bar
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(32)),
                              ),
                            ),
                            AnimatedContainer(
                              duration: 400.ms,
                              height: 6,
                              width: MediaQuery.of(context).size.width *
                                  (_currentStep == 0 ? 0.5 : 1.0),
                              decoration: BoxDecoration(
                                color: Warna.primary,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(32)),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: AnimatedSwitcher(
                            duration: 300.ms,
                            child: _currentStep == 0
                                ? _buildStep1(theme)
                                : _buildStep2(theme),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
            // Back Button
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(TablerIcons.chevron_left, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shadowColor: Colors.black.withOpacity(0.1),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ShadThemeData theme) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Model Bisnis',
          style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Fitur akan menyesuaikan secara otomatis.',
          style: theme.textTheme.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 24),
        ..._businessModels.map((model) => _buildModelCard(model)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            onPressed: () => setState(() => _currentStep = 1),
            size: ShadButtonSize.lg,
            backgroundColor: Warna.primary,
            foregroundColor: Colors.black,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lanjut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 8),
                Icon(TablerIcons.arrow_right, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(ShadThemeData theme) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _currentStep = 0),
              icon: const Icon(TablerIcons.chevron_left, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Text(
              'Informasi Toko',
              style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'NAMA TOKO / OUTLET',
          style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _nameController,
          placeholder: const Text('Contoh: Kopi Kenangan Jaya'),
          padding: const EdgeInsets.all(16),
          decoration: ShadDecoration(
            color: const Color(0xFFF3F4F6),
            border: ShadBorder.all(color: Colors.grey.shade300, radius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ALAMAT LENGKAP',
          style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _addressController,
          placeholder: const Text('Jl. Merdeka No. 123'),
          padding: const EdgeInsets.all(16),
          maxLines: 2,
          decoration: ShadDecoration(
            color: const Color(0xFFF3F4F6),
            border: ShadBorder.all(color: Colors.grey.shade300, radius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            onPressed: _isLoading ? null : _handleCreateStore,
            size: ShadButtonSize.lg,
            backgroundColor: Warna.primary.withOpacity(_isLoading ? 0.5 : 1.0),
            foregroundColor: Colors.black,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Konfirmasi & Mulai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text.rich(
            TextSpan(
              text: 'Dengan klik Konfirmasi, fitur ',
              style: theme.textTheme.muted.copyWith(fontSize: 11),
              children: [
                TextSpan(
                  text: _selectedModel.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Warna.primary),
                ),
                const TextSpan(text: ' akan langsung disiapkan untuk anda.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    final isSelected = _selectedModel == model['id'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedModel = model['id']),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? Warna.primary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Warna.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: model['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(model['icon'], color: model['iconColor'], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model['subtitle'],
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(TablerIcons.circle_check_filled, color: Warna.primary, size: 24)
              else
                Icon(TablerIcons.circle, color: Colors.grey.shade200, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

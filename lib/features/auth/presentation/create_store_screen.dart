import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/core/services/wilayah_service.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

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

  // Location state
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedCityName;
  List<Map<String, dynamic>>? _cachedProvinces;
  bool _loadingProvinces = false;
  bool _loadingCities = false;

  final List<Map<String, dynamic>> _businessModels = [
    {
      'id': 'Restaurant',
      'title': 'Restoran / F&B',
      'subtitle': 'Restoran, warung makan, katering',
      'icon': TablerIcons.tools_kitchen_2,
      'color': const Color(0xFFE9FCD4),
      'iconColor': const Color(0xFF9AE600),
    },
    {
      'id': 'Retail',
      'title': 'Toko Ritel / Dagang',
      'subtitle': 'Toko kelontong, minimarket, fashion',
      'icon': TablerIcons.building_store,
      'color': const Color(0xFFE0F2FE),
      'iconColor': const Color(0xFF0EA5E9),
    },
    {
      'id': 'Cafe',
      'title': 'Kedai Kopi / Cafe',
      'subtitle': 'Kafe, bakeri, minuman kekinian',
      'icon': TablerIcons.flame,
      'color': const Color(0xFFFEF3C7),
      'iconColor': const Color(0xFFF59E0B),
    },
  ];

  Future<void> _handleCreateStore() async {
    if (_nameController.text.isEmpty) {
      mySnackBar(
        context: context,
        text: 'Nama toko tidak boleh kosong',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(activeStoreProvider.notifier).createStore(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            businessType: _selectedModel,
            province: _selectedProvinceName,
            city: _selectedCityName,
          );
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal membuat toko: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProvince() async {
    setState(() => _loadingProvinces = true);
    List<Map<String, dynamic>> provinces;
    try {
      provinces = _cachedProvinces ?? await WilayahService.instance.getProvinces();
      _cachedProvinces = provinces;
    } catch (e) {
      if (mounted) {
        mySnackBar(context: context, text: 'Gagal memuat provinsi: $e', status: ToastStatus.error);
      }
      setState(() => _loadingProvinces = false);
      return;
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }

    if (!mounted) return;
    final selected = await _showLocationPickerSheet(
      title: 'Pilih Provinsi',
      items: provinces,
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedProvinceCode = selected['code'];
        _selectedProvinceName = WilayahService.instance.toTitleCase(selected['name']);
        _selectedCityName = null;
      });
    }
  }

  Future<void> _pickCity() async {
    if (_selectedProvinceCode == null) {
      mySnackBar(context: context, text: 'Pilih provinsi terlebih dahulu', status: ToastStatus.error);
      return;
    }
    setState(() => _loadingCities = true);
    List<Map<String, dynamic>> cities;
    try {
      cities = await WilayahService.instance.getCities(_selectedProvinceCode!);
    } catch (e) {
      if (mounted) {
        mySnackBar(context: context, text: 'Gagal memuat kota: $e', status: ToastStatus.error);
      }
      setState(() => _loadingCities = false);
      return;
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }

    if (!mounted) return;
    final selected = await _showLocationPickerSheet(
      title: 'Pilih Kota / Kabupaten',
      items: cities,
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCityName = WilayahService.instance.toTitleCase(selected['name']);
      });
    }
  }

  Future<Map<String, dynamic>?> _showLocationPickerSheet({
    required String title,
    required List<Map<String, dynamic>> items,
  }) async {
    final searchController = TextEditingController();
    Map<String, dynamic>? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.toLowerCase();
            final filtered = query.isEmpty
                ? items
                : items
                    .where((e) => e['name'].toString().toLowerCase().contains(query))
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(TablerIcons.search, size: 18),
                        fillColor: const Color(0xFFF3F4F6),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(
                            WilayahService.instance.toTitleCase(item['name']),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            result = item;
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

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
                      child: const Icon(TablerIcons.building_store, size: 28, color: Colors.black),
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
                    style: theme.textTheme.muted.copyWith(fontSize: 14, height: 1.4),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

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
                        // Progress bar
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              ),
                            ),
                            AnimatedContainer(
                              duration: 400.ms,
                              height: 6,
                              width: MediaQuery.of(context).size.width *
                                  (_currentStep == 0 ? 0.5 : 1.0),
                              decoration: BoxDecoration(
                                color: Warna.primary,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            // Back button
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
          'Pilih Kategori Bisnis',
          style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih kategori yang paling sesuai dengan bisnis Anda.',
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

        // Nama toko
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

        // Provinsi
        Text(
          'PROVINSI',
          style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        _buildLocationPickerTile(
          icon: TablerIcons.map,
          value: _selectedProvinceName,
          placeholder: 'Pilih Provinsi',
          isLoading: _loadingProvinces,
          onTap: _pickProvince,
        ),
        const SizedBox(height: 20),

        // Kota / Kabupaten
        Text(
          'KOTA / KABUPATEN',
          style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        _buildLocationPickerTile(
          icon: TablerIcons.map_pin,
          value: _selectedCityName,
          placeholder: _selectedProvinceCode == null ? 'Pilih provinsi dulu' : 'Pilih Kota / Kabupaten',
          isLoading: _loadingCities,
          isDisabled: _selectedProvinceCode == null,
          onTap: _pickCity,
        ),
        const SizedBox(height: 24),

        // Alamat
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
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text(
                    'Konfirmasi & Mulai',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPickerTile({
    required IconData icon,
    required String? value,
    required String placeholder,
    required bool isLoading,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled || isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: isLoading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Text(
                      value ?? placeholder,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                        color: value != null
                            ? Colors.black87
                            : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade500),
                      ),
                    ),
            ),
            Icon(
              TablerIcons.chevron_down,
              size: 16,
              color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade500,
            ),
          ],
        ),
      ),
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
                    ),
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

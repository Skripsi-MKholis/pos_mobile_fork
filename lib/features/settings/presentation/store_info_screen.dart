import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/services/wilayah_service.dart';
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/core/utils/image_picker_helper.dart';

class StoreInfoScreen extends ConsumerStatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  ConsumerState<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends ConsumerState<StoreInfoScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _isSaving = false;
  bool _isDeleting = false;
  File? _imageFile;
  bool _logoRemoved = false;

  // Initial State Tracking (untuk deteksi dirty/perubahan)
  String? _initialName;
  String? _initialPhone;
  String? _initialAddress;
  String? _initialProvinceName;
  String? _initialCityName;
  Set<int> _initialOpenWeekdays = {1, 2, 3, 4, 5, 6, 7};
  int _initialOpenHour = 8;
  int _initialCloseHour = 21;

  // Current Form State
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // Location state
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedCityName;
  List<Map<String, dynamic>>? _cachedProvinces;
  bool _loadingProvinces = false;
  bool _loadingCities = false;
  bool _locationInitialized = false;

  // Profil operasional toko
  Set<int> _openWeekdays = {1, 2, 3, 4, 5, 6, 7};
  List<int> _existingClosedMonths = const [];
  int _openHour = 8;
  int _closeHour = 21;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationInitialized) {
      _locationInitialized = true;
      final activeStore = ref.read(activeStoreProvider).value;
      if (activeStore != null) {
        _initialName = activeStore['name']?.toString() ?? '';
        _initialPhone = activeStore['phone']?.toString() ?? '';
        _initialAddress = activeStore['address']?.toString() ?? '';
        _initialProvinceName = activeStore['province'] as String?;
        _initialCityName = activeStore['city'] as String?;

        _nameController.text = _initialName ?? '';
        _phoneController.text = _initialPhone ?? '';
        _addressController.text = _initialAddress ?? '';

        _selectedProvinceName = _initialProvinceName;
        _selectedCityName = _initialCityName;

        final profile = StoreOperationalProfile.fromStoreSettings(activeStore);
        _initialOpenWeekdays = profile.openWeekdays.toSet();
        _existingClosedMonths = profile.closedMonths;
        _initialOpenHour = profile.openHour;
        _initialCloseHour = profile.closeHour;

        _openWeekdays = Set.from(_initialOpenWeekdays);
        _openHour = _initialOpenHour;
        _closeHour = _initialCloseHour;
      }
    }
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  /// Mengecek apakah terdapat perubahan yang belum disimpan
  bool get _hasChanges {
    // 1. Logo
    if (_imageFile != null || _logoRemoved) return true;

    // 2. Text fields
    if (_nameController.text.trim() != (_initialName ?? '').trim()) return true;
    if (_phoneController.text.trim() != (_initialPhone ?? '').trim()) return true;
    if (_addressController.text.trim() != (_initialAddress ?? '').trim()) return true;

    // 3. Location
    if (_selectedProvinceName != _initialProvinceName) return true;
    if (_selectedCityName != _initialCityName) return true;

    // 4. Operational profile
    if (!_setEquals(_openWeekdays, _initialOpenWeekdays)) return true;
    if (_openHour != _initialOpenHour) return true;
    if (_closeHour != _initialCloseHour) return true;

    return false;
  }

  /// Menampilkan dialog konfirmasi saat user menekan back dengan data belum disimpan
  Future<bool> _handlePopScope() async {
    if (!_hasChanges) return true;

    final isId = Localizations.localeOf(context).languageCode == 'id';
    final shouldLeave = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text(
          isId ? 'Perubahan Belum Disimpan' : 'Unsaved Changes',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        description: Text(
          isId
              ? 'Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar tanpa menyimpan?'
              : 'You have unsaved changes. Are you sure you want to discard them and leave?',
        ),
        actions: [
          ShadButton.outline(
            child: Text(isId ? 'Tetap di Sini' : 'Stay Here'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text(isId ? 'Buang Perubahan' : 'Discard Changes'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
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
    final selected = await _showLocationPickerSheet(title: 'Pilih Provinsi', items: provinces);
    if (selected != null && mounted) {
      setState(() {
        _selectedProvinceCode = selected['code'];
        _selectedProvinceName = WilayahService.instance.toTitleCase(selected['name']);
        _selectedCityName = null;
      });
    }
  }

  Future<void> _pickCity() async {
    if (_selectedProvinceCode == null && _selectedProvinceName != null) {
      if (_cachedProvinces == null) {
        setState(() => _loadingProvinces = true);
        try {
          _cachedProvinces = await WilayahService.instance.getProvinces();
        } catch (_) {} finally {
          if (mounted) setState(() => _loadingProvinces = false);
        }
      }
      if (_cachedProvinces != null) {
        final match = _cachedProvinces!.where((p) =>
            WilayahService.instance.toTitleCase(p['name']) == _selectedProvinceName).firstOrNull;
        if (match != null) _selectedProvinceCode = match['code'];
      }
    }

    if (_selectedProvinceCode == null) {
      if (!mounted) return;
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
    final selected = await _showLocationPickerSheet(title: 'Pilih Kota / Kabupaten', items: cities);
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
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(TablerIcons.x, size: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari nama daerah...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(TablerIcons.search, size: 18, color: Colors.grey),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Warna.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final name = WilayahService.instance.toTitleCase(item['name']);
                        return ListTile(
                          dense: true,
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(TablerIcons.chevron_right, size: 16, color: Colors.grey),
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

  Widget _buildLocationPickerTile({
    required IconData icon,
    required String? value,
    required String placeholder,
    required bool isLoading,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled || isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDisabled ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isLoading
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Warna.black,
                        ),
                      ),
                    )
                  : Text(
                      value ?? placeholder,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                        color: value != null
                            ? const Color(0xFF1E293B)
                            : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade400),
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

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final activeStore = ref.watch(activeStoreProvider).value;

    if (activeStore == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Text(
            isId ? 'Toko tidak ditemukan' : 'Store not found',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final storeName = activeStore['name'] ?? 'Toko';
    final businessType = activeStore['business_type'] ?? 'Retail';
    final hasChanges = _hasChanges;

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _handlePopScope();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isId ? 'Informasi Toko' : 'Store Information',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isId ? 'Kelola identitas outlet & jadwal operasional' : 'Manage outlet identity & operating hours',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 70,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.chevron_left, size: 19, color: Color(0xFF334155)),
            ),
            onPressed: () async {
              final shouldLeave = await _handlePopScope();
              if (shouldLeave && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: const Color(0xFFE2E8F0),
              height: 1,
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ShadButton(
              backgroundColor: hasChanges ? Warna.primary : const Color(0xFFE2E8F0),
              foregroundColor: hasChanges ? Warna.black : const Color(0xFF94A3B8),
              onPressed: (!hasChanges || _isSaving) ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Warna.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          TablerIcons.device_floppy,
                          size: 18,
                          color: hasChanges ? Warna.black : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isId ? 'Simpan Perubahan' : 'Save Changes',
                          style: TextStyle(
                            color: hasChanges ? Warna.black : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: ShadForm(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Identity Header Card (Logo, Name, Business Type)
                  _buildHeaderIdentityCard(activeStore, storeName, businessType, isId),
                  const SizedBox(height: 14),

                  // 2. Business Details Form Card
                  _buildFormCard(activeStore, theme, isId),
                  const SizedBox(height: 14),

                  // 3. Operational Profile Card
                  _buildOperationalCard(theme, isId),
                  const SizedBox(height: 14),

                  // 4. Danger Zone Card (Owner only)
                  _buildDangerZoneCard(activeStore, theme, isId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header identitas toko: logo di kiri, nama toko, tipe bisnis, dan tombol ganti logo.
  Widget _buildHeaderIdentityCard(
    Map<String, dynamic> activeStore,
    String storeName,
    String businessType,
    bool isId,
  ) {
    final currentLogo = activeStore['logo_url'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Avatar
          GestureDetector(
            onTap: () => _handleChangeLogo(currentLogo),
            child: Stack(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: Warna.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _logoRemoved
                      ? _buildPlaceholderLogo(storeName)
                      : (_imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : (currentLogo != null && currentLogo.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: currentLogo,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey.shade200,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) => _buildPlaceholderLogo(storeName),
                                )
                              : _buildPlaceholderLogo(storeName))),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Warna.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      TablerIcons.camera,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Name and Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    letterSpacing: -0.3,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(TablerIcons.building_store, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            businessType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _handleChangeLogo(currentLogo),
                      child: Text(
                        isId ? 'Ubah Logo' : 'Change Logo',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderLogo(String storeName) {
    return Center(
      child: Text(
        storeName.trim().isNotEmpty ? storeName.trim()[0].toUpperCase() : 'T',
        style: const TextStyle(
          fontSize: 24,
          color: Warna.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  /// Card Formulir Detail Toko
  Widget _buildFormCard(
    Map<String, dynamic> activeStore,
    ShadThemeData theme,
    bool isId,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.info_circle, size: 17, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                isId ? 'Detail Informasi Toko' : 'Store Information Details',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nama Toko
          ShadInputFormField(
            id: 'name',
            controller: _nameController,
            label: Text(
              isId ? 'Nama Toko' : 'Store Name',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            placeholder: Text(
              isId ? 'Masukkan nama toko' : 'Enter store name',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            validator: (v) => v.trim().length < 3 
                ? (isId ? 'Nama toko minimal 3 karakter' : 'Store name too short') 
                : null,
            leading: const Padding(
              padding: EdgeInsets.only(left: 10, right: 6),
              child: Icon(TablerIcons.building_store, size: 17, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // Nomor Telepon
          ShadInputFormField(
            id: 'phone',
            controller: _phoneController,
            label: Text(
              isId ? 'Nomor Telepon / WhatsApp' : 'Phone / WhatsApp Number',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            placeholder: Text(
              isId ? 'Contoh: 08123456789' : 'Example: 08123456789',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            keyboardType: TextInputType.phone,
            leading: const Padding(
              padding: EdgeInsets.only(left: 10, right: 6),
              child: Icon(TablerIcons.phone, size: 17, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // Alamat
          ShadInputFormField(
            id: 'address',
            controller: _addressController,
            label: Text(
              isId ? 'Alamat Lengkap' : 'Full Address',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            placeholder: Text(
              isId ? 'Masukkan jalan, nomor, RT/RW, dsb.' : 'Enter street address, building, etc.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            maxLines: 2,
            leading: const Padding(
              padding: EdgeInsets.only(left: 10, right: 6, top: 10),
              child: Icon(TablerIcons.map_pin, size: 17, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // Provinsi
          Text(
            isId ? 'Provinsi' : 'Province',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          _buildLocationPickerTile(
            icon: TablerIcons.map,
            value: _selectedProvinceName,
            placeholder: isId ? 'Pilih Provinsi' : 'Select Province',
            isLoading: _loadingProvinces,
            onTap: _pickProvince,
          ),
          const SizedBox(height: 16),

          // Kota / Kabupaten
          Text(
            isId ? 'Kota / Kabupaten' : 'City / Regency',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          _buildLocationPickerTile(
            icon: TablerIcons.map_pin,
            value: _selectedCityName,
            placeholder: _selectedProvinceName == null
                ? (isId ? 'Pilih provinsi terlebih dahulu' : 'Select province first')
                : (isId ? 'Pilih Kota / Kabupaten' : 'Select City / Regency'),
            isLoading: _loadingCities,
            isDisabled: _selectedProvinceName == null,
            onTap: _pickCity,
          ),
        ],
      ),
    );
  }

  /// Profil operasional toko
  Widget _buildOperationalCard(ShadThemeData theme, bool isId) {
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final openDaysCount = _openWeekdays.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.clock, size: 17, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isId ? 'Jadwal & Jam Operasional' : 'Operating Schedule & Hours',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$openDaysCount/7 ${isId ? 'Hari' : 'Days'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Warna.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isId
                ? 'Diselaraskan dengan model prediksi analitik penjualan toko'
                : 'Synced with the predictive analytics sales forecast model',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Hari Buka
          Text(
            isId ? 'Hari Operasional Buka' : 'Open Days',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int day = 1; day <= 7; day++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: day < 7 ? 6 : 0),
                    child: _buildDayChip(
                      label: dayLabels[day - 1],
                      selected: _openWeekdays.contains(day),
                      onTap: () => setState(() {
                        if (_openWeekdays.contains(day)) {
                          if (_openWeekdays.length > 1) _openWeekdays.remove(day);
                        } else {
                          _openWeekdays.add(day);
                        }
                      }),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Jam Operasional
          Text(
            isId ? 'Jam Operasional Harian' : 'Daily Operating Hours',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHourPicker(
                  label: isId ? 'Buka Pukul' : 'Opens At',
                  hour: _openHour,
                  theme: theme,
                  onChanged: (value) => setState(() {
                    _openHour = value;
                    if (_closeHour <= _openHour) _closeHour = _openHour + 1;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHourPicker(
                  label: isId ? 'Tutup Pukul' : 'Closes At',
                  hour: _closeHour,
                  theme: theme,
                  minHour: _openHour + 1,
                  onChanged: (value) => setState(() => _closeHour = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Warna.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Warna.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? Warna.black : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildHourPicker({
    required String label,
    required int hour,
    required ShadThemeData theme,
    required ValueChanged<int> onChanged,
    int minHour = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 5),
        ShadSelect<int>(
          initialValue: hour,
          options: [
            for (int h = minHour; h <= 23; h++)
              ShadOption(
                value: h,
                child: Text('${h.toString().padLeft(2, '0')}:00'),
              ),
          ],
          selectedOptionBuilder: (context, value) =>
              Text('${value.toString().padLeft(2, '0')}:00', style: const TextStyle(fontWeight: FontWeight.w600)),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }

  Widget _buildDangerZoneCard(
    Map<String, dynamic> activeStore,
    ShadThemeData theme,
    bool isId,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
    final isOwner = activeStore['owner_id'] == user?.id;
    if (!isOwner) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.trash, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isId ? 'Hapus Toko Ini' : 'Delete This Store',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Colors.red,
                  ),
                ),
                Text(
                  isId ? 'Hapus toko dan sembunyikan dari staf' : 'Hide store permanently from all staff',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          ShadButton.destructive(
            size: ShadButtonSize.sm,
            onPressed: _isDeleting ? null : () => _handleDeleteStore(activeStore, isId),
            child: _isDeleting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isId ? 'Hapus' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteStore(Map<String, dynamic> activeStore, bool isId) async {
    final storeName = activeStore['name'] ?? '';
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text(isId ? 'Hapus "$storeName"?' : 'Delete "$storeName"?'),
        description: Text(
          isId
              ? 'Tindakan ini tidak dapat dibatalkan sendiri melalui aplikasi. Semua staf akan kehilangan akses ke toko ini.'
              : 'This action cannot be undone from within the app. All staff will lose access to this store.',
        ),
        actions: [
          ShadButton.outline(
            child: Text(isId ? 'Batal' : 'Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text(isId ? 'Ya, Hapus' : 'Yes, Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(activeStoreProvider.notifier).deleteStore();
      if (mounted) {
        mySnackBar(
          context: context,
          text: isId ? 'Toko berhasil dihapus' : 'Store deleted successfully',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: isId ? 'Gagal menghapus toko: $e' : 'Failed to delete store: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _handleChangeLogo(String? currentLogo) async {
    final isId = Localizations.localeOf(context).languageCode == 'id';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isId ? 'Ubah Logo Toko' : 'Change Store Logo',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(TablerIcons.photo, color: Warna.black, size: 20),
              ),
              title: Text(
                isId ? 'Pilih dari Galeri' : 'Pick from Gallery',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(TablerIcons.camera, color: Color(0xFF1E293B), size: 20),
              ),
              title: Text(
                isId ? 'Ambil Foto Baru' : 'Take a Photo',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageFile != null || (currentLogo != null && currentLogo.isNotEmpty && !_logoRemoved)) ...[
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(TablerIcons.trash, color: Colors.red, size: 20),
                ),
                title: Text(
                  isId ? 'Hapus Logo' : 'Remove Logo',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _logoRemoved = true;
                  });
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await AppImagePicker.pickStoreLogo(source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _logoRemoved = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() => _isSaving = true);

    try {
      final activeStore = ref.read(activeStoreProvider).value!;
      final supabase = Supabase.instance.client;

      String? logoUrl = activeStore['logo_url'];

      if (_logoRemoved) {
        logoUrl = null;
      } else if (_imageFile != null) {
        final rand = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
        final fileName = 'store_${activeStore['id']}_$rand.png';
        final path = 'store_logos/$fileName';

        await supabase.storage.from('product-images').upload(path, _imageFile!);
        logoUrl = supabase.storage.from('product-images').getPublicUrl(path);
      }

      final existingSettings = activeStore['settings'] is Map
          ? Map<String, dynamic>.from(activeStore['settings'] as Map)
          : <String, dynamic>{};
      final existingOperational = existingSettings['operational'] is Map
          ? Map<String, dynamic>.from(existingSettings['operational'] as Map)
          : <String, dynamic>{};

      final openWeekdays = (_openWeekdays.toList()..sort());
      final updatedSettings = {
        ...existingSettings,
        'operational': {
          ...existingOperational,
          'open_weekdays': openWeekdays,
          'open_on_weekends':
              openWeekdays.contains(6) || openWeekdays.contains(7),
          'closed_months': _existingClosedMonths,
          'open_hour': _openHour,
          'close_hour': _closeHour,
        },
      };

      final updatedName = _nameController.text.trim();
      final updatedPhone = _phoneController.text.trim();
      final updatedAddress = _addressController.text.trim();

      final updatedData = {
        'name': updatedName,
        'phone': updatedPhone,
        'address': updatedAddress,
        'logo_url': logoUrl,
        'province': _selectedProvinceName,
        'city': _selectedCityName,
        'settings': updatedSettings,
      };

      await supabase.from('stores').update(updatedData).eq('id', activeStore['id']);

      await ref.read(activeStoreProvider.notifier).selectStore({
        ...activeStore,
        ...updatedData,
      });

      // Update snapshot awal agar tombol disabled kembali & tidak memicu dialog konfirmasi
      if (mounted) {
        setState(() {
          _initialName = updatedName;
          _initialPhone = updatedPhone;
          _initialAddress = updatedAddress;
          _initialProvinceName = _selectedProvinceName;
          _initialCityName = _selectedCityName;
          _initialOpenWeekdays = Set.from(_openWeekdays);
          _initialOpenHour = _openHour;
          _initialCloseHour = _closeHour;
          _imageFile = null;
          _logoRemoved = false;
        });

        mySnackBar(
          context: context,
          text: Localizations.localeOf(context).languageCode == 'id'
              ? 'Informasi toko berhasil disimpan'
              : 'Store information saved successfully',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: Localizations.localeOf(context).languageCode == 'id'
              ? 'Gagal memperbarui data: $e'
              : 'Failed to update data: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

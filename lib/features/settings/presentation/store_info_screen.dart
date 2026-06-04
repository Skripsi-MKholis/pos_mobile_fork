import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class StoreInfoScreen extends ConsumerStatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  ConsumerState<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends ConsumerState<StoreInfoScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _isSaving = false;
  File? _imageFile;
  bool _logoRemoved = false;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final activeStore = ref.watch(activeStoreProvider).value;

    if (activeStore == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
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

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isId ? 'Informasi Toko' : 'Store Information',
              style: theme.textTheme.h3.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            Text(
              isId ? 'Kelola identitas dan detail bisnis Anda' : 'Manage your business identity & details',
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.chevron_left, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 80,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: ShadForm(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // BENTO CARD 1: Logo & Store Identity
                _buildLogoBentoCard(activeStore, storeName, businessType, theme, isId),
                const SizedBox(height: 16),

                // BENTO CARD 2: Detail Informasi Toko (Form)
                _buildFormBentoCard(activeStore, theme, isId),
                const SizedBox(height: 24),

                // Primary Save Button
                SizedBox(
                  width: double.infinity,
                  child: MyButtonPrimary(
                    backgroundColor: Warna.primary,
                    radius: 16,
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Warna.black,
                            ),
                          )
                        : Text(
                            isId ? 'Simpan Perubahan' : 'Save Changes',
                            style: const TextStyle(
                              color: Warna.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoBentoCard(
    Map<String, dynamic> activeStore,
    String storeName,
    String businessType,
    ShadThemeData theme,
    bool isId,
  ) {
    final currentLogo = activeStore['logo_url'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _handleChangeLogo(currentLogo),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Warna.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    height: 92,
                    width: 92,
                    decoration: BoxDecoration(
                      color: Warna.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
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
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Warna.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      TablerIcons.pencil,
                      color: Warna.black,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),

          // Store Name (Display)
          Text(
            storeName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
              color: Warna.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Business Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Warna.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Warna.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(TablerIcons.building_store, size: 14, color: Warna.black),
                const SizedBox(width: 6),
                Text(
                  businessType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Warna.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildPlaceholderLogo(String storeName) {
    return Center(
      child: Text(
        storeName.trim().isNotEmpty ? storeName.trim()[0].toUpperCase() : 'T',
        style: const TextStyle(
          fontSize: 36,
          color: Warna.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildFormBentoCard(
    Map<String, dynamic> activeStore,
    ShadThemeData theme,
    bool isId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            isId ? 'INFORMASI DETAIL BISNIS' : 'BUSINESS DETAIL INFORMATION',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.black45,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadInputFormField(
                id: 'name',
                label: Text(
                  isId ? 'Nama Toko' : 'Store Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                initialValue: activeStore['name'],
                placeholder: Text(isId ? 'Masukkan nama toko' : 'Enter store name'),
                validator: (v) => v.length < 3 
                    ? (isId ? 'Nama terlalu pendek' : 'Name too short') 
                    : null,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(TablerIcons.building_store, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              ShadInputFormField(
                id: 'phone',
                label: Text(
                  isId ? 'Nomor Telepon' : 'Phone Number',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                initialValue: activeStore['phone'] ?? '',
                placeholder: Text(isId ? 'Contoh: 08123456789' : 'Example: 08123456789'),
                keyboardType: TextInputType.phone,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(TablerIcons.phone, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              ShadInputFormField(
                id: 'address',
                label: Text(
                  isId ? 'Alamat Lengkap' : 'Full Address',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                initialValue: activeStore['address'] ?? '',
                placeholder: Text(isId ? 'Masukkan alamat lengkap toko' : 'Enter store address'),
                maxLines: 3,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8, top: 12),
                  child: Icon(TablerIcons.map_pin, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0);
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isId ? 'Ubah Logo Toko' : 'Change Store Logo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(TablerIcons.photo, color: Warna.black, size: 20),
              ),
              title: Text(
                isId ? 'Pilih dari Galeri' : 'Pick from Gallery',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(TablerIcons.camera, color: Warna.black, size: 20),
              ),
              title: Text(
                isId ? 'Ambil Foto Baru' : 'Take a Photo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageFile != null || (currentLogo != null && currentLogo.isNotEmpty && !_logoRemoved)) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(TablerIcons.trash, color: Colors.red, size: 20),
                ),
                title: Text(
                  isId ? 'Hapus Logo' : 'Remove Logo',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
            const SizedBox(height: 12),
            ShadButton.outline(
              child: Text(isId ? 'Batal' : 'Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
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
      final values = _formKey.currentState!.value;
      final activeStore = ref.read(activeStoreProvider).value!;
      final supabase = Supabase.instance.client;

      String? logoUrl = activeStore['logo_url'];

      // Upload image if changed, or handle removal
      if (_logoRemoved) {
        logoUrl = null;
      } else if (_imageFile != null) {
        final fileName = 'logo_${activeStore['id']}_${DateTime.now().millisecondsSinceEpoch}.png';
        final path = 'logos/$fileName';

        await supabase.storage.from('store_assets').upload(path, _imageFile!);
        logoUrl = supabase.storage.from('store_assets').getPublicUrl(path);
      }

      final updatedData = {
        'name': values['name'],
        'phone': values['phone'],
        'address': values['address'],
        'logo_url': logoUrl,
      };

      await supabase.from('stores').update(updatedData).eq('id', activeStore['id']);
      
      // Update local state
      await ref.read(activeStoreProvider.notifier).selectStore({
        ...activeStore,
        ...updatedData,
      });

      if (mounted) {
        mySnackBar(
          context: context,
          text: Localizations.localeOf(context).languageCode == 'id'
              ? 'Informasi toko berhasil diperbarui'
              : 'Store information updated successfully',
          status: ToastStatus.success,
        );
        Navigator.of(context).pop();
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


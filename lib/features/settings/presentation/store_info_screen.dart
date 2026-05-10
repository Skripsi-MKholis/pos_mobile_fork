import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreInfoScreen extends ConsumerStatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  ConsumerState<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends ConsumerState<StoreInfoScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _isSaving = false;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final activeStore = ref.watch(activeStoreProvider).value;

    if (activeStore == null) {
      return const Scaffold(body: Center(child: Text('Toko tidak ditemukan')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Informasi Toko',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
              ),
            )
          else
            ShadButton.ghost(
              onPressed: _saveChanges,
              child: const Text('Simpan'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ShadForm(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogoPicker(activeStore['logo_url'], theme),
              const SizedBox(height: 32),
              ShadInputFormField(
                id: 'name',
                label: const Text('Nama Toko'),
                initialValue: activeStore['name'],
                placeholder: const Text('Masukkan nama toko'),
                validator: (v) => v.length < 3 ? 'Nama terlalu pendek' : null,
              ),
              const SizedBox(height: 16),
              ShadInputFormField(
                id: 'phone',
                label: const Text('Nomor Telepon'),
                initialValue: activeStore['phone'] ?? '',
                placeholder: const Text('Contoh: 08123456789'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              ShadInputFormField(
                id: 'address',
                label: const Text('Alamat Lengkap'),
                initialValue: activeStore['address'] ?? '',
                placeholder: const Text('Masukkan alamat lengkap toko'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPicker(String? currentLogo, ShadThemeData theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Warna.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Warna.primary.withOpacity(0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _imageFile != null
                ? Image.file(_imageFile!, fit: BoxFit.cover)
                : (currentLogo != null && currentLogo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: currentLogo,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(TablerIcons.building_store, size: 40),
                      )
                    : const Icon(TablerIcons.building_store, size: 40)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(TablerIcons.camera, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
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

      // Upload image if changed
      if (_imageFile != null) {
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
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Informasi toko berhasil diperbarui'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Gagal memperbarui data: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReceiptCustomizationScreen extends ConsumerStatefulWidget {
  const ReceiptCustomizationScreen({super.key});

  @override
  ConsumerState<ReceiptCustomizationScreen> createState() =>
      _ReceiptCustomizationScreenState();
}

class _ReceiptCustomizationScreenState
    extends ConsumerState<ReceiptCustomizationScreen> {
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _initialSettings = {};
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isExiting = false;

  // Controllers to avoid cursor jumping
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _headerController;
  late TextEditingController _footerController;
  late TextEditingController _websiteController;
  late TextEditingController _freeTextController;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    _websiteController.dispose();
    _freeTextController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (_initialSettings.isEmpty) return false;

    // Check text controllers
    if (_nameController.text.trim() !=
        (_initialSettings['store_name'] ?? '').trim())
      return true;
    if (_addressController.text.trim() !=
        (_initialSettings['address'] ?? '').trim())
      return true;
    if (_phoneController.text.trim() !=
        (_initialSettings['phone'] ?? '').trim())
      return true;
    if (_headerController.text.trim() !=
        (_initialSettings['header_message'] ?? '').trim())
      return true;
    if (_footerController.text.trim() !=
        (_initialSettings['footer_message'] ?? '').trim())
      return true;
    if (_websiteController.text.trim() !=
        (_initialSettings['website_url'] ?? '').trim())
      return true;
    if (_freeTextController.text != (_initialSettings['free_text'] ?? ''))
      return true;

    // Check toggles
    if ((_settings['show_logo'] ?? true) !=
        (_initialSettings['show_logo'] ?? true))
      return true;
    if ((_settings['show_address'] ?? true) !=
        (_initialSettings['show_address'] ?? true))
      return true;
    if ((_settings['show_phone'] ?? true) !=
        (_initialSettings['show_phone'] ?? true))
      return true;
    if ((_settings['show_header_message'] ?? true) !=
        (_initialSettings['show_header_message'] ?? true))
      return true;
    if ((_settings['show_footer_message'] ?? true) !=
        (_initialSettings['show_footer_message'] ?? true))
      return true;
    if ((_settings['show_cashier'] ?? true) !=
        (_initialSettings['show_cashier'] ?? true))
      return true;
    if ((_settings['show_qr_code'] ?? true) !=
        (_initialSettings['show_qr_code'] ?? true))
      return true;

    return false;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Perubahan Belum Disimpan'),
        description: const Text(
          'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin membuang semua perubahan ini?',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _initSettings() {
    if (_isInitialized) return;
    final activeStore = ref.read(activeStoreProvider).value;
    if (activeStore != null) {
      final storeSettings =
          activeStore['settings'] as Map<String, dynamic>? ?? {};
      final receipt = storeSettings['receipt'] as Map<String, dynamic>? ?? {};

      _settings = {
        'store_name': receipt['store_name'] ?? activeStore['name'] ?? '',
        'address': receipt['address'] ?? activeStore['address'] ?? '',
        'phone': receipt['phone'] ?? activeStore['phone'] ?? '',
        'header_message':
            receipt['header_message'] ?? 'Terima Kasih Telah Berbelanja',
        'footer_message': receipt['footer_message'] ?? 'Terima Kasih',
        'website_url': receipt['website_url'] ?? '',
        'show_logo': receipt['show_logo'] ?? true,
        'show_address': receipt['show_address'] ?? true,
        'show_phone': receipt['show_phone'] ?? true,
        'show_header_message': receipt['show_header_message'] ?? true,
        'show_footer_message': receipt['show_footer_message'] ?? true,
        'show_cashier': receipt['show_cashier'] ?? true,
        'show_qr_code': receipt['show_qr_code'] ?? true,
        'free_text': receipt['free_text'] ?? '',
      };

      _nameController = TextEditingController(text: _settings['store_name']);
      _addressController = TextEditingController(text: _settings['address']);
      _phoneController = TextEditingController(text: _settings['phone']);
      _headerController = TextEditingController(
        text: _settings['header_message'],
      );
      _footerController = TextEditingController(
        text: _settings['footer_message'],
      );
      _websiteController = TextEditingController(
        text: _settings['website_url'],
      );
      _freeTextController = TextEditingController(text: _settings['free_text']);

      _initialSettings = Map<String, dynamic>.from(_settings);
      _isInitialized = true;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // Sync local controllers back to settings map
      _settings['store_name'] = _nameController.text.trim();
      _settings['address'] = _addressController.text.trim();
      _settings['phone'] = _phoneController.text.trim();
      _settings['header_message'] = _headerController.text.trim();
      _settings['footer_message'] = _footerController.text.trim();
      _settings['website_url'] = _websiteController.text.trim();
      _settings['free_text'] = _freeTextController.text;

      await ref.read(activeStoreProvider.notifier).updateSettings({
        'receipt': _settings,
      });

      _initialSettings = Map<String, dynamic>.from(_settings);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text(
              'Pengaturan kustomisasi struk berhasil disimpan!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Gagal menyimpan pengaturan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initSettings();
    final theme = ShadTheme.of(context);
    final activeStore = ref.watch(activeStoreProvider).value;

    if (activeStore == null) {
      return const Scaffold(
        body: Center(child: Text('Toko tidak aktif ditemukan')),
      );
    }

    return PopScope(
      canPop: _isExiting || !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showUnsavedChangesDialog();
        if (shouldPop && context.mounted) {
          setState(() {
            _isExiting = true;
          });
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(TablerIcons.chevron_left),
            onPressed: () async {
              final canPop = !_hasChanges;
              if (canPop) {
                Navigator.of(context).pop();
              } else {
                final shouldPop = await _showUnsavedChangesDialog();
                if (shouldPop && context.mounted) {
                  setState(() {
                    _isExiting = true;
                  });
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: Text(
            'Kustomisasi Struk',
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ShadButton.ghost(
                  onPressed: _hasChanges ? _saveChanges : null,
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _hasChanges
                          ? theme.colorScheme.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Configurations form (Takes full width on narrow screens or half on wide ones)
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KOP STRUK & LOGO',
                      style: theme.textTheme.muted.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleRow(
                      'Tampilkan Logo Toko',
                      'Menampilkan logo avatar toko di bagian paling atas struk.',
                      _settings['show_logo'] ?? true,
                      (val) => setState(() => _settings['show_logo'] = val),
                    ),
                    const SizedBox(height: 16),
                    _buildInputRow(
                      label: 'Nama Toko di Struk',
                      controller: _nameController,
                      placeholder:
                          'Masukkan nama alternatif jika berbeda dengan nama toko',
                      onChanged: (val) =>
                          setState(() => _settings['store_name'] = val),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'INFORMASI KONTAK',
                      style: theme.textTheme.muted.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleRow(
                      'Tampilkan Alamat Toko',
                      'Menyertakan teks alamat toko pada bagian atas struk.',
                      _settings['show_address'] ?? true,
                      (val) => setState(() => _settings['show_address'] = val),
                    ),
                    if (_settings['show_address'] ?? true) ...[
                      const SizedBox(height: 12),
                      _buildInputRow(
                        label: 'Alamat Kustom',
                        controller: _addressController,
                        placeholder: 'Masukkan alamat toko',
                        maxLines: 2,
                        onChanged: (val) =>
                            setState(() => _settings['address'] = val),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildToggleRow(
                      'Tampilkan No. Telepon',
                      'Menyertakan nomor kontak toko pada bagian atas struk.',
                      _settings['show_phone'] ?? true,
                      (val) => setState(() => _settings['show_phone'] = val),
                    ),
                    if (_settings['show_phone'] ?? true) ...[
                      const SizedBox(height: 12),
                      _buildInputRow(
                        label: 'No. Telepon Kustom',
                        controller: _phoneController,
                        placeholder: 'Masukkan no telepon toko',
                        keyboardType: TextInputType.phone,
                        onChanged: (val) =>
                            setState(() => _settings['phone'] = val),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'PESAN TAMBAHAN (GREETINGS)',
                      style: theme.textTheme.muted.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleRow(
                      'Tampilkan Salam Pembuka (Header Message)',
                      'Menyertakan ucapan selamat datang di bagian atas struk.',
                      _settings['show_header_message'] ?? true,
                      (val) => setState(
                        () => _settings['show_header_message'] = val,
                      ),
                    ),
                    if (_settings['show_header_message'] ?? true) ...[
                      const SizedBox(height: 12),
                      _buildInputRow(
                        label: 'Pesan Salam Pembuka',
                        controller: _headerController,
                        placeholder: 'Contoh: Terima Kasih Telah Berbelanja',
                        onChanged: (val) =>
                            setState(() => _settings['header_message'] = val),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildToggleRow(
                      'Tampilkan Catatan Kaki (Footer Message)',
                      'Menyertakan pesan penutup di bagian paling bawah struk.',
                      _settings['show_footer_message'] ?? true,
                      (val) => setState(
                        () => _settings['show_footer_message'] = val,
                      ),
                    ),
                    if (_settings['show_footer_message'] ?? true) ...[
                      const SizedBox(height: 12),
                      _buildInputRow(
                        label: 'Pesan Catatan Kaki',
                        controller: _footerController,
                        placeholder:
                            'Contoh: Barang yang sudah dibeli tidak dapat ditukar',
                        onChanged: (val) =>
                            setState(() => _settings['footer_message'] = val),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildInputRow(
                      label: 'Website / Sosial Media Toko',
                      controller: _websiteController,
                      placeholder:
                          'Contoh: instagram.com/tokosaya atau www.tokosaya.com',
                      onChanged: (val) =>
                          setState(() => _settings['website_url'] = val),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'AREA BEBAS & QR CODE',
                      style: theme.textTheme.muted.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFreeAreaEditor(),
                    const SizedBox(height: 16),
                    _buildToggleRow(
                      'Tampilkan QR Code Struk Online',
                      'Menyertakan QR Code agar pelanggan bisa melihat struk digital online.',
                      _settings['show_qr_code'] ?? true,
                      (val) => setState(() => _settings['show_qr_code'] = val),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'LAINNYA',
                      style: theme.textTheme.muted.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleRow(
                      'Tampilkan Nama Kasir',
                      'Menyertakan nama staf/kasir yang melayani transaksi.',
                      _settings['show_cashier'] ?? true,
                      (val) => setState(() => _settings['show_cashier'] = val),
                    ),
                    const SizedBox(height: 16),
                    _buildLockedToggleRow(
                      'Tampilkan Watermark Parzello POS',
                      'Menghilangkan tulisan "Powered by Parzello POS" di bagian bawah struk.',
                      true,
                    ),
                    const SizedBox(height: 40),
                    // Render receipt preview stacked for smaller devices
                    if (MediaQuery.of(context).size.width < 800) ...[
                      const Divider(),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'PRATINJAU REAL-TIME',
                          style: theme.textTheme.muted.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(child: _buildReceiptPreview(activeStore)),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
            // Right side: Gorgeous live paper receipt preview (only for wider devices)
            if (MediaQuery.of(context).size.width >= 800)
              Expanded(
                flex: 2,
                child: Container(
                  color: const Color(0xFFF9FAFB),
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PRATINJAU STRUK REAL-TIME',
                          style: theme.textTheme.muted.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildReceiptPreview(activeStore),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedToggleRow(String title, String description, bool val) {
    final theme = ShadTheme.of(context);
    return InkWell(
      onTap: () {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Row(
              children: [
                Icon(TablerIcons.crown, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Fitur Premium / Pro'),
              ],
            ),
            description: Text(
              'Menghilangkan watermark Parzello POS memerlukan langganan Premium. Fitur berlangganan akan segera hadir!',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TablerIcons.lock,
                              size: 10,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.muted.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AbsorbPointer(
              child: ShadSwitch(value: val, onChanged: (_) {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String description,
    bool val,
    ValueChanged<bool> onChanged,
  ) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.muted.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ShadSwitch(value: val, onChanged: onChanged),
      ],
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        ShadInput(
          controller: controller,
          placeholder: Text(placeholder),
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFreeAreaEditor() {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            'Area Bebas / Catatan Tambahan (Free Section)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Text(
          'Tulis info apa pun (promosi, password Wi-Fi, jam buka, dll). Teks ini akan muncul sebelum QR Code.',
          style: theme.textTheme.muted.copyWith(fontSize: 10, height: 1.3),
        ),
        const SizedBox(height: 8),

        // Formatting & Preset Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolbarButton(
                  icon: TablerIcons.separator_horizontal,
                  label: 'Pembatas',
                  onTap: () =>
                      _insertTextAtCursor('--------------------------------\n'),
                ),
                const SizedBox(width: 6),
                _buildToolbarButton(
                  icon: TablerIcons.bold,
                  label: 'Tebal',
                  onTap: () => _insertTextAtCursor('**TEKS TEBAL**'),
                ),
                const SizedBox(width: 6),
                _buildToolbarButton(
                  icon: TablerIcons.discount_2,
                  label: 'Promo',
                  onTap: () => _insertTextAtCursor(
                    '🎉 PROMO KHUSUS 🎉\nDiskon 10% untuk transaksi berikutnya!\nTunjukkan struk ini.\n',
                  ),
                ),
                const SizedBox(width: 6),
                _buildToolbarButton(
                  icon: TablerIcons.wifi,
                  label: 'Wi-Fi',
                  onTap: () => _insertTextAtCursor(
                    'Wi-Fi Gratis:\nSSID: Wifi_Toko\nPass: toko1234\n',
                  ),
                ),
                const SizedBox(width: 6),
                _buildToolbarButton(
                  icon: TablerIcons.clock,
                  label: 'Jam Buka',
                  onTap: () => _insertTextAtCursor(
                    '🕒 Jam Operasional:\nSetiap Hari: 09:00 - 22:00\n',
                  ),
                ),
              ],
            ),
          ),
        ),

        // Editor Text Area
        ShadInput(
          controller: _freeTextController,
          placeholder: const Text(
            'Masukkan catatan/promosi kustom Anda di sini...',
          ),
          maxLines: null,
          minLines: 4,
          onChanged: (val) => setState(() => _settings['free_text'] = val),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _insertTextAtCursor(String text) {
    final controller = _freeTextController;
    final currentText = controller.text;
    final selection = controller.selection;

    String newText;
    int newCursorPosition;

    if (selection.isValid && selection.start >= 0) {
      newText = currentText.replaceRange(selection.start, selection.end, text);
      newCursorPosition = selection.start + text.length;
    } else {
      newText = currentText + text;
      newCursorPosition = newText.length;
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    setState(() {
      _settings['free_text'] = newText;
    });
  }

  Widget _buildReceiptPreview(Map<String, dynamic> store) {
    final showLogo = _settings['show_logo'] ?? true;
    final storeName = _settings['store_name']?.isNotEmpty == true
        ? _settings['store_name']
        : (store['name'] ?? 'PARZELLO POS');
    final showAddress = _settings['show_address'] ?? true;
    final address = _settings['address']?.isNotEmpty == true
        ? _settings['address']
        : (store['address'] ?? '');
    final showPhone = _settings['show_phone'] ?? true;
    final phone = _settings['phone']?.isNotEmpty == true
        ? _settings['phone']
        : (store['phone'] ?? '');
    final showHeaderMsg = _settings['show_header_message'] ?? true;
    final headerMsg = _settings['header_message'] ?? '';
    final showFooterMsg = _settings['show_footer_message'] ?? true;
    final footerMsg = _settings['footer_message'] ?? '';
    final showCashier = _settings['show_cashier'] ?? true;
    final websiteUrl = _settings['website_url'] ?? '';
    final logoUrl = store['logo_url'] as String? ?? '';
    final showQrCode = _settings['show_qr_code'] ?? true;
    final freeText = _settings['free_text'] ?? '';

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Decorative top visual border
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Warna.primary.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Store logo
                if (showLogo) ...[
                  Container(
                    height: 48,
                    width: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Warna.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Warna.primary.withOpacity(0.3)),
                    ),
                    child:
                        store['logo_url'] != null &&
                            (store['logo_url'] as String).isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: store['logo_url'],
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => const Icon(
                              TablerIcons.building_store,
                              size: 22,
                            ),
                          )
                        : const Icon(TablerIcons.building_store, size: 22),
                  ),
                  const SizedBox(height: 8),
                ],
                // Store Name
                Text(
                  storeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Address
                if (showAddress && address.isNotEmpty) ...[
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],

                // Phone
                if (showPhone && phone.isNotEmpty) ...[
                  Text(
                    'Telp: $phone',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                ],

                // Header Message
                if (showHeaderMsg && headerMsg.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      headerMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildDottedDivider(),
                const SizedBox(height: 8),

                // Meta Info (Date, No, Cashier)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'No. Struk: #PRZ-98B2',
                      style: TextStyle(fontSize: 9, fontFamily: 'monospace'),
                    ),
                    Text(
                      '18/05/26 16:50',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (showCashier) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kasir:', style: TextStyle(fontSize: 9)),
                      Text(
                        'Staf Parzello',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                _buildDottedDivider(),
                const SizedBox(height: 12),

                // Items Mock list
                _buildMockItem(
                  'Kopi Susu Gula Aren',
                  '2 x Rp 18.000',
                  'Rp 36.000',
                ),
                const SizedBox(height: 8),
                _buildMockItem(
                  'Roti Bakar Cokelat',
                  '1 x Rp 15.000',
                  'Rp 15.000',
                ),

                const SizedBox(height: 12),
                _buildDottedDivider(),
                const SizedBox(height: 12),

                // Totals
                _buildTotalRow('Subtotal', 'Rp 51.000', isBold: false),
                const SizedBox(height: 4),
                _buildTotalRow('Total Tagihan', 'Rp 51.000', isBold: true),
                const SizedBox(height: 4),
                _buildTotalRow('Metode Tunai', 'Rp 100.000', isBold: false),
                const SizedBox(height: 4),
                _buildTotalRow(
                  'Kembalian',
                  'Rp 49.000',
                  isBold: false,
                  color: Warna.primary,
                ),

                const SizedBox(height: 16),
                _buildDottedDivider(),
                const SizedBox(height: 16),

                // Free Text Section
                if (freeText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    freeText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDottedDivider(),
                  const SizedBox(height: 16),
                ],

                // Premium QR Code & Store info section
                if (showQrCode) ...[
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: const Icon(
                            TablerIcons.qrcode,
                            size: 48,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pindai QR untuk struk online',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Small store logo and name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Warna.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: logoUrl.isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: logoUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      TablerIcons.building_store,
                                      size: 10,
                                      color: Warna.primary,
                                    ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // Website / Sosmed URL
                        if (websiteUrl.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                TablerIcons.world,
                                size: 10,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                websiteUrl,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDottedDivider(),
                  const SizedBox(height: 16),
                ],

                // Footer Message
                if (showFooterMsg && footerMsg.isNotEmpty) ...[
                  Text(
                    footerMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const Text(
                    'Terima Kasih Telah Berbelanja',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Powered by Parzello POS',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMockItem(String name, String qtyAndPrice, String subtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              qtyAndPrice,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
            Text(
              subtotal,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    required bool isBold,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 12 : 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 12 : 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            color: color ?? (isBold ? Colors.black : Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}

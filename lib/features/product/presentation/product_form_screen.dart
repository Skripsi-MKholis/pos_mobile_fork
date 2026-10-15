import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_mobile/core/utils/image_picker_helper.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:barcode_widget/barcode_widget.dart' as bc;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _modalPriceController;
  late TextEditingController _stockController;
  File? _imageFile;
  bool _isSaving = false;
  String? _selectedCategoryId;
  bool _showBarcodeCard = false;

  final GlobalKey _previewKey = GlobalKey();
  bool _isSharingPreview = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.product?.categoryId;
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _showBarcodeCard = (_skuController.text.trim().isNotEmpty);

    final p = widget.product?.price;
    final mp = widget.product?.modalPrice;
    final sq = widget.product?.stockQuantity;

    _priceController = TextEditingController(
      text: p != null ? (p % 1 == 0 ? p.toInt().toString() : p.toString()) : '',
    );
    _modalPriceController = TextEditingController(
      text: mp != null ? (mp % 1 == 0 ? mp.toInt().toString() : mp.toString()) : '',
    );
    _stockController = TextEditingController(
      text: sq != null ? sq.toString() : '0',
    );

    _nameController.addListener(_onFieldChanged);
    _skuController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _modalPriceController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _skuController.removeListener(_onFieldChanged);
    _priceController.removeListener(_onFieldChanged);
    _modalPriceController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _modalPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _generateRandomSku() {
    final l10n = AppLocalizations.of(context)!;
    final random = Random();
    final randomNumber = random.nextInt(90000000) + 10000000;
    _skuController.text = 'SKU-$randomNumber';
    _showBarcodeCard = true;
    HapticFeedback.lightImpact();

    mySnackBar(
      context: context,
      text: l10n.randomSkuCreated,
      status: ToastStatus.success,
    );
  }

  Future<void> _sharePreviewBarcode() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSharingPreview = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/barcode_preview_${_skuController.text}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.barcodeFor(
          _nameController.text.isNotEmpty ? _nameController.text : l10n.newProduct,
          _skuController.text,
        ),
      );
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.shareFailed(e.toString()),
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingPreview = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await AppImagePicker.pickProductImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _scanBarcode() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _BarcodeScannerSheet(),
    );
    if (result != null) {
      setState(() {
        _skuController.text = result;
        _showBarcodeCard = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.product != null;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    // Calculate potential profit margin
    final sellPrice = double.tryParse(_priceController.text) ?? 0.0;
    final modalPrice = double.tryParse(_modalPriceController.text) ?? 0.0;
    final profit = sellPrice - modalPrice;
    final margin = sellPrice > 0 ? ((profit / sellPrice) * 100).clamp(-100, 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? l10n.editProduct : l10n.addProduct,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isEdit
                  ? (isId ? 'Perbarui informasi & harga produk' : 'Update product details & price')
                  : (isId ? 'Tambahkan item baru ke katalog toko' : 'Add new item to store catalog'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.chevron_left, size: 19, color: Color(0xFF334155)),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products');
            }
          },
        ),
        toolbarHeight: 70,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SECTION: FOTO & INFORMASI UTAMA
              _buildSectionCard(
                title: isId ? 'Informasi Produk' : 'Product Information',
                icon: TablerIcons.box,
                children: [
                  _buildImagePickerRow(l10n),
                  const SizedBox(height: 16),
                  _buildFieldLabel(l10n.productName, isRequired: true),
                  _buildInput(
                    controller: _nameController,
                    placeholder: l10n.enterProductName,
                    icon: TablerIcons.tag,
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel(l10n.category),
                  categoriesAsync.when(
                    data: (categories) => ShadSelect<String>(
                      placeholder: Text(
                        l10n.selectCategory,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),
                      initialValue: _selectedCategoryId,
                      options: [
                        ShadOption(
                          value: 'none',
                          child: Text(l10n.noCategory, style: const TextStyle(fontSize: 13)),
                        ),
                        ...categories.map(
                          (c) => ShadOption(
                            value: c.supabaseId,
                            child: Text(c.name, style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => _selectedCategoryId = value == 'none' ? null : value,
                      ),
                      selectedOptionBuilder: (context, value) => Text(
                        value == 'none'
                            ? l10n.noCategory
                            : categories
                                .firstWhere(
                                  (c) => c.supabaseId == value,
                                  orElse: () => Category()..name = l10n.noCategory,
                                )
                                .name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    loading: () => ShadSelect<String>(
                      placeholder: Text(l10n.loadingCategories, style: const TextStyle(fontSize: 13)),
                      options: const [],
                      selectedOptionBuilder: null,
                    ),
                    error: (err, _) => ShadSelect<String>(
                      placeholder: Text(l10n.errorCategories(err.toString()), style: const TextStyle(fontSize: 13)),
                      options: const [],
                      selectedOptionBuilder: null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. SECTION: HARGA & ESTIMASI MARGIN
              _buildSectionCard(
                title: isId ? 'Harga & Biaya' : 'Pricing & Cost',
                icon: TablerIcons.currency_dollar,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modal Price (Harga Pokok)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(l10n.costPrice),
                            _buildInput(
                              controller: _modalPriceController,
                              keyboardType: TextInputType.number,
                              placeholder: '0',
                              prefixText: 'Rp ',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Selling Price (Harga Jual)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(l10n.sellingPrice, isRequired: true),
                            _buildInput(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              placeholder: '0',
                              prefixText: 'Rp ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (sellPrice > 0 && modalPrice > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: profit >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: profit >= 0 ? const Color(0xFFBBF7D0) : const Color(0xFFFECDD3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            profit >= 0 ? TablerIcons.trending_up : TablerIcons.trending_down,
                            size: 16,
                            color: profit >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${isId ? "Estimasi Laba/unit" : "Estimated Profit"}: Rp ${profit.toStringAsFixed(0)} (${margin.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: profit >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              // 3. SECTION: STOK & INVENTARIS
              _buildSectionCard(
                title: isId ? 'Stok Produk' : 'Stock Inventory',
                icon: TablerIcons.packages,
                children: [
                  _buildFieldLabel(l10n.initialStock),
                  _buildInput(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    placeholder: '0',
                    suffixText: 'pcs',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 4. SECTION: SKU & BARCODE
              _buildSectionCard(
                title: isId ? 'SKU & Barcode' : 'SKU & Barcode',
                icon: TablerIcons.barcode,
                children: [
                  _buildFieldLabel(l10n.skuBarcode),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          controller: _skuController,
                          placeholder: l10n.scanOrTypeSku,
                          icon: TablerIcons.qrcode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: l10n.generateRandomSku,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _generateRandomSku,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(TablerIcons.refresh, size: 18, color: Color(0xFF334155)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: l10n.scanBarcodeCamera,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _scanBarcode,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(TablerIcons.camera, size: 18, color: Color(0xFF334155)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_skuController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(() => _showBarcodeCard = !_showBarcodeCard),
                      child: Row(
                        children: [
                          Icon(
                            _showBarcodeCard ? TablerIcons.chevron_down : TablerIcons.chevron_right,
                            size: 15,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showBarcodeCard
                                ? (isId ? 'Sembunyikan Preview Barcode' : 'Hide Barcode Preview')
                                : (isId ? 'Tampilkan Preview Barcode' : 'Show Barcode Preview'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showBarcodeCard) ...[
                      const SizedBox(height: 10),
                      RepaintBoundary(
                        key: _previewKey,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text.toUpperCase()
                                    : l10n.newProduct.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 55,
                                child: bc.BarcodeWidget(
                                  barcode: bc.Barcode.code128(),
                                  data: _skuController.text,
                                  color: Colors.black,
                                  drawText: false,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _skuController.text,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _isSharingPreview ? null : _sharePreviewBarcode,
                                    child: Row(
                                      children: [
                                        if (_isSharingPreview)
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF0F172A),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        else
                                          const Icon(TablerIcons.share, size: 15, color: Color(0xFF0F172A)),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.share,
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // SAVE BUTTON (Minimalist & Solid)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Warna.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          isEdit ? (isId ? 'Simpan Perubahan' : 'Save Changes') : l10n.saveProduct,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: Color(0xFF334155),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? prefixText,
    String? suffixText,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: icon != null
              ? Icon(icon, size: 16, color: const Color(0xFF94A3B8))
              : null,
          prefixIconConstraints: icon != null
              ? const BoxConstraints(minWidth: 36, minHeight: 42)
              : null,
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon != null ? 8 : 12,
            vertical: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerRow(AppLocalizations l10n) {
    return Row(
      children: [
        // Image square preview
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : widget.product?.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(widget.product!.imageUrl!, fit: BoxFit.cover),
                      )
                    : const Icon(TablerIcons.camera_plus, size: 26, color: Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(width: 14),

        // Help text and change action
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _imageFile != null || widget.product?.imageUrl != null
                    ? 'Foto Produk Terpasang'
                    : l10n.tapToAddPhoto,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Maksimal 2MB, format JPG atau PNG.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _imageFile != null || widget.product?.imageUrl != null
                        ? 'Ganti Foto'
                        : 'Pilih dari Galeri',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      mySnackBar(
        context: context,
        text: l10n.productNameRequired,
        status: ToastStatus.error,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final product = Product(
        id: widget.product?.id ?? 0,
        supabaseId: widget.product?.supabaseId ?? '',
        storeId: widget.product?.storeId ?? '',
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        modalPrice: double.tryParse(_modalPriceController.text),
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        sku: _skuController.text.trim(),
        categoryId: _selectedCategoryId,
        imageUrl: widget.product?.imageUrl,
      );

      await ref.read(productNotifierProvider.notifier).saveProduct(product, imageFile: _imageFile);

      try {
        if (widget.product == null) {
          final categories = ref.read(categoryNotifierProvider).value;
          final categoryName = _selectedCategoryId == null
              ? l10n.noCategory
              : categories?.firstWhere(
                  (c) => c.supabaseId == _selectedCategoryId,
                  orElse: () => Category()..name = l10n.noCategory,
                ).name ?? l10n.noCategory;

          await AnalyticsService.instance.logProductCreation(
            categoryName: categoryName,
            price: product.price,
            hasImage: _imageFile != null,
          );
        } else {
          final oldPrice = widget.product!.price;
          final oldStock = widget.product!.stockQuantity;
          await AnalyticsService.instance.logProductUpdate(
            priceChanged: oldPrice != product.price,
            stockChanged: oldStock != product.stockQuantity,
          );
        }
      } catch (_) {}

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.productSaveFailed(e.toString()),
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return Container(
      height: 460,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isId ? 'Pindai Barcode Produk' : 'Scan Product Barcode',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flash / Torch Toggle
                    IconButton(
                      tooltip: _isTorchOn ? 'Matikan Senter' : 'Nyalakan Senter',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isTorchOn ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isTorchOn ? TablerIcons.bolt : TablerIcons.bolt_off,
                          size: 18,
                          color: _isTorchOn ? const Color(0xFFD97706) : const Color(0xFF334155),
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await _controller.toggleTorch();
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                    ),
                    const SizedBox(width: 4),

                    // Switch Camera (Front / Back)
                    IconButton(
                      tooltip: isId ? 'Ganti Kamera Depan/Belakang' : 'Switch Camera',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          TablerIcons.switch_horizontal,
                          size: 18,
                          color: Color(0xFF334155),
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await _controller.switchCamera();
                        setState(() {
                          _isTorchOn = false;
                        });
                      },
                    ),
                    const SizedBox(width: 4),

                    // Close modal
                    IconButton(
                      tooltip: 'Tutup',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(TablerIcons.x, size: 18, color: Color(0xFF334155)),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, barcodes.first.rawValue);
                      }
                    },
                  ),
                  // Center scan reticle overlay
                  Center(
                    child: Container(
                      width: 240,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              isId ? 'Arahkan barcode ke dalam bingkai' : 'Align barcode within the frame',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

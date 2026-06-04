import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.product?.categoryId;
    _nameController = TextEditingController(text: widget.product?.name);
    _skuController = TextEditingController(text: widget.product?.sku);
    _nameController.addListener(_onSkuChanged);
    _skuController.addListener(_onSkuChanged);
    _priceController = TextEditingController(text: widget.product?.price.toString());
    _modalPriceController = TextEditingController(text: widget.product?.modalPrice?.toString());
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString());
  }

  void _onSkuChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onSkuChanged);
    _skuController.removeListener(_onSkuChanged);
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
    final randomNumber = random.nextInt(90000000) + 10000000; // 8-digit random number
    _skuController.text = 'SKU-$randomNumber';
    HapticFeedback.lightImpact();
    
    mySnackBar(
      context: context,
      text: l10n.randomSkuCreated,
      status: ToastStatus.success,
    );
  }

  final GlobalKey _previewKey = GlobalKey();
  bool _isSharingPreview = false;

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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _scanBarcode() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SizedBox(
        height: 400,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) Navigator.pop(context, barcodes.first.rawValue);
          },
        ),
      ),
    );
    if (result != null) setState(() => _skuController.text = result);
  }

  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? l10n.addProduct : l10n.editProduct, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildFieldLabel(l10n.productName),
              ShadInput(
                controller: _nameController,
                placeholder: Text(l10n.enterProductName),
              ),
              const SizedBox(height: 20),
              _buildFieldLabel(l10n.category),
              categoriesAsync.when(
                data: (categories) => ShadSelect<String>(
                  placeholder: Text(l10n.selectCategory),
                  initialValue: _selectedCategoryId,
                  options: [
                    ShadOption(
                      value: 'none',
                      child: Text(l10n.noCategory),
                    ),
                    ...categories.map(
                      (c) => ShadOption(
                        value: c.supabaseId,
                        child: Text(c.name),
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
                  ),
                ),
                loading: () => ShadSelect<String>(
                  placeholder: Text(l10n.loadingCategories),
                  options: const [],
                  selectedOptionBuilder: null,
                ),
                error: (err, _) => ShadSelect<String>(
                  placeholder: Text(l10n.errorCategories(err.toString())),
                  options: const [],
                  selectedOptionBuilder: null,
                ),
              ),
              const SizedBox(height: 20),
              _buildFieldLabel(l10n.skuBarcode),
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _skuController,
                      placeholder: Text(l10n.scanOrTypeSku),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.generateRandomSku,
                    child: ShadButton.outline(
                      onPressed: _generateRandomSku,
                      child: const Icon(TablerIcons.refresh, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.scanBarcodeCamera,
                    child: ShadButton.outline(
                      onPressed: _scanBarcode,
                      child: const Icon(TablerIcons.barcode, size: 20),
                    ),
                  ),
                ],
              ),
              if (_skuController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFieldLabel(l10n.barcodePreview),
                RepaintBoundary(
                  key: _previewKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _nameController.text.isNotEmpty 
                              ? _nameController.text.toUpperCase() 
                              : l10n.newProduct.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 70,
                          child: bc.BarcodeWidget(
                            barcode: bc.Barcode.code128(),
                            data: _skuController.text,
                            color: Colors.black,
                            drawText: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _skuController.text,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                                        color: Colors.blue,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(TablerIcons.share, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.share,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(l10n.costPrice),
                        ShadInput(
                          controller: _modalPriceController,
                          keyboardType: TextInputType.number,
                          placeholder: const Text('0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(l10n.sellingPrice),
                        ShadInput(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          placeholder: const Text('0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFieldLabel(l10n.initialStock),
              ShadInput(
                controller: _stockController,
                keyboardType: TextInputType.number,
                placeholder: const Text('0'),
              ),
              const SizedBox(height: 40),
              ShadButton(
                size: ShadButtonSize.lg,
                onPressed: _isSaving ? null : _saveProduct,
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(l10n.saveProduct),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildImagePicker() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: _imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
            : widget.product?.imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.product!.imageUrl!, fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TablerIcons.photo_plus, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(l10n.tapToAddPhoto, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.isEmpty) {
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
        storeId: widget.product?.storeId ?? '', // Akan dihandle di notifier
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        modalPrice: double.tryParse(_modalPriceController.text),
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        sku: _skuController.text,
        categoryId: _selectedCategoryId,
        imageUrl: widget.product?.imageUrl,
      );

      await ref.read(productNotifierProvider.notifier).saveProduct(product, imageFile: _imageFile);

      // Log to Firebase Analytics
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
      if (mounted) mySnackBar(
        context: context,
        text: l10n.productSaveFailed(e.toString()),
        status: ToastStatus.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

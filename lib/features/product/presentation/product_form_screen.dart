import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _skuController = TextEditingController(text: widget.product?.sku);
    _priceController = TextEditingController(text: widget.product?.price.toString());
    _modalPriceController = TextEditingController(text: widget.product?.modalPrice?.toString());
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk', style: const TextStyle(fontWeight: FontWeight.bold))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildFieldLabel('Nama Produk'),
              ShadInput(
                controller: _nameController,
                placeholder: const Text('Masukkan nama produk...'),
              ),
              const SizedBox(height: 20),
              _buildFieldLabel('SKU / Barcode'),
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _skuController,
                      placeholder: const Text('Scan atau ketik SKU...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadButton.outline(
                    leading: const Icon(TablerIcons.barcode),
                    onPressed: _scanBarcode,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Harga Modal'),
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
                        _buildFieldLabel('Harga Jual'),
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
              _buildFieldLabel('Stok Awal'),
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
                  : const Text('Simpan Produk'),
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
                      const Text('Ketuk untuk tambah foto', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty) {
      ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Nama produk wajib diisi')));
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
        imageUrl: widget.product?.imageUrl,
      );

      await ref.read(productNotifierProvider.notifier).saveProduct(product, imageFile: _imageFile);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

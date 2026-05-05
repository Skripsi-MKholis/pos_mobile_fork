import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_mobile/core/widgets/barcode_scanner_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _modalPriceController;
  late TextEditingController _stockController;
  late TextEditingController _barcodeController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '0');
    _modalPriceController = TextEditingController(text: widget.product?.modalPrice?.toString() ?? '0');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '0');
    _barcodeController = TextEditingController(text: widget.product?.barcode);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _scanBarcode() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (mounted) {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
        );
        if (result != null) {
          setState(() {
            _barcodeController.text = result;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newProduct = Product()
        ..name = _nameController.text
        ..price = double.parse(_priceController.text)
        ..modalPrice = double.parse(_modalPriceController.text)
        ..stockQuantity = int.parse(_stockController.text)
        ..barcode = _barcodeController.text;

      await ref.read(productNotifierProvider.notifier).addProduct(
        newProduct,
        imageFile: _imageFile,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextField('Product Name', _nameController, TablerIcons.package),
              const SizedBox(height: 16),
              _buildTextField('Selling Price', _priceController, TablerIcons.coin, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Cost Price (Modal)', _modalPriceController, TablerIcons.cash, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Stock Quantity', _stockController, TablerIcons.stack_2, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildBarcodeField(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Save Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Warna.neutral,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Warna.line, width: 2),
          image: _imageFile != null 
            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
            : widget.product?.imageUrl != null 
              ? DecorationImage(image: NetworkImage(widget.product!.imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: _imageFile == null && (widget.product?.imageUrl == null)
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(TablerIcons.photo_plus, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Add Product Photo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            )
          : Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(TablerIcons.pencil, color: Colors.white, size: 20),
              ),
            ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildBarcodeField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _barcodeController,
            decoration: const InputDecoration(
              labelText: 'Barcode / SKU',
              prefixIcon: Icon(TablerIcons.barcode),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _scanBarcode,
          style: IconButton.styleFrom(backgroundColor: Warna.primary),
          icon: const Icon(TablerIcons.scan, color: Colors.black),
        ),
      ],
    );
  }
}

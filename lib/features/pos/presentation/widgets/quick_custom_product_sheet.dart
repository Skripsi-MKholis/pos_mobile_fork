import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

class QuickCustomProductSheet extends StatefulWidget {
  final CartNotifier cartNotifier;
  final String storeId;

  const QuickCustomProductSheet({
    super.key,
    required this.cartNotifier,
    required this.storeId,
  });

  static Future<void> show({
    required BuildContext context,
    required CartNotifier cartNotifier,
    required String storeId,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickCustomProductSheet(
        cartNotifier: cartNotifier,
        storeId: storeId,
      ),
    );
  }

  @override
  State<QuickCustomProductSheet> createState() => _QuickCustomProductSheetState();
}

class _QuickCustomProductSheetState extends State<QuickCustomProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  int _quantity = 1;

  final List<String> _quickPresets = const [
    'Menu Khusus',
    'Extra Topping',
    'Biaya Kemasan',
    'Ongkir Titip',
    'Jasa',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final rawPrice = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = double.tryParse(rawPrice) ?? 0.0;

    if (name.isEmpty) {
      mySnackBar(
        context: context,
        text: 'Nama item tidak boleh kosong',
        status: ToastStatus.error,
      );
      return;
    }

    if (price <= 0) {
      mySnackBar(
        context: context,
        text: 'Masukkan harga yang valid',
        status: ToastStatus.error,
      );
      return;
    }

    // Gunakan UUID v4 agar supabaseId selalu valid dan kompatibel dengan DB
    final customId = const Uuid().v4();

    final customProduct = Product(
      supabaseId: customId,
      storeId: widget.storeId,
      name: name,
      price: price,
      stockQuantity: 9999, // Bypass stock check
      isSynced: true, // Jangan sinkronkan ke master tabel products cloud
    );

    // Masukkan ke keranjang dengan jumlah yang dipilih
    for (int i = 0; i < _quantity; i++) {
      widget.cartNotifier.addItem(customProduct);
    }

    HapticFeedback.lightImpact();
    Navigator.of(context).pop();

    final l10n = AppLocalizations.of(context);
    mySnackBar(
      context: context,
      text: l10n?.customProductAdded(name) ?? '$name ditambahkan ke keranjang',
      status: ToastStatus.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Warna.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      TablerIcons.plus,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.addCustomProduct,
                          style: theme.textTheme.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          l10n.customProductDesc,
                          style: TextStyle(
                            color: theme.colorScheme.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(TablerIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chip Presets Cepat
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickPresets.map((preset) {
                    final isCurrent = _nameController.text == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.black : Colors.black87,
                          ),
                        ),
                        backgroundColor: isCurrent ? Warna.primary : Colors.grey.shade100,
                        side: BorderSide(
                          color: isCurrent ? Warna.primary : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () {
                          setState(() {
                            _nameController.text = preset;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Field Nama Produk
              Text(
                l10n.customProductName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ShadInput(
                controller: _nameController,
                placeholder: Text(l10n.customProductNameHint),
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Field Harga
              Text(
                l10n.customProductPrice,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ShadInput(
                controller: _priceController,
                placeholder: Text(l10n.customProductPriceHint),
                keyboardType: TextInputType.number,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 6),
                  child: Text(
                    'Rp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Counter Jumlah (Quantity)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.customProductQty,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(TablerIcons.minus, size: 16),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(TablerIcons.plus, size: 16),
                          onPressed: () => setState(() => _quantity++),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol Tambah ke Keranjang
              ShadButton(
                size: ShadButtonSize.lg,
                onPressed: _submit,
                leading: const Icon(TablerIcons.plus, size: 18),
                child: Text(l10n.addToCart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

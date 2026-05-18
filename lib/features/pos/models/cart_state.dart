import 'package:pos_mobile/core/models/table.dart';
import 'package:pos_mobile/core/models/voucher.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';

class CartState {
  final List<CartItem> items;
  final TableModel? selectedTable;
  final Voucher? appliedVoucher;
  final String? activeTransactionId;

  CartState({
    this.items = const [],
    this.selectedTable,
    this.appliedVoucher,
    this.activeTransactionId,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    if (appliedVoucher == null) return 0;
    return appliedVoucher!.calculateDiscount(subtotal);
  }

  double get totalAmount => subtotal - discountAmount;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    TableModel? selectedTable,
    Voucher? appliedVoucher,
    String? activeTransactionId,
    bool clearTable = false,
    bool clearVoucher = false,
    bool clearTransactionId = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedTable: clearTable ? null : (selectedTable ?? this.selectedTable),
      appliedVoucher: clearVoucher ? null : (appliedVoucher ?? this.appliedVoucher),
      activeTransactionId: clearTransactionId ? null : (activeTransactionId ?? this.activeTransactionId),
    );
  }
}

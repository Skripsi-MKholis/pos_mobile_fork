import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/table.dart';
import 'package:pos_mobile/core/models/voucher.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/features/pos/models/cart_state.dart';

part 'cart_provider.g.dart';

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  CartState build() {
    return CartState();
  }

  void addItem(Product product) {
    final items = state.items;
    final existingIndex = items.indexWhere((item) => item.product.supabaseId == product.supabaseId);
    
    if (existingIndex != -1) {
      final updatedList = [...items];
      updatedList[existingIndex] = updatedList[existingIndex].copyWith(
        quantity: updatedList[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: updatedList);
    } else {
      state = state.copyWith(items: [...items, CartItem(product: product)]);
    }
  }

  void removeFromCart(String supabaseId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.supabaseId != supabaseId).toList(),
    );
  }

  void updateQuantity(String supabaseId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(supabaseId);
      return;
    }
    
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.supabaseId == supabaseId)
            item.copyWith(quantity: quantity)
          else
            item
      ],
    );
  }

  void selectTable(TableModel? table) {
    state = state.copyWith(selectedTable: table, clearTable: table == null);
  }

  void applyVoucher(Voucher voucher) {
    state = state.copyWith(appliedVoucher: voucher);
  }

  void removeVoucher() {
    state = state.copyWith(clearVoucher: true);
  }

  void setItems(List<CartItem> items) {
    state = state.copyWith(items: items);
  }

  void clearCart() {
    state = CartState();
  }

  double get subtotal => state.subtotal;
  double get discountAmount => state.discountAmount;
  double get totalAmount => state.totalAmount;
  int get totalItems => state.totalItems;
}

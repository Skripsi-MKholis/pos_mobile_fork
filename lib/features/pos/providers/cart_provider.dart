import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';

part 'cart_provider.g.dart';

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  List<CartItem> build() {
    return [];
  }

  void addToCart(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.supabaseId == product.supabaseId);
    
    if (existingIndex != -1) {
      final updatedList = [...state];
      updatedList[existingIndex] = updatedList[existingIndex].copyWith(
        quantity: updatedList[existingIndex].quantity + 1,
      );
      state = updatedList;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(String supabaseId) {
    state = state.where((item) => item.product.supabaseId != supabaseId).toList();
  }

  void updateQuantity(String supabaseId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(supabaseId);
      return;
    }
    
    state = [
      for (final item in state)
        if (item.product.supabaseId == supabaseId)
          item.copyWith(quantity: quantity)
        else
          item
    ];
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.subtotal);
  }

  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

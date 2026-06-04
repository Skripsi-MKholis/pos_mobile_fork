import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/features/customer/models/customer_cart_item.dart';

final customerCartProvider =
    StateNotifierProvider<CustomerCartNotifier, List<CustomerCartItem>>(
  (ref) => CustomerCartNotifier(),
);

class CustomerCartNotifier extends StateNotifier<List<CustomerCartItem>> {
  CustomerCartNotifier() : super(const []);

  void addItem(CustomerCartItem item) {
    final existingIndex = state.indexWhere((entry) => entry.id == item.id);
    if (existingIndex == -1) {
      state = [...state, item];
      return;
    }

    final updated = [...state];
    final existing = updated[existingIndex];
    updated[existingIndex] = existing.copyWith(quantity: existing.quantity + item.quantity);
    state = updated;
  }

  void increment(String id) {
    final updated = [
      for (final item in state)
        if (item.id == id) item.copyWith(quantity: item.quantity + 1) else item,
    ];
    state = updated;
  }

  void decrement(String id) {
    final updated = <CustomerCartItem>[];
    for (final item in state) {
      if (item.id != id) {
        updated.add(item);
        continue;
      }
      if (item.quantity > 1) {
        updated.add(item.copyWith(quantity: item.quantity - 1));
      }
    }
    state = updated;
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
  }

  void clear() {
    state = const [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.lineTotal);
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
}

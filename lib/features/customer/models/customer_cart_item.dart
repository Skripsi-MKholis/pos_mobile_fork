class CustomerCartItem {
  const CustomerCartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.badge,
    this.iconCodePoint,
  });

  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? badge;
  final int? iconCodePoint;

  CustomerCartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? badge,
    int? iconCodePoint,
  }) {
    return CustomerCartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      badge: badge ?? this.badge,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  double get lineTotal => price * quantity;
}

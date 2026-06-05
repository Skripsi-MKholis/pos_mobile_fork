import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';

class CustomerCatalogProduct {
  const CustomerCatalogProduct({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.stockQuantity = 0,
    this.imageUrl,
    this.category = 'Umum',
    this.categoryId,
  });

  final String id;
  final String name;
  final double price;
  final String? description;
  final int stockQuantity;
  final String? imageUrl;
  final String category;
  final String? categoryId;

  bool get isOutOfStock => stockQuantity <= 0;

  factory CustomerCatalogProduct.fromMap(Map<String, dynamic> map) {
    return CustomerCatalogProduct(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Tanpa Nama',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      description: map['description']?.toString(),
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url']?.toString(),
      category: map['category']?.toString() ?? 'Umum',
      categoryId: map['category_id']?.toString(),
    );
  }
}

final customerCatalogProvider =
    FutureProvider.autoDispose.family<List<CustomerCatalogProduct>, String?>(
  (ref, storeId) async {
    if (storeId == null || storeId.isEmpty) return const [];

    final supabase = Supabase.instance.client;
    final response = await supabase.retryWithFreshSession(() => supabase
        .from('products')
        .select('id, name, description, price, stock_quantity, image_url, category, category_id')
        .eq('store_id', storeId)
        .order('name'));

    final rows = response as List<dynamic>;
    return rows
        .whereType<Map>()
        .map((row) => CustomerCatalogProduct.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  },
);

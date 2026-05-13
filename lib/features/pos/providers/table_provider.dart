import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/models/table.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

part 'table_provider.g.dart';

@riverpod
class TableNotifier extends _$TableNotifier {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<TableModel>> build() async {
    // Wait for the active store to be loaded first
    final activeStore = await ref.watch(activeStoreProvider.future);
    final storeId = activeStore?['id'];

    if (storeId == null) return [];

    try {
      final response = await _supabase
          .from('tables')
          .select()
          .eq('store_id', storeId)
          .order('name')
          .timeout(const Duration(seconds: 10));
          
      return (response as List).map((data) => TableModel.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching tables: $e');
      return [];
    }
  }

  Future<void> addTable(String name, int capacity) async {
    final activeStore = await ref.read(activeStoreProvider.future);
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    try {
      await _supabase.from('tables').insert({
        'store_id': storeId,
        'name': name,
        'capacity': capacity,
        'status': 'available',
      });
      ref.invalidateSelf();
    } catch (e) {
      print('Error adding table: $e');
      rethrow;
    }
  }

  Future<void> updateTable(TableModel table) async {
    try {
      await _supabase
          .from('tables')
          .update(table.toMap())
          .eq('id', table.id);
      ref.invalidateSelf();
    } catch (e) {
      print('Error updating table: $e');
      rethrow;
    }
  }

  Future<void> deleteTable(String id) async {
    try {
      await _supabase.from('tables').delete().eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      print('Error deleting table: $e');
      rethrow;
    }
  }
}

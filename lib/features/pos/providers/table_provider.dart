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
      return []; // Return empty list instead of throwing to avoid stuck loading UI
    }
  }
}

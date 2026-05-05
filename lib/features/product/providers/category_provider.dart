import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:isar/isar.dart';

part 'category_provider.g.dart';

@riverpod
class CategoryNotifier extends _$CategoryNotifier {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;

  @override
  Future<List<Category>> build() async {
    _listenToRealtimeChanges();
    // Trigger background sync
    Future.microtask(() => syncCategories());
    return _fetchLocalCategories();
  }

  void _listenToRealtimeChanges() {
    _supabase
        .channel('public:categories')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categories',
          callback: (payload) async {
            await syncCategories();
          },
        )
        .subscribe();
  }

  Future<List<Category>> _fetchLocalCategories() async {
    return _isar.collection<Category>().where().findAll();
  }

  Future<void> syncCategories() async {
    try {
      final response = await _supabase.from('categories').select();
      
      final categories = (response as List).map((data) => Category()
        ..supabaseId = data['id'].toString()
        ..storeId = data['store_id'].toString()
        ..name = data['name']
        ..description = data['description']
        ..updatedAt = data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null
      ).toList();

      await _isar.writeTxn(() async {
        for (var category in categories) {
          await _isar.collection<Category>().putBySupabaseId(category);
        }
      });

      state = AsyncData(await _fetchLocalCategories());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addCategory({required String name, String? description}) async {
    final activeStore = ref.read(activeStoreProvider).value;
    if (activeStore == null) return;

    try {
      await _supabase.from('categories').insert({
        'store_id': activeStore['id'],
        'name': name,
        'description': description,
      });
      // Realtime listener will trigger sync
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory({
    required String supabaseId,
    required String name,
    String? description,
  }) async {
    try {
      await _supabase.from('categories').update({
        'name': name,
        'description': description,
      }).eq('id', supabaseId);
      // Realtime listener will trigger sync
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String supabaseId) async {
    try {
      await _supabase.from('categories').delete().eq('id', supabaseId);
      
      // Also delete from local Isar
      final localCategory = await _isar.collection<Category>().filter().supabaseIdEqualTo(supabaseId).findFirst();
      if (localCategory != null) {
        await _isar.writeTxn(() => _isar.collection<Category>().delete(localCategory.id));
      }
      
      state = AsyncData(await _fetchLocalCategories());
    } catch (e) {
      rethrow;
    }
  }
}

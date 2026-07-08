import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';

part 'category_provider.g.dart';

@riverpod
class CategoryNotifier extends _$CategoryNotifier {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Category>> build() async {
    final activeStoreAsync = ref.watch(activeStoreProvider);
    final activeStore = activeStoreAsync.value;
    final storeId = activeStore?['id'];

    if (storeId == null) return [];

    final channel = _listenToRealtimeChanges(storeId);
    ref.onDispose(() {
      _supabase.removeChannel(channel);
    });

    // Watch connectivity to trigger sync when online
    ref.listen(connectivityNotifierProvider, (previous, next) {
      if (next.value == ConnectivityStatus.online) {
        syncCategories();
      }
    });

    // Trigger initial background sync
    Future.microtask(() => syncCategories());
    return _fetchLocalCategories(storeId);
  }

  RealtimeChannel _listenToRealtimeChanges(String storeId) {
    return _supabase
        .channel('public:categories:store:$storeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categories',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'store_id',
            value: storeId,
          ),
          callback: (payload) async {
            await syncCategories();
          },
        )
        .subscribe();
  }

  Future<List<Category>> _fetchLocalCategories(String storeId) async {
    return _isar
        .collection<Category>()
        .where()
        .filter()
        .storeIdEqualTo(storeId)
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<void> syncCategories() async {
    try {
      final activeStore = ref.read(activeStoreProvider).value;
      final storeId = activeStore?['id'];
      if (storeId == null) return;

      final isOnline =
          ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;
      if (!isOnline) return;

      final response = await _supabase.retryWithFreshSession(() => _supabase
          .from('categories')
          .select()
          .eq('store_id', storeId));

      final categories = (response as List)
          .map(
            (data) => Category()
              ..supabaseId = data['id'].toString()
              ..storeId = data['store_id'].toString()
              ..name = data['name']
              ..updatedAt = data['updated_at'] != null
                  ? DateTime.parse(data['updated_at'])
                  : null
              ..isSynced = true,
          )
          .toList();
      final remoteIds = categories.map((c) => c.supabaseId).toSet();

      await _isar.writeTxn(() async {
        // 1. Update/Add dari Remote
        for (var category in categories) {
          await _isar.collection<Category>().putBySupabaseId(category);
        }

        // 2. Hapus data lokal yang sudah tersinkron tapi tidak ada di Remote
        final localCategories = await _isar
            .collection<Category>()
            .filter()
            .isSyncedEqualTo(true)
            .isDeletedEqualTo(false)
            .findAll();

        for (var lc in localCategories) {
          if (!remoteIds.contains(lc.supabaseId)) {
            await _isar.collection<Category>().delete(lc.id);
          }
        }
      });

      state = AsyncData(await _fetchLocalCategories(storeId));
    } catch (e) {
      print('DEBUG: Error syncing categories: $e');
    }
  }

  Future<void> addCategory({required String name}) async {
    final activeStore = ref.read(activeStoreProvider).value;
    if (activeStore == null) return;

    final storeId = activeStore['id'];
    final localId = _uuid.v4();

    // 1. Save locally
    final category = Category()
      ..supabaseId = localId
      ..storeId = storeId
      ..name = name
      ..isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.collection<Category>().putBySupabaseId(category);
    });
    ref.invalidateSelf();

    // 2. Try sync if online
    final isOnline =
        ref.read(connectivityNotifierProvider).value ==
        ConnectivityStatus.online;
    if (isOnline) {
      try {
        await _supabase.from('categories').insert({
          'id': localId,
          'store_id': storeId,
          'name': name,
        });

        await _isar.writeTxn(() async {
          category.isSynced = true;
          await _isar.collection<Category>().putBySupabaseId(category);
        });
        ref.invalidateSelf();
      } catch (e) {
        await _isar.writeTxn(() async {
          category.syncError = e.toString();
          await _isar.collection<Category>().putBySupabaseId(category);
        });
        ref.invalidateSelf();
      }
    }
  }

  Future<void> updateCategory({
    required String supabaseId,
    required String name,
  }) async {
    // 1. Update locally
    final localCategory = await _isar
        .collection<Category>()
        .filter()
        .supabaseIdEqualTo(supabaseId)
        .findFirst();
    if (localCategory != null) {
      await _isar.writeTxn(() async {
        localCategory.name = name;
        localCategory.isSynced = false;
        await _isar.collection<Category>().put(localCategory);
      });
      ref.invalidateSelf();
    }

    // 2. Try sync if online
    final isOnline =
        ref.read(connectivityNotifierProvider).value ==
        ConnectivityStatus.online;
    if (isOnline) {
      try {
        await _supabase
            .from('categories')
            .update({'name': name})
            .eq('id', supabaseId);

        await _isar.writeTxn(() async {
          localCategory?.isSynced = true;
          if (localCategory != null)
            await _isar.collection<Category>().put(localCategory);
        });
      } catch (e) {
        await _isar.writeTxn(() async {
          localCategory?.syncError = e.toString();
          if (localCategory != null)
            await _isar.collection<Category>().put(localCategory);
        });
      }
    }
  }

  Future<void> deleteCategory(String supabaseId) async {
    try {
      // 1. Soft delete locally
      final localCategory = await _isar
          .collection<Category>()
          .filter()
          .supabaseIdEqualTo(supabaseId)
          .findFirst();
      if (localCategory != null) {
        await _isar.writeTxn(() async {
          localCategory.isDeleted = true;
          localCategory.isSynced = false;
          await _isar.collection<Category>().put(localCategory);
        });
        ref.invalidateSelf();
      }

      // 2. Try sync if online
      final isOnline =
          ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;
      if (isOnline) {
        await _supabase.from('categories').delete().eq('id', supabaseId);

        // Hard delete locally
        await _isar.writeTxn(() async {
          await _isar
              .collection<Category>()
              .filter()
              .supabaseIdEqualTo(supabaseId)
              .deleteAll();
        });
        ref.invalidateSelf();
      }
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/store.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:isar/isar.dart';

part 'store_provider.g.dart';

@riverpod
class ActiveStore extends _$ActiveStore {
  static const _storageKey = 'active_store_id';
  final _isar = IsarService.instance;

  @override
  FutureOr<Map<String, dynamic>?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_storageKey);
    
    if (savedId != null) {
      // 1. Try Isar first (Works offline)
      final localStore = await _isar.stores.filter().supabaseIdEqualTo(savedId).findFirst();
      
      // 2. If online, update from Supabase
      final connectivity = ref.read(connectivityNotifierProvider).value;
      if (connectivity == ConnectivityStatus.online) {
        final supabase = Supabase.instance.client;
        try {
          final response = await supabase.from('stores').select().eq('id', savedId).single();
          
          // Save to Isar
          final updatedStore = Store.fromMap(response);
          await _isar.writeTxn(() => _isar.stores.putBySupabaseId(updatedStore));
          
          return response;
        } catch (e) {
          // If not found in Supabase but found in Isar, keep the local one
          if (localStore != null) return localStore.toMap();
          
          await prefs.remove(_storageKey);
        }
      }
      
      return localStore?.toMap();
    }
    return null;
  }

  Future<void> selectStore(Map<String, dynamic> storeMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, storeMap['id'].toString());
    
    // Save to Isar for offline access
    final store = Store.fromMap(storeMap);
    await _isar.writeTxn(() => _isar.stores.putBySupabaseId(store));
    
    state = AsyncData(storeMap);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = const AsyncData(null);
  }
}

@riverpod
Future<List<Map<String, dynamic>>> userStores(UserStoresRef ref) async {
  final supabase = Supabase.instance.client;
  final isar = IsarService.instance;
  final user = supabase.auth.currentUser;
  
  if (user == null) return [];

  final connectivity = ref.watch(connectivityNotifierProvider).value;

  // 1. Fetch Local First
  final localStores = await isar.stores.where().findAll();
  
  // 2. If online, fetch from Supabase and sync
  if (connectivity == ConnectivityStatus.online) {
    try {
      final memberStoreData = await supabase
          .from('store_members')
          .select('store_id')
          .eq('user_id', user.id);
      
      final memberStoreIds = (memberStoreData as List)
          .map((m) => m['store_id'] as String)
          .toList();

      List<dynamic> remoteStores;
      if (memberStoreIds.isNotEmpty) {
        remoteStores = await supabase
            .from('stores')
            .select()
            .or('id.in.(${memberStoreIds.join(',')}),owner_id.eq.${user.id}');
      } else {
        remoteStores = await supabase
            .from('stores')
            .select()
            .eq('owner_id', user.id);
      }

      final stores = List<Map<String, dynamic>>.from(remoteStores);

      // Save all to Isar
      await isar.writeTxn(() async {
        for (var s in stores) {
          await isar.stores.putBySupabaseId(Store.fromMap(s));
        }
      });

      return stores;
    } catch (e) {
      print('Error fetching remote stores: $e');
    }
  }

  return localStores.map((s) => s.toMap()).toList();
}

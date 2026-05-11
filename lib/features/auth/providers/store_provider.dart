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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_storageKey);
    
    if (savedId != null) {
      // 1. Try Isar first
      final localStore = await _isar.stores.filter()
          .supabaseIdEqualTo(savedId)
          .and()
          .group((q) => q.ownerIdEqualTo(user.id).or().userRoleIsNotNull())
          .findFirst();
      
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

  Future<void> createStore({
    required String name,
    required String address,
    required String businessType,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // 1. Insert into stores
    final storeResponse = await supabase.from('stores').insert({
      'name': name,
      'address': address,
      'business_type': businessType,
      'owner_id': user.id,
      'settings': {
        'features': {
          'kds': businessType == 'Restaurant' || businessType == 'Cafe',
          'tables': businessType == 'Restaurant',
          'customers': true,
          'promotions': true,
          'reservations': businessType == 'Restaurant',
        },
        'operational': {
          'business_model': businessType.toLowerCase(),
        }
      }
    }).select().single();

    final storeId = storeResponse['id'];

    // 2. Insert into store_members
    await supabase.from('store_members').insert({
      'user_id': user.id,
      'store_id': storeId,
      'role': 'Owner',
      'status': 'active',
    });

    // 3. Update users table
    await supabase.from('users').update({'store_id': storeId}).eq('id', user.id);

    // 4. Select the store
    await selectStore(storeResponse);
    
    // 5. Refresh user stores list
    ref.invalidate(userStoresProvider);
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
      final response = await supabase
          .from('store_members')
          .select('role, stores:stores(*)')
          .eq('user_id', user.id);
      
      final stores = (response as List).map((item) {
        final storeMap = Map<String, dynamic>.from(item['stores']);
        storeMap['user_role'] = item['role']; // Add role to the store map
        return storeMap;
      }).toList();

      // Save all to Isar (Note: Isar model might need user_role if we want it offline)
      await isar.writeTxn(() async {
        for (var s in stores) {
          final storeObj = Store.fromMap(s);
          // We can use settings or a dedicated field in Store model for role
          // For now, let's just save the store itself.
          await isar.stores.putBySupabaseId(storeObj);
        }
      });

      return stores;
    } catch (e) {
      print('Error fetching remote stores: $e');
    }
  }

  return localStores.map((s) => s.toMap()).toList();
}

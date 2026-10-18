import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/store.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';
import 'package:isar_community/isar.dart';

part 'store_provider.g.dart';

final userRoleProvider = Provider<String?>((ref) {
  final activeStore = ref.watch(activeStoreProvider).value;
  return activeStore?['user_role'] as String?;
});

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
      
      // 2. If online, update from Supabase with Role
      final connectivity = ref.read(connectivityNotifierProvider).value;
      if (connectivity == ConnectivityStatus.online) {
        final supabase = Supabase.instance.client;
        try {
          await supabase.ensureValidSession();
          // Join with store_members to get the user's role in this store
          final response = await supabase
              .from('store_members')
              .select('role, stores(*)')
              .eq('store_id', savedId)
              .eq('user_id', user.id)
              .maybeSingle();
          
          if (response != null && response['stores'] != null) {
            final storeMap = Map<String, dynamic>.from(response['stores']);
            
            // If the store was soft-deleted, clear it immediately
            if (storeMap['deleted_at'] != null) {
              await prefs.remove(_storageKey);
              await _isar.writeTxn(() =>
                  _isar.stores.filter().supabaseIdEqualTo(savedId).deleteFirst());
              return null;
            }

            storeMap['user_role'] = response['role'];
            
            // Save to Isar (Note: Store model should ideally handle user_role)
            final updatedStore = Store.fromMap(storeMap);
            await _isar.writeTxn(() => _isar.stores.putBySupabaseId(updatedStore));
            
            return storeMap;
          } else {
            // Not found in Supabase or membership revoked
            await prefs.remove(_storageKey);
            await _isar.writeTxn(() =>
                _isar.stores.filter().supabaseIdEqualTo(savedId).deleteFirst());
            return null;
          }
        } catch (e) {
          // If network error but found in Isar, check local fallback
          if (localStore != null) return localStore.toMap();
          
          await prefs.remove(_storageKey);
        }
      }
      
      return localStore?.toMap();
    }
    return null;
  }

  /// Validates with Supabase whether the currently active store still exists and has not been deleted.
  /// If it has been deleted, it clears the active store state and Isar cache, returning false.
  Future<bool> validateActiveStore() async {
    final currentStore = state.value;
    if (currentStore == null) return false;

    final storeId = currentStore['id']?.toString();
    if (storeId == null) return false;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final connectivity = ref.read(connectivityNotifierProvider).value;
    if (connectivity == ConnectivityStatus.offline) return true;

    try {
      await supabase.ensureValidSession();
      final response = await supabase
          .from('store_members')
          .select('role, stores(*)')
          .eq('store_id', storeId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null ||
          response['stores'] == null ||
          response['stores']['deleted_at'] != null) {
        await clear();
        await _isar.writeTxn(() =>
            _isar.stores.filter().supabaseIdEqualTo(storeId).deleteFirst());
        ref.invalidate(userStoresProvider);
        return false;
      }
      return true;
    } catch (e) {
      // In case of error (e.g. transient network issue), keep existing state
      return true;
    }
  }

  Future<void> selectStore(Map<String, dynamic> storeMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, storeMap['id'].toString());
    
    // Save to Isar for offline access
    final store = Store.fromMap(storeMap);
    await _isar.writeTxn(() => _isar.stores.putBySupabaseId(store));
    
    state = AsyncData(storeMap);

    await AnalyticsService.instance.logStoreSelection(
      storeId: storeMap['id']?.toString() ?? '',
      storeName: storeMap['name']?.toString() ?? '',
    );
  }

  /// Beralih ke toko tertentu berdasarkan ID toko (misal ketika tap notifikasi dari toko lain).
  Future<bool> switchStoreById(String storeId) async {
    if (storeId.isEmpty) return false;
    final currentStore = state.value;
    if (currentStore != null && currentStore['id']?.toString() == storeId) {
      return true; // Sudah di toko ini
    }

    // 1. Coba cari di Isar terlebih dahulu
    final localStore = await _isar.stores.filter()
        .supabaseIdEqualTo(storeId)
        .findFirst();

    if (localStore != null) {
      await selectStore(localStore.toMap());
    }

    // 2. Jika online, perbarui info detail & user_role dari Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final connectivity = ref.read(connectivityNotifierProvider).value;
      if (connectivity == ConnectivityStatus.online) {
        try {
          final supabase = Supabase.instance.client;
          await supabase.ensureValidSession();
          final response = await supabase
              .from('store_members')
              .select('role, stores(*)')
              .eq('store_id', storeId)
              .eq('user_id', user.id)
              .maybeSingle();

          if (response != null && response['stores'] != null) {
            final storeMap = Map<String, dynamic>.from(response['stores']);
            if (storeMap['deleted_at'] == null) {
              storeMap['user_role'] = response['role'];
              await selectStore(storeMap);
              return true;
            }
          }
        } catch (e) {
          // Abaikan jika network issue dan sudah dapat dari Isar
        }
      }
    }

    return localStore != null;
  }

  Future<void> createStore({
    required String name,
    required String address,
    required String businessType,
    String? province,
    String? city,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // 1. Insert into stores — all features enabled by default regardless of business type
    final storeResponse = await supabase.from('stores').insert({
      'name': name,
      'address': address,
      'business_type': businessType,
      'province': province,
      'city': city,
      'owner_id': user.id,
      'settings': {
        'features': {
          'tables': true,
          'customers': true,
          'promotions': true,
          'reservations': true,
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

    // 4. Select the store with Owner role
    final storeMap = Map<String, dynamic>.from(storeResponse);
    storeMap['user_role'] = 'Owner';
    await selectStore(storeMap);
    
    // 5. Refresh user stores list
    ref.invalidate(userStoresProvider);

    await AnalyticsService.instance.logStoreCreation(
      storeName: name,
      businessType: businessType,
    );
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    final currentStore = state.value;
    if (currentStore == null) return;

    final supabase = Supabase.instance.client;
    final storeId = currentStore['id'];

    try {
      // Merge new settings with existing ones if necessary, 
      // but here we expect the caller to provide the full settings map or we can merge here.
      final existingSettings = currentStore['settings'] as Map<String, dynamic>? ?? {};
      final updatedSettings = {...existingSettings, ...newSettings};

      await supabase.from('stores').update({
        'settings': updatedSettings,
      }).eq('id', storeId);

      // Update local state
      final updatedStore = {...currentStore, 'settings': updatedSettings};
      state = AsyncData(updatedStore);

      // Update Isar
      final storeObj = Store.fromMap(updatedStore);
      await _isar.writeTxn(() => _isar.stores.putBySupabaseId(storeObj));
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = const AsyncData(null);
  }

  /// Soft-deletes the active store. Only the store owner may do this.
  /// Financial records (transactions) are intentionally preserved and stay
  /// blocked from hard-deletion at the database level — this only marks the
  /// store as deleted (`deleted_at`) so it disappears from every listing.
  Future<void> deleteStore() async {
    final currentStore = state.value;
    if (currentStore == null) throw 'No active store selected';

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final storeId = currentStore['id'].toString();
    if (currentStore['owner_id'] != user.id) {
      throw 'Only the store owner can delete this store';
    }

    await supabase
        .from('stores')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', storeId)
        .eq('owner_id', user.id);

    // Drop local cache for the deleted store and clear the active selection.
    await _isar.writeTxn(() =>
        _isar.stores.filter().supabaseIdEqualTo(storeId).deleteFirst());
    ref.invalidate(userStoresProvider);

    await clear();
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
      await supabase.ensureValidSession();
      final response = await supabase
          .from('store_members')
          .select('role, stores:stores(*)')
          .eq('user_id', user.id);
      
      final stores = <Map<String, dynamic>>[];
      for (final item in (response as List)) {
        if (item['stores'] == null) continue;
        final storeData = Map<String, dynamic>.from(item['stores']);
        // Ignore soft-deleted stores
        if (storeData['deleted_at'] != null) continue;
        storeData['user_role'] = item['role'];
        stores.add(storeData);
      }

      // Sync with Isar: put active stores, remove local stores no longer present/active
      final activeSupabaseIds = stores.map((s) => s['id'].toString()).toSet();
      await isar.writeTxn(() async {
        // Prune stores locally that were deleted or user is no longer member of
        for (final local in localStores) {
          if (!activeSupabaseIds.contains(local.supabaseId)) {
            await isar.stores.delete(local.id);
          }
        }
        for (final s in stores) {
          final storeObj = Store.fromMap(s);
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

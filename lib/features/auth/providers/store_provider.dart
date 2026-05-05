import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'store_provider.g.dart';

@riverpod
class ActiveStore extends _$ActiveStore {
  static const _storageKey = 'active_store_id';

  @override
  FutureOr<Map<String, dynamic>?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_storageKey);
    
    if (savedId != null) {
      final supabase = Supabase.instance.client;
      try {
        final store = await supabase.from('stores').select().eq('id', savedId).single();
        return store;
      } catch (e) {
        // Jika toko tidak ditemukan atau error, hapus dari storage
        await prefs.remove(_storageKey);
      }
    }
    return null;
  }

  Future<void> selectStore(Map<String, dynamic> store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, store['id'].toString());
    state = AsyncData(store);
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
  final user = supabase.auth.currentUser;
  
  if (user == null) return [];

  // Ambil toko di mana user adalah owner
  final ownedStores = await supabase.from('stores').select().eq('owner_id', user.id);
  
  // Nanti bisa ditambah pencarian toko di mana user adalah staff
  
  return List<Map<String, dynamic>>.from(ownedStores);
}

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

  try {
    // 1. Ambil ID toko dari tabel store_members (Tempat user jadi Staff/Owner/Kasir)
    final memberStoreData = await supabase
        .from('store_members')
        .select('store_id')
        .eq('user_id', user.id);
    
    final memberStoreIds = (memberStoreData as List)
        .map((m) => m['store_id'] as String)
        .toList();

    // 2. Ambil semua toko yang ID-nya ada di daftar memberStoreIds ATAU owner_id-nya adalah user.id
    // Catatan: Menggunakan query 'in' untuk efisiensi
    var query = supabase.from('stores').select();
    
    if (memberStoreIds.isNotEmpty) {
      // Ambil toko yang user adalah member ATAU owner
      final stores = await supabase
          .from('stores')
          .select()
          .or('id.in.(${memberStoreIds.join(',')}),owner_id.eq.${user.id}');
      return List<Map<String, dynamic>>.from(stores);
    } else {
      // Jika tidak ada di store_members, ambil yang owned saja
      final ownedStores = await supabase
          .from('stores')
          .select()
          .eq('owner_id', user.id);
      return List<Map<String, dynamic>>.from(ownedStores);
    }
  } catch (e) {
    print('Error fetching user stores: $e');
    return [];
  }
}

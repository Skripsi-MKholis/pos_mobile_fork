import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final customerStoreIdProvider = StateProvider<String?>((ref) => null);
final customerTableIdProvider = StateProvider<String?>((ref) => null);
final customerTableNameProvider = StateProvider<String?>((ref) => null);

final customerStoreDetailsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final storeId = ref.watch(customerStoreIdProvider);
  if (storeId == null || storeId.isEmpty) return null;

  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('stores')
        .select()
        .eq('id', storeId)
        .maybeSingle();
    return response;
  } catch (e) {
    // If it fails, log and return null
    return null;
  }
});

final transactionStreamProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, transactionId) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('id', transactionId)
      .map((list) => list.isEmpty ? null : list.first);
});

final transactionItemsStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, transactionId) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('transaction_items')
      .stream(primaryKey: ['id'])
      .eq('transaction_id', transactionId);
});

final customerTransactionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null || user.email == null) {
    return Stream.value([]);
  }

  final controller = StreamController<List<Map<String, dynamic>>>();
  Timer? timer;

  Future<void> fetch() async {
    try {
      final customersRes = await supabase
          .from('customers')
          .select('id')
          .eq('email', user.email!);
      
      final customerIds = customersRes.map((c) => c['id'] as String).toList();
      if (customerIds.isEmpty) {
        if (!controller.isClosed) controller.add([]);
        return;
      }

      final transactionsRes = await supabase
          .from('transactions')
          .select('*, stores(name, address, phone), transaction_items(product_name, quantity)')
          .inFilter('customer_id', customerIds)
          .order('created_at', ascending: false);

      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(transactionsRes));
      }
    } catch (e) {
      debugPrint('Error fetching customer transactions: $e');
    }
  }

  fetch();
  timer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});


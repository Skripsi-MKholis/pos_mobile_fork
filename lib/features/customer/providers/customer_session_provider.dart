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

class CustomerAllStoresState {
  final List<Map<String, dynamic>> stores;
  final bool hasNextPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String searchQuery;
  final int page;

  CustomerAllStoresState({
    this.stores = const [],
    this.hasNextPage = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.searchQuery = '',
    this.page = 0,
  });

  CustomerAllStoresState copyWith({
    List<Map<String, dynamic>>? stores,
    bool? hasNextPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? searchQuery,
    int? page,
  }) {
    return CustomerAllStoresState(
      stores: stores ?? this.stores,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
    );
  }
}

class CustomerAllStoresNotifier extends StateNotifier<CustomerAllStoresState> {
  CustomerAllStoresNotifier() : super(CustomerAllStoresState()) {
    fetchStores(refresh: true);
  }

  static const int _pageSize = 15;

  Future<void> fetchStores({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, page: 0, stores: [], hasNextPage: true);
    } else {
      if (!state.hasNextPage) return;
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final supabase = Supabase.instance.client;
      final start = state.page * _pageSize;
      final end = start + _pageSize - 1;

      var query = supabase.from('stores').select();

      if (state.searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%${state.searchQuery}%,business_type.ilike.%${state.searchQuery}%');
      }

      final response = await query
          .order('name', ascending: true)
          .range(start, end);

      final newStores = List<Map<String, dynamic>>.from(response);

      state = state.copyWith(
        stores: refresh ? newStores : [...state.stores, ...newStores],
        isLoading: false,
        isLoadingMore: false,
        hasNextPage: newStores.length == _pageSize,
        page: state.page + 1,
      );
    } catch (e, stack) {
      debugPrint('Error fetching stores: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  void updateSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    fetchStores(refresh: true);
  }
}

final customerAllStoresProvider = StateNotifierProvider.autoDispose<CustomerAllStoresNotifier, CustomerAllStoresState>((ref) {
  return CustomerAllStoresNotifier();
});


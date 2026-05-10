import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

part 'transaction_history_provider.g.dart';

class TransactionHistoryState {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;

  TransactionHistoryState({
    required this.transactions,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
  });

  TransactionHistoryState copyWith({
    List<Map<String, dynamic>>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

@riverpod
class TransactionHistory extends _$TransactionHistory {
  final _supabase = Supabase.instance.client;
  final int _pageSize = 20;

  @override
  FutureOr<TransactionHistoryState> build() async {
    final activeStore = ref.watch(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return TransactionHistoryState(transactions: []);

    final data = await _fetchFromSupabase(storeId, 0);
    return TransactionHistoryState(
      transactions: data,
      page: 0,
      hasMore: data.length == _pageSize,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFromSupabase(
    String storeId,
    int page,
  ) async {
    final response = await _supabase
        .from('transactions')
        .select('*, transaction_items(*)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .range(page * _pageSize, (page + 1) * _pageSize - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> fetchMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore)
      return;

    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.page + 1;
      final newData = await _fetchFromSupabase(storeId, nextPage);

      state = AsyncValue.data(
        currentState.copyWith(
          transactions: [...currentState.transactions, ...newData],
          page: nextPage,
          hasMore: newData.length == _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    state = const AsyncLoading();
    try {
      final data = await _fetchFromSupabase(storeId, 0);
      state = AsyncValue.data(
        TransactionHistoryState(
          transactions: data,
          page: 0,
          hasMore: data.length == _pageSize,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

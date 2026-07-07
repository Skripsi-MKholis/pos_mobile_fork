// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionSummaryHash() =>
    r'0aabd0b87e0ca964d7d89c852dcfa1cf1f120747';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Omzet & jumlah transaksi dihitung di server via RPC `get_transaction_summary`
/// (agregasi Postgres, hanya 1 baris yang dikirim) — bukan menjumlahkan list
/// transaksi di client. Fallback ke agregasi cache Isar saat offline.
///
/// Copied from [transactionSummary].
@ProviderFor(transactionSummary)
const transactionSummaryProvider = TransactionSummaryFamily();

/// Omzet & jumlah transaksi dihitung di server via RPC `get_transaction_summary`
/// (agregasi Postgres, hanya 1 baris yang dikirim) — bukan menjumlahkan list
/// transaksi di client. Fallback ke agregasi cache Isar saat offline.
///
/// Copied from [transactionSummary].
class TransactionSummaryFamily extends Family<AsyncValue<TransactionSummary>> {
  /// Omzet & jumlah transaksi dihitung di server via RPC `get_transaction_summary`
  /// (agregasi Postgres, hanya 1 baris yang dikirim) — bukan menjumlahkan list
  /// transaksi di client. Fallback ke agregasi cache Isar saat offline.
  ///
  /// Copied from [transactionSummary].
  const TransactionSummaryFamily();

  /// Omzet & jumlah transaksi dihitung di server via RPC `get_transaction_summary`
  /// (agregasi Postgres, hanya 1 baris yang dikirim) — bukan menjumlahkan list
  /// transaksi di client. Fallback ke agregasi cache Isar saat offline.
  ///
  /// Copied from [transactionSummary].
  TransactionSummaryProvider call({
    DateTime? date,
  }) {
    return TransactionSummaryProvider(
      date: date,
    );
  }

  @override
  TransactionSummaryProvider getProviderOverride(
    covariant TransactionSummaryProvider provider,
  ) {
    return call(
      date: provider.date,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'transactionSummaryProvider';
}

/// Omzet & jumlah transaksi dihitung di server via RPC `get_transaction_summary`
/// (agregasi Postgres, hanya 1 baris yang dikirim) — bukan menjumlahkan list
/// transaksi di client. Fallback ke agregasi cache Isar saat offline.
///
/// Copied from [transactionSummary].
class TransactionSummaryProvider
    extends AutoDisposeFutureProvider<TransactionSummary> {
  /// Omzet & jumlah transaksi dihitung di server via RPC `get_transaction_summary`
  /// (agregasi Postgres, hanya 1 baris yang dikirim) — bukan menjumlahkan list
  /// transaksi di client. Fallback ke agregasi cache Isar saat offline.
  ///
  /// Copied from [transactionSummary].
  TransactionSummaryProvider({
    DateTime? date,
  }) : this._internal(
          (ref) => transactionSummary(
            ref as TransactionSummaryRef,
            date: date,
          ),
          from: transactionSummaryProvider,
          name: r'transactionSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$transactionSummaryHash,
          dependencies: TransactionSummaryFamily._dependencies,
          allTransitiveDependencies:
              TransactionSummaryFamily._allTransitiveDependencies,
          date: date,
        );

  TransactionSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime? date;

  @override
  Override overrideWith(
    FutureOr<TransactionSummary> Function(TransactionSummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TransactionSummaryProvider._internal(
        (ref) => create(ref as TransactionSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TransactionSummary> createElement() {
    return _TransactionSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionSummaryProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TransactionSummaryRef
    on AutoDisposeFutureProviderRef<TransactionSummary> {
  /// The parameter `date` of this provider.
  DateTime? get date;
}

class _TransactionSummaryProviderElement
    extends AutoDisposeFutureProviderElement<TransactionSummary>
    with TransactionSummaryRef {
  _TransactionSummaryProviderElement(super.provider);

  @override
  DateTime? get date => (origin as TransactionSummaryProvider).date;
}

String _$transactionHistoryHash() =>
    r'cac8e39523e131d2bd4f2ebe2c52b9242fe731ea';

/// See also [TransactionHistory].
@ProviderFor(TransactionHistory)
final transactionHistoryProvider = AutoDisposeAsyncNotifierProvider<
    TransactionHistory, TransactionHistoryState>.internal(
  TransactionHistory.new,
  name: r'transactionHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TransactionHistory
    = AutoDisposeAsyncNotifier<TransactionHistoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

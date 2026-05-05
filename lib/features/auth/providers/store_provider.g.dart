// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userStoresHash() => r'67b671e3d684b95b7786096c13c2ce85022dde9c';

/// See also [userStores].
@ProviderFor(userStores)
final userStoresProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
  userStores,
  name: r'userStoresProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userStoresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserStoresRef
    = AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$activeStoreHash() => r'a92c65d57d09d874357ca9b633277d4b50aa53f3';

/// See also [ActiveStore].
@ProviderFor(ActiveStore)
final activeStoreProvider = AutoDisposeAsyncNotifierProvider<ActiveStore,
    Map<String, dynamic>?>.internal(
  ActiveStore.new,
  name: r'activeStoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveStore = AutoDisposeAsyncNotifier<Map<String, dynamic>?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

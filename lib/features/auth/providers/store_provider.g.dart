// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userStoresHash() => r'64d15acc6ba0dde2d3c05ff1da0f8ed3a53f99ae';

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
String _$activeStoreHash() => r'c140b94d9aab419d793568e6718bc417759a9aa4';

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

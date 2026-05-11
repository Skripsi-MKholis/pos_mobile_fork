// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userStoresHash() => r'e6bf5e3ae1c8fb22690311dd5c80aa4e36912461';

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
String _$activeStoreHash() => r'75d5f8737cc54d588bed83003e068e7ae0c5cc31';

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

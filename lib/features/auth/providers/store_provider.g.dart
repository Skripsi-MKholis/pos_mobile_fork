// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userStoresHash() => r'762194806ac0d4827eda0f661e86c068afa2ec6d';

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
String _$activeStoreHash() => r'd5f8394d9b91af7ea13cab8607c97f2d37eb061d';

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

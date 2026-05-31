// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unreadNotificationCountHash() =>
    r'68e4ec526475bc5ac83d404cd2641a64f9d827c1';

/// See also [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeProvider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UnreadNotificationCountRef = AutoDisposeProviderRef<int>;
String _$notificationNotifierHash() =>
    r'2eb7c0c86289a896052b5ac74e7ec87d6ecca81d';

/// See also [NotificationNotifier].
@ProviderFor(NotificationNotifier)
final notificationNotifierProvider = AutoDisposeAsyncNotifierProvider<
    NotificationNotifier, List<NotificationLocalModel>>.internal(
  NotificationNotifier.new,
  name: r'notificationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationNotifier
    = AutoDisposeAsyncNotifier<List<NotificationLocalModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  static const _kFirstRunKey = 'is_first_run';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFirstRunKey) ?? true;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFirstRunKey, false);
    state = const AsyncValue.data(false);
  }
}

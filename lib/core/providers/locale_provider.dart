import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

String initialLanguageCode = 'id';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'selected_language_code';

  @override
  Locale build() {
    return Locale(initialLanguageCode);
  }

  Future<void> changeLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, languageCode);
      initialLanguageCode = languageCode;
      state = Locale(languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'selected_language_code';

  @override
  Locale build() {
    _loadSavedLocale();
    return const Locale('id');
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null) {
        state = Locale(code);
      }
    } catch (e) {
      // SharedPreferences error handling
      debugPrint('Error loading saved locale: $e');
    }
  }

  Future<void> changeLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, languageCode);
      state = Locale(languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pos_mobile/firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/env/env.dart';
import 'package:pos_mobile/core/router/router.dart';
import 'package:pos_mobile/core/providers/sync_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing Supabase credentials. '
      'Please provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define during build/run.'
    );
  }

  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  try {
    await Supabase.instance.client.ensureValidSession();
  } catch (e) {
    debugPrint('Error validating session during main initialization: $e');
  }
  await IsarService.init();

  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('selected_language_code');
    if (code != null) {
      initialLanguageCode = code;
    }
  } catch (e) {
    debugPrint('Error loading saved locale in main: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep sync logic alive in the background
    ref.watch(syncNotifierProvider);

    final router = ref.watch(routerProvider);

    // Theme Colors based on Shadcn Preset: b6V64cnNom (Luma - Stone/Lime)
    final colorScheme = ShadColorScheme(
      background: const HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
      foreground: const HSLColor.fromAHSL(1.0, 20, 0.143, 0.041).toColor(),
      card: const HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
      cardForeground: const HSLColor.fromAHSL(1.0, 20, 0.143, 0.041).toColor(),
      popover: const HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
      popoverForeground: const HSLColor.fromAHSL(
        1.0,
        20,
        0.143,
        0.041,
      ).toColor(),
      primary: const HSLColor.fromAHSL(1.0, 75, 0.941, 0.439).toColor(),
      primaryForeground: const HSLColor.fromAHSL(
        1.0,
        60,
        0.091,
        0.098,
      ).toColor(),
      secondary: const HSLColor.fromAHSL(1.0, 60, 0.048, 0.959).toColor(),
      secondaryForeground: const HSLColor.fromAHSL(
        1.0,
        24,
        0.098,
        0.1,
      ).toColor(),
      muted: const HSLColor.fromAHSL(1.0, 60, 0.048, 0.959).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1.0, 25, 0.053, 0.447).toColor(),
      accent: const HSLColor.fromAHSL(1.0, 60, 0.048, 0.959).toColor(),
      accentForeground: const HSLColor.fromAHSL(1.0, 24, 0.098, 0.1).toColor(),
      destructive: const HSLColor.fromAHSL(1.0, 0, 0.842, 0.602).toColor(),
      destructiveForeground: const HSLColor.fromAHSL(
        1.0,
        60,
        0.091,
        0.978,
      ).toColor(),
      border: const HSLColor.fromAHSL(1.0, 20, 0.059, 0.9).toColor(),
      input: const HSLColor.fromAHSL(1.0, 20, 0.059, 0.9).toColor(),
      ring: const HSLColor.fromAHSL(1.0, 20, 0.143, 0.041).toColor(),
      selection: const HSLColor.fromAHSL(1.0, 75, 0.941, 0.439).toColor(),
    );

    final selectedLocale = ref.watch(localeNotifierProvider);

    return ShadApp.router(
      title: 'Parzello POS',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: selectedLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalShadLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: ThemeMode
          .light, // Memaksa Light Mode agar tidak terpengaruh sistem HP
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: colorScheme,

      ),
    );
  }
}

import 'package:flutter/foundation.dart';

/// Central place for AdMob ad unit IDs.
///
/// Saat ini memakai Google TEST ad unit IDs (aman, tidak melanggar kebijakan
/// AdMob saat development). Setelah punya akun AdMob, ganti nilai
/// `_prod*` di bawah dengan ad unit ID milikmu, dan ganti APPLICATION_ID
/// di android/app/src/main/AndroidManifest.xml.
class AdHelper {
  AdHelper._();

  // Ad unit ID produksi (AdMob app: ca-app-pub-6360290376727097).
  static const String _prodBannerAndroid =
      'ca-app-pub-6360290376727097/6815133434';
  static const String _prodInterstitialAndroid =
      'ca-app-pub-6360290376727097/4841530617';

  // Google test IDs — selalu dipakai di debug mode.
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';

  static String get bannerAdUnitId =>
      kDebugMode ? _testBannerAndroid : _prodBannerAndroid;

  static String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialAndroid : _prodInterstitialAndroid;
}

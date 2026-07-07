import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pos_mobile/core/ads/ad_helper.dart';

/// Mengelola interstitial ad dengan frequency cap agar tidak mengganggu
/// operasional kasir: iklan hanya tampil setiap [showEvery] pemicu
/// (mis. setiap 3 transaksi selesai).
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  static const int showEvery = 3;

  InterstitialAd? _ad;
  int _triggerCount = 0;
  bool _isLoading = false;

  void preload() {
    if (_ad != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isLoading = false;
        },
      ),
    );
  }

  /// Panggil di titik transisi natural (mis. selesai transaksi).
  /// Menampilkan iklan hanya tiap [showEvery] panggilan, lalu langsung
  /// menjalankan [onDone] (navigasi tidak pernah tertahan iklan).
  void maybeShow({VoidCallback? onDone}) {
    _triggerCount++;
    final ad = _ad;
    if (_triggerCount % showEvery != 0 || ad == null) {
      preload();
      onDone?.call();
      return;
    }

    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        onDone?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
        onDone?.call();
      },
    );
    ad.show();
  }
}

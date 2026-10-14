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

  /// Apakah user bebas iklan (memiliki langganan berbayar atau fitur removeAds).
  bool _isAdFree = false;

  /// Update status ad-free user. Jika user berbayar, buang iklan yang tersimpan di memori.
  void setAdFree(bool isAdFree) {
    _isAdFree = isAdFree;
    if (isAdFree && _ad != null) {
      _ad?.dispose();
      _ad = null;
    }
  }

  void preload() {
    if (_isAdFree || _ad != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_isAdFree) {
            ad.dispose();
            _ad = null;
          } else {
            _ad = ad;
          }
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
  /// Menampilkan iklan hanya tiap [showEvery] panggilan jika user TIDAK berlangganan berbayar,
  /// lalu langsung menjalankan [onDone] (navigasi tidak pernah tertahan iklan).
  void maybeShow({VoidCallback? onDone, bool isAdFree = false}) {
    if (isAdFree) {
      setAdFree(true);
    }

    if (_isAdFree) {
      onDone?.call();
      return;
    }

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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pos_mobile/core/ads/ad_helper.dart';
import 'package:pos_mobile/core/guards/feature_guard.dart';
import 'package:pos_mobile/features/settings/providers/subscription_provider.dart';

/// Banner adaptif yang bisa ditaruh di mana saja di dalam layout.
/// Iklan otomatis disembunyikan (SizedBox.shrink) jika toko berlangganan paket berbayar / Bebas Iklan.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadAd();
  }

  void _checkAndLoadAd() {
    final canRemoveAds = ref.read(canAccessFeatureProvider(AppFeature.removeAds));
    final currentSub = ref.read(currentSubscriptionProvider).value;
    final isPaid = currentSub?.isPaidActive ?? false;

    // Jika memiliki fitur bebas iklan atau paket berbayar aktif, jangan muat iklan
    if (canRemoveAds || isPaid) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (_isLoaded) {
        setState(() => _isLoaded = false);
      }
      return;
    }

    if (_bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;

    final ad = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch subscription agar jika user upgrade secara real-time, iklan langsung lenyap
    final canRemoveAds = ref.watch(canAccessFeatureProvider(AppFeature.removeAds));
    final currentSub = ref.watch(currentSubscriptionProvider).value;
    final isPaid = currentSub?.isPaidActive ?? false;

    if (canRemoveAds || isPaid) {
      return const SizedBox.shrink();
    }

    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

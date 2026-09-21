import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/app_language.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

class HomesickBannerAd extends StatefulWidget {
  const HomesickBannerAd({super.key});

  @override
  State<HomesickBannerAd> createState() => _HomesickBannerAdState();
}

class _HomesickBannerAdState extends State<HomesickBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdService.isSupported) return;

    _banner = BannerAd(
      adUnitId: AdService.familyBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _banner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null) return const SizedBox.shrink();

    return Semantics(
      label: context.familyText('ad'),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}

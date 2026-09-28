import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/app_scope.dart';

/// Stable, safe-area-aware footer slot shared by every game mode.
class FooterAdBanner extends StatefulWidget {
  const FooterAdBanner({this.backgroundColor = Colors.black, super.key});

  final Color backgroundColor;

  @override
  State<FooterAdBanner> createState() => _FooterAdBannerState();
}

class _FooterAdBannerState extends State<FooterAdBanner> {
  BannerAd? _ad;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null && !_loading) _load();
  }

  Future<void> _load() async {
    _loading = true;
    BannerAd? ad;
    try {
      ad = await AppScope.of(context, listen: false).ads.loadBanner();
    } catch (_) {
      ad = null;
    }
    if (!mounted) {
      ad?.dispose();
      return;
    }
    setState(() {
      _ad = ad;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ColoredBox(
      key: const Key('footer-ad-banner'),
      color: widget.backgroundColor,
      child: SizedBox(
        height: AdSize.banner.height.toDouble(),
        width: double.infinity,
        child: _ad == null
            ? const SizedBox.shrink()
            : Center(
                child: SizedBox(
                  width: _ad!.size.width.toDouble(),
                  height: _ad!.size.height.toDouble(),
                  child: AdWidget(ad: _ad!),
                ),
              ),
      ),
    ),
  );
}

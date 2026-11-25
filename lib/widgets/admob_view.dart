import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/theme/app_colors.dart';

/// ID factory native yang didaftarkan pada platform (lihat `MainActivity.kt`
/// dan `FeedAdFactory.kt` di Android).
const String kAdMobNativeFactoryId = 'feedAdFactory';

/// Tampilkan kotak pesan error iklan di layar (untuk diagnosis).
///
/// - `true`  → kotak error tampil di **semua** mode (termasuk release).
/// - `false` → kotak error hanya tampil di mode debug (perilaku produksi).
///
/// Catatan: kotak ini hanya muncul saat iklan GAGAL; tidak memengaruhi
/// keberhasilan pemuatan iklan. Set `false` sebelum rilis produksi.
const bool kShowAdErrors = false;

/// Pembatas permintaan iklan agar app tidak menembak Ad Unit yang sama secara
/// beruntun (penyebab error SDK `code=1` "Too many recently failed requests").
///
/// Satu Ad Unit hanya boleh diminta **sekali per [cooldown]**. Setelah jeda itu,
/// unit boleh diminta lagi.
class AdMobRequestThrottle {
  AdMobRequestThrottle._();

  /// Jeda minimum antar permintaan untuk unit yang sama.
  static const Duration cooldown = Duration(seconds: 60);

  static final Map<String, DateTime> _lastRequest = <String, DateTime>{};

  /// Kembalikan `true` bila [adUnitId] boleh diminta sekarang, lalu catat
  /// waktunya. Kembalikan `false` bila masih dalam masa cooldown.
  static bool allow(String adUnitId) {
    if (adUnitId.isEmpty) return true;
    if (cooldown == Duration.zero) return true;
    final DateTime now = DateTime.now();
    final DateTime? last = _lastRequest[adUnitId];
    if (last != null && now.difference(last) < cooldown) return false;
    _lastRequest[adUnitId] = now;
    return true;
  }
}

/// Cache iklan yang **sudah dimuat**, per Ad Unit ID.
class AdMobAdCache {
  AdMobAdCache._();

  static final Map<String, Ad> _cache = <String, Ad>{};

  static Ad? take(String adUnitId) => _cache.remove(adUnitId);

  static void store(String adUnitId, Ad ad) => _cache[adUnitId] = ad;

  static void drop(String adUnitId) => _cache.remove(adUnitId)?.dispose();
}

/// Iklan AdMob format native (in-feed). Hanya aktif di Android/iOS.
class AdMobNativeView extends StatefulWidget {
  final String adUnitId;
  final EdgeInsets padding;

  /// Batas tinggi yang tersedia. Bila lebih kecil dari tinggi iklan native,
  /// iklan tidak dimuat sama sekali (agar tidak tampil terpotong).
  final double? maxHeight;

  /// Dipanggil saat status kesiapan iklan berubah: `true` bila iklan sudah
  /// tampil, `false` bila gagal/dilewati.
  final ValueChanged<bool>? onReadyChanged;

  const AdMobNativeView({
    super.key,
    required this.adUnitId,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.maxHeight,
    this.onReadyChanged,
  });

  @override
  State<AdMobNativeView> createState() => _AdMobNativeViewState();
}

class _AdMobNativeViewState extends State<AdMobNativeView>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _loaded = false;
  bool _skipped = false;
  String? _error;

  /// Beri tahu pemanggil setelah frame selesai agar tidak memicu `setState`
  /// milik parent di tengah proses build.
  void _notifyReady(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReadyChanged?.call(value);
    });
  }

  /// True bila ruang yang tersedia cukup untuk menampilkan seluruh iklan.
  bool get _fitsBudget =>
      widget.maxHeight == null || widget.maxHeight! >= _nativeAdHeight;

  @override
  void initState() {
    super.initState();
    if (!_fitsBudget) {
      _skipped = true;
      return;
    }

    final Ad? cached = AdMobAdCache.take(widget.adUnitId);
    if (cached is NativeAd) {
      _ad = cached;
      _loaded = true;
      _notifyReady(true);
      return;
    }
    if (cached != null) cached.dispose();

    if (!AdMobRequestThrottle.allow(widget.adUnitId)) {
      _skipped = true;
      debugPrint('AdMob: native unit ${widget.adUnitId} DILEWATI (cooldown).');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (widget.adUnitId.isEmpty) return;

    try {
      final ad = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: kAdMobNativeFactoryId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _ad = ad as NativeAd;
              _loaded = true;
              _error = null;
            });
            _notifyReady(true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'AdMob: gagal memuat native ad. code=${error.code} message=${error.message}',
            );
            ad.dispose();
            if (mounted) {
              setState(() {
                _ad = null;
                _loaded = false;
                _error = '${error.code}: ${error.message}';
              });
            }
            _notifyReady(false);
          },
        ),
      );
      _ad = ad;
      ad.load();
    } catch (e, s) {
      debugPrint('AdMob: gagal memuat iklan native: $e\n$s');
      _notifyReady(false);
    }
  }

  @override
  void didUpdateWidget(covariant AdMobNativeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool unitChanged = oldWidget.adUnitId != widget.adUnitId;
    final bool budgetChanged = oldWidget.maxHeight != widget.maxHeight;
    if (!unitChanged && !budgetChanged) return;

    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _skipped = !_fitsBudget;
    _error = null;
    if (_skipped) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    if (_loaded && _ad != null) {
      AdMobAdCache.store(widget.adUnitId, _ad!);
    } else {
      _ad?.dispose();
    }
    super.dispose();
  }

  /// Tinggi tetap slot iklan native (logical px) agar geometri tidak berubah
  /// saat platform view AdWidget dipasang. Harus cukup untuk seluruh isi
  /// layout `admob_native_ad.xml` (label, headline, body, CTA, dan MediaView
  /// 120x120dp di samping teks) supaya tidak ada bagian iklan yang terpotong.
  static const double _nativeAdHeight = 160;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    if (_skipped) return const SizedBox.shrink();

    final bool ready = _loaded && _ad != null;

    if (!ready && _error != null) {
      if (!kShowAdErrors && !kDebugMode) return const SizedBox.shrink();
      return Padding(
        padding: widget.padding,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'AdMob gagal memuat: $_error',
            style: const TextStyle(color: AppColors.error, fontSize: 11),
          ),
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: SizedBox(
        height: _nativeAdHeight,
        child: ready ? AdWidget(ad: _ad!) : const SizedBox.shrink(),
      ),
    );
  }
}

/// Iklan AdMob format banner (in-feed). Hanya aktif di Android/iOS.
class AdMobBannerView extends StatefulWidget {
  final String adUnitId;
  final EdgeInsets padding;

  /// Batas tinggi yang tersedia. Bila lebih kecil dari tinggi banner yang
  /// dimuat, banner tidak ditampilkan (agar tidak terpotong).
  final double? maxHeight;

  /// Dipanggil saat status kesiapan iklan berubah: `true` bila iklan sudah
  /// tampil, `false` bila gagal/dilewati.
  final ValueChanged<bool>? onReadyChanged;

  const AdMobBannerView({
    super.key,
    required this.adUnitId,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.maxHeight,
    this.onReadyChanged,
  });

  @override
  State<AdMobBannerView> createState() => _AdMobBannerViewState();
}

class _AdMobBannerViewState extends State<AdMobBannerView>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _ad;
  bool _loaded = false;
  bool _skipped = false;
  String? _error;
  AdSize? _size;

  /// Lebar yang sudah dipakai untuk memulai permintaan iklan. `null` berarti
  /// belum dimulai; diisi dari constraint layout agar lebar banner tidak
  /// melebihi ruang slot (yang bisa memotong iklan secara horizontal).
  int? _requestedWidth;

  /// Mencegah permintaan ganda sebelum frame pertama selesai.
  bool _startScheduled = false;

  void _notifyReady(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReadyChanged?.call(value);
    });
  }

  /// True bila tinggi banner masih muat di ruang yang tersedia.
  bool _fits(AdSize size) =>
      widget.maxHeight == null || size.height <= widget.maxHeight!;

  void _start(int width) {
    if (!mounted || _requestedWidth != null) return;

    final Ad? cached = AdMobAdCache.take(widget.adUnitId);
    if (cached is BannerAd) {
      if (!_fits(cached.size)) {
        cached.dispose();
        _skipped = true;
        _notifyReady(false);
        return;
      }
      _requestedWidth = width;
      _ad = cached;
      _size = cached.size;
      _loaded = true;
      _notifyReady(true);
      return;
    }
    if (cached != null) cached.dispose();

    if (AdMobRequestThrottle.allow(widget.adUnitId)) {
      _requestedWidth = width;
      _load(width);
      return;
    }

    _skipped = true;
    debugPrint('AdMob: banner unit ${widget.adUnitId} DILEWATI (cooldown).');
  }

  Future<void> _load(int width) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (widget.adUnitId.isEmpty) return;

    AdSize size = AdSize.banner;
    try {
      size =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ??
          AdSize.banner;
    } catch (_) {
      size = AdSize.banner;
    }
    if (!mounted) return;

    // Ruang tidak cukup untuk menampilkan banner secara utuh: lewati.
    if (!_fits(size) || size.width > width) {
      _skipped = true;
      _notifyReady(false);
      return;
    }

    setState(() => _size = size);

    try {
      final ad = BannerAd(
        adUnitId: widget.adUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _ad = ad as BannerAd;
              _loaded = true;
              _error = null;
            });
            _notifyReady(true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'AdMob: gagal memuat banner. code=${error.code} message=${error.message}',
            );
            ad.dispose();
            if (mounted) {
              setState(() {
                _ad = null;
                _loaded = false;
                _error = '${error.code}: ${error.message}';
              });
            }
            _notifyReady(false);
          },
        ),
      );
      _ad = ad;
      ad.load();
    } catch (e, s) {
      debugPrint('AdMob: gagal memuat banner: $e\n$s');
      _notifyReady(false);
    }
  }

  @override
  void didUpdateWidget(covariant AdMobBannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool unitChanged = oldWidget.adUnitId != widget.adUnitId;
    final bool budgetChanged = oldWidget.maxHeight != widget.maxHeight;
    if (!unitChanged && !budgetChanged) return;
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _skipped = false;
    _requestedWidth = null;
    _startScheduled = false;
    _error = null;
    _size = null;
  }

  @override
  void dispose() {
    if (_loaded && _ad != null) {
      AdMobAdCache.store(widget.adUnitId, _ad!);
    } else {
      _ad?.dispose();
    }
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    if (widget.adUnitId.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mulai permintaan memakai lebar slot yang sebenarnya (bukan lebar
        // layar), supaya banner tidak lebih lebar dari ruang yang tersedia.
        if (_requestedWidth == null && !_startScheduled && !_skipped) {
          _startScheduled = true;
          final double available = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final int width = (available - widget.padding.horizontal)
              .truncate()
              .clamp(1, 10000);
          WidgetsBinding.instance.addPostFrameCallback((_) => _start(width));
        }

        if (_skipped) return const SizedBox.shrink();

        final int? knownHeight = _size?.height ?? _ad?.size.height;
        final int? knownWidth = _size?.width ?? _ad?.size.width;
        final double reservedHeight = (knownHeight != null && knownHeight > 0)
            ? knownHeight.toDouble()
            : 100.0;
        final double adWidth = (knownWidth != null && knownWidth > 0)
            ? knownWidth.toDouble()
            : double.infinity;

        if (!_loaded || _ad == null) {
          if (_error != null) {
            if (!kShowAdErrors && !kDebugMode) return const SizedBox.shrink();
            return Padding(
              padding: widget.padding,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'AdMob banner gagal memuat: $_error',
                  style: const TextStyle(color: AppColors.error, fontSize: 11),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return Padding(
          padding: widget.padding,
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: adWidth,
              height: reservedHeight,
              child: AdWidget(ad: _ad!),
            ),
          ),
        );
      },
    );
  }
}

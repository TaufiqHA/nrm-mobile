import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/theme/app_colors.dart';
import '../models/application_model.dart';
import 'admob_view.dart';

/// Membangun URL gambar iklan dari nilai backend.
///
/// Nilai bisa berupa URL penuh (mis. `https://...`) atau path relatif di
/// storage publik (mis. `banners/promo.jpg`). Untuk path relatif, digabung
/// dengan origin API (dengan `/api` dilepas) + `/storage/`.
String resolveAdImageUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) return value;

  var base = ApiConfig.baseUrl;
  final apiIndex = base.indexOf('/api');
  if (apiIndex >= 0) base = base.substring(0, apiIndex);
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  return '$base/storage/$value';
}

/// Label kecil "Iklan" agar slot iklan tidak tampak seperti konten aplikasi
/// (kebijakan AdSense/AdMob: iklan tidak boleh disamarkan sebagai konten).
class _AdLabel extends StatelessWidget {
  const _AdLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.16),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Iklan',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Muat konten iklan lebih dulu agar slot/pop-up hanya ditampilkan saat siap.
///
/// - Gambar: dipanaskan dengan `precacheImage`.
/// - AdMob native/banner: dimuat ke `AdMobAdCache` (lihat `preloadAdMobSlot`).
///
/// Mengembalikan `true` bila konten siap ditampilkan.
Future<bool> preloadAdSlotContent(BuildContext context, AdSlotConfig ad) async {
  if (ad.isImage) {
    final url = resolveAdImageUrl(ad.image ?? '');
    if (url.isEmpty) return false;
    final ImageProvider provider =
        AdSlotView.debugImageProviderBuilder?.call(url) ?? NetworkImage(url);
    bool failed = false;
    await precacheImage(
      provider,
      context,
      onError: (_, _) => failed = true,
    );
    return !failed;
  }

  if ((ad.isNative || ad.isBanner) && ad.hasUnit) {
    final int width =
        (MediaQuery.sizeOf(context).width - 76).truncate().clamp(1, 10000);
    return preloadAdMobSlot(
      adUnitId: ad.unit!,
      native: ad.isNative,
      width: width,
    );
  }

  return false;
}

/// Menampilkan satu slot iklan sesuai konfigurasi dari panel admin website.
///
/// - Jenis `image`    → banner gambar (di-load dari URL storage).
/// - Jenis `admob_native` / `admob_banner` → iklan AdMob in-feed.
/// - Jenis full-screen (interstitial/app open/reward) → tidak dirender di slot
///   (ditangani [AdManager]).
///
/// Slot hanya muncul setelah konten iklan berhasil dimuat; selama menunggu
/// (atau bila gagal) slot tidak memakan ruang. Setiap slot yang tampil diberi
/// bingkai + label "Iklan" supaya jelas terpisah dari konten aplikasi.
class AdSlotView extends StatefulWidget {
  final AdSlotConfig ad;

  /// Status aktif slot (dari `applicationadsactive`/`applicationadsbottomactive`).
  final bool active;

  final EdgeInsets padding;

  /// Batas tinggi opsional agar slot tidak memicu overflow pada layout tetap
  /// (mis. layout karaoke). Bila `null`, tinggi mengikuti isi iklan.
  final double? maxHeight;

  /// Bila diisi, slot menampilkan tombol close di pojok kanan atas.
  /// Pemanggil bertanggung jawab menyembunyikan slot setelah tombol ditekan.
  final VoidCallback? onClose;

  /// Tampilkan label "Iklan" di atas slot. Set `false` bila label sudah
  /// disediakan pemanggil (mis. header dialog pop-up).
  final bool showLabel;

  /// Anggap konten sudah siap sejak frame pertama. Dipakai pemanggil yang
  /// sudah memuat iklan lebih dulu (mis. pop-up lewat [preloadAdSlotContent]).
  final bool startReady;

  /// Provider gambar khusus pengujian. `null` berarti memakai [NetworkImage].
  @visibleForTesting
  static ImageProvider Function(String url)? debugImageProviderBuilder;

  const AdSlotView({
    super.key,
    required this.ad,
    this.active = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.maxHeight,
    this.onClose,
    this.showLabel = true,
    this.startReady = false,
  });

  bool get _hasRenderable =>
      (ad.isImage && (ad.image ?? '').trim().isNotEmpty) ||
      ((ad.isNative || ad.isBanner) && ad.hasUnit);

  @override
  State<AdSlotView> createState() => _AdSlotViewState();
}

class _AdSlotViewState extends State<AdSlotView> {
  late bool _ready;

  @override
  void initState() {
    super.initState();
    _ready = widget.startReady;
  }

  @override
  void didUpdateWidget(covariant AdSlotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final AdSlotConfig oldAd = oldWidget.ad;
    final AdSlotConfig newAd = widget.ad;
    final bool adChanged =
        oldAd.format != newAd.format ||
        (oldAd.image ?? '') != (newAd.image ?? '') ||
        (oldAd.unit ?? '') != (newAd.unit ?? '');
    if (adChanged) {
      _ready = widget.startReady;
    }
    if (!widget.active) _ready = false;
  }

  void _setReady(bool value) {
    if (!mounted || _ready == value) return;
    setState(() => _ready = value);
  }

  @override
  Widget build(BuildContext context) {
    final AdSlotConfig ad = widget.ad;
    if (!widget.active) return const SizedBox.shrink();

    // Iklan layar penuh tidak dirender di slot.
    if (ad.isFullScreen) return const SizedBox.shrink();
    if (!widget._hasRenderable) return const SizedBox.shrink();

    final Widget content;
    if (ad.isNative) {
      content = AdMobNativeView(
        adUnitId: ad.unit!,
        padding: widget.padding,
        onReadyChanged: _setReady,
      );
    } else if (ad.isBanner) {
      content = AdMobBannerView(
        adUnitId: ad.unit!,
        padding: widget.padding,
        onReadyChanged: _setReady,
      );
    } else {
      content = _AdImageView(
        rawUrl: ad.image ?? '',
        padding: widget.padding,
        onReadyChanged: _setReady,
      );
    }

    final double? height = widget.maxHeight;
    final Widget body = height == null
        ? content
        // Batasi tinggi agar tidak overflow pada Column dengan tinggi tetap.
        : ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: ClipRect(child: content),
          );

    // Bingkai + label "Iklan" agar slot tidak menyatu dengan konten.
    final Widget slot = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.45),
        border: Border.all(color: AppColors.cardGlassBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget? label = widget.showLabel
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.padding.left,
                    0,
                    // Sisakan ruang untuk tombol tutup di pojok kanan atas.
                    widget.padding.right + (widget.onClose == null ? 0 : 36),
                    6,
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: _AdLabel(),
                  ),
                )
              : null;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label != null) label,
              // Saat tinggi dibatasi parent, biarkan isi menyesuaikan sisa
              // ruang agar tidak overflow (mis. slot dalam layout tetap/pop-up).
              if (constraints.hasBoundedHeight)
                Flexible(fit: FlexFit.loose, child: body)
              else
                body,
            ],
          );
        },
      ),
    );

    final VoidCallback? onClose = widget.onClose;
    final Widget framed = onClose == null
        ? slot
        : Stack(
            children: [
              slot,
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    key: const ValueKey('ad_slot_close'),
                    onPressed: onClose,
                    tooltip: 'Tutup iklan',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    iconSize: 18,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          );

    // Selama iklan belum siap, slot tetap dibangun (agar proses muat berjalan)
    // tetapi disembunyikan dan tidak memakan ruang.
    return Visibility(
      visible: _ready,
      maintainState: true,
      maintainAnimation: true,
      child: framed,
    );
  }
}

/// Gambar iklan yang melaporkan kesiapannya setelah frame pertama berhasil
/// dimuat, sehingga slot baru tampil ketika gambar benar-benar ada.
class _AdImageView extends StatefulWidget {
  final String rawUrl;
  final EdgeInsets padding;
  final ValueChanged<bool> onReadyChanged;

  const _AdImageView({
    required this.rawUrl,
    required this.padding,
    required this.onReadyChanged,
  });

  @override
  State<_AdImageView> createState() => _AdImageViewState();
}

class _AdImageViewState extends State<_AdImageView> {
  String? _resolvedUrl;
  ImageProvider? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool? _lastReported;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureImage();
  }

  @override
  void didUpdateWidget(covariant _AdImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawUrl != widget.rawUrl) _ensureImage();
  }

  void _ensureImage() {
    final String url = resolveAdImageUrl(widget.rawUrl);
    if (url == _resolvedUrl && _provider != null) return;

    _detach();
    _resolvedUrl = url;
    _lastReported = null;

    if (url.isEmpty) {
      _report(false);
      return;
    }

    final ImageProvider provider =
        AdSlotView.debugImageProviderBuilder?.call(url) ?? NetworkImage(url);
    _provider = provider;

    final ImageStream stream = provider.resolve(
      createLocalImageConfiguration(context),
    );
    _stream = stream;
    _listener = ImageStreamListener(
      (_, _) => _report(true),
      onError: (_, _) => _report(false),
    );
    stream.addListener(_listener!);
  }

  void _detach() {
    final ImageStreamListener? listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _listener = null;
    _stream = null;
    _provider = null;
  }

  /// Lapor setelah frame selesai agar tidak memicu `setState` parent saat build.
  void _report(bool value) {
    if (_lastReported == value) return;
    _lastReported = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReadyChanged(value);
    });
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = _provider;
    if (provider == null) return const SizedBox.shrink();

    // Batasi tinggi agar banner yang sangat tinggi tidak memicu overflow
    // (mis. saat iklan ditampilkan di dalam dialog pop-up).
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.6;

    return Padding(
      padding: widget.padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(
            image: provider,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

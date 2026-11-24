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

/// Membangun [ImageProvider] iklan dari nilai backend.
///
/// Memakai provider khusus pengujian bila tersedia, sehingga pop-up dan slot
/// bisa diuji tanpa jaringan.
ImageProvider buildAdImageProvider(String raw) {
  final String url = resolveAdImageUrl(raw);
  return AdSlotView.debugImageProviderBuilder?.call(url) ?? NetworkImage(url);
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
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.45)),
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

/// Menampilkan satu slot iklan sesuai konfigurasi dari panel admin website.
///
/// - Jenis `image`    → banner gambar (di-load dari URL storage).
/// - Jenis `admob_native` / `admob_banner` → iklan AdMob in-feed.
/// - Jenis full-screen (interstitial/app open/reward) → tidak dirender di slot
///   (ditangani `AdManager`).
///
/// Slot hanya muncul setelah konten iklan berhasil dimuat; selama menunggu
/// (atau bila gagal) slot tidak memakan ruang.
///
/// **Iklan selalu ditampilkan utuh.** Tidak ada pemotongan (`ClipRect`) atau
/// elemen yang menutupi iklan, karena hal itu melanggar kebijakan AdMob
/// ("konten yang menghalangi iklan"). Bila ruang yang tersedia (lihat
/// [maxHeight]) lebih kecil dari ukuran iklan, slot tidak ditampilkan sama
/// sekali.
class AdSlotView extends StatefulWidget {
  final AdSlotConfig ad;

  /// Status aktif slot (dari `applicationadsactive`/`applicationadsbottomactive`).
  final bool active;

  final EdgeInsets padding;

  /// Batas tinggi total slot (termasuk label/judul dan tombol tutup).
  ///
  /// Bila `null`, tinggi mengikuti isi iklan. Bila diisi dan iklan AdMob yang
  /// dimuat lebih tinggi dari batas tersebut, iklan tidak ditampilkan (bukan
  /// dipotong). Iklan gambar tetap ditampilkan dengan skala proporsional agar
  /// seluruh bagiannya terlihat.
  final double? maxHeight;

  /// Bila diisi, slot menampilkan tombol close di luar area iklan.
  /// Pemanggil bertanggung jawab menyembunyikan slot setelah tombol ditekan.
  final VoidCallback? onClose;

  /// Tampilkan label "Iklan" di atas slot. Iklan AdMob sudah memiliki label
  /// bawaannya sendiri, jadi label ini hanya dipakai untuk iklan gambar.
  /// Set `false` bila label sudah disediakan pemanggil.
  final bool showLabel;

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
  });

  bool get _hasRenderable =>
      (ad.isImage && (ad.image ?? '').trim().isNotEmpty) ||
      ((ad.isNative || ad.isBanner) && ad.hasUnit);

  @override
  State<AdSlotView> createState() => _AdSlotViewState();
}

class _AdSlotViewState extends State<AdSlotView> {
  bool _ready = false;

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
      _ready = false;
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

    // Iklan AdMob sudah membawa labelnya sendiri; label manual hanya untuk
    // iklan gambar supaya tidak ada teks tambahan menutupi iklan.
    final bool showLabel = widget.showLabel && ad.isImage;
    final bool showClose = widget.onClose != null;
    final double headerHeight = (showLabel || showClose) ? 34 : 0;

    // Ruang untuk isi iklan: batas total dikurangi header dan padding bingkai.
    final double? contentMaxHeight = widget.maxHeight == null
        ? null
        : (widget.maxHeight! - headerHeight - 14)
              .clamp(0.0, widget.maxHeight!)
              .toDouble();

    final Widget content;
    if (ad.isNative) {
      content = AdMobNativeView(
        adUnitId: ad.unit!,
        padding: widget.padding,
        maxHeight: contentMaxHeight,
        onReadyChanged: _setReady,
      );
    } else if (ad.isBanner) {
      content = AdMobBannerView(
        adUnitId: ad.unit!,
        padding: widget.padding,
        maxHeight: contentMaxHeight,
        onReadyChanged: _setReady,
      );
    } else {
      content = _AdImageView(
        rawUrl: ad.image ?? '',
        padding: widget.padding,
        maxHeight: contentMaxHeight,
        onReadyChanged: _setReady,
      );
    }

    final Widget? header = (showLabel || showClose)
        ? Padding(
            padding: EdgeInsets.fromLTRB(
              widget.padding.left,
              0,
              widget.padding.right,
              6,
            ),
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  if (showLabel) const _AdLabel() else const SizedBox.shrink(),
                  const Spacer(),
                  if (showClose)
                    Material(
                      color: AppColors.textMuted.withValues(alpha: 0.16),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        key: const ValueKey('ad_slot_close'),
                        onPressed: widget.onClose,
                        tooltip: 'Tutup iklan',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        iconSize: 16,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        : null;

    // Bingkai + label agar slot tidak menyatu dengan konten. Isi iklan tidak
    // dipotong dan tombol tutup diletakkan di atas iklan (tidak menimpanya).
    final Widget slot = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.45),
        border: Border.all(color: AppColors.cardGlassBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Saat tinggi dibatasi parent, isi iklan mengambil sisa ruang setelah
          // header. `Flexible` membuat isi menyesuaikan (gambar mengecil
          // proporsional), bukan terpotong.
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) header,
              if (constraints.hasBoundedHeight)
                Flexible(fit: FlexFit.loose, child: content)
              else
                content,
            ],
          );
        },
      ),
    );

    // Saat ada batas tinggi dari pemanggil, jadikan batas tersebut constraint
    // nyata agar LayoutBuilder di atas mengetahui ruang yang tersedia.
    final Widget bounded = widget.maxHeight == null
        ? slot
        : ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight!),
            child: slot,
          );

    // Selama iklan belum siap, slot tetap dibangun (agar proses muat berjalan)
    // tetapi disembunyikan dan tidak memakan ruang.
    return Visibility(
      visible: _ready,
      maintainState: true,
      maintainAnimation: true,
      child: bounded,
    );
  }
}

/// Gambar iklan yang melaporkan kesiapannya setelah frame pertama berhasil
/// dimuat, sehingga slot baru tampil ketika gambar benar-benar ada.
class _AdImageView extends StatefulWidget {
  final String rawUrl;
  final EdgeInsets padding;
  final double? maxHeight;
  final ValueChanged<bool> onReadyChanged;

  const _AdImageView({
    required this.rawUrl,
    required this.padding,
    required this.maxHeight,
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

    // Tanpa batas dari pemanggil, gunakan maksimum 60% tinggi layar.
    // `BoxFit.contain` memastikan gambar diperkecil proporsional (tidak
    // dipotong) bila ruangnya lebih kecil.
    final double effectiveMaxHeight =
        widget.maxHeight ?? MediaQuery.sizeOf(context).height * 0.6;

    return Padding(
      padding: widget.padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/application_model.dart';

/// Mengelola iklan AdMob full-screen: interstitial, app open, dan reward.
///
/// Iklan inline (native/banner/gambar) dirender langsung oleh widget di
/// `ad_slot_view.dart`/`admob_view.dart`. Service ini hanya menangani format
/// yang memenuhi layar dan dipicu oleh navigasi/aksi pengguna.
///
/// Ad Unit full-screen diambil dari salah satu slot iklan (slot 1, slot 2, atau
/// banner bawah) yang pada panel admin website disetel ke jenis interstitial,
/// app open, atau reward.
class AdManager {
  AdManager._();

  static final AdManager instance = AdManager._();

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ---- Konfigurasi Ad Unit (berasal dari konfigurasi aplikasi) ----
  String? _interstitialUnit;
  String? _appOpenUnit;
  String? _rewardUnit;

  // ---- Iklan yang sudah dimuat ----
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;
  RewardedAd? _reward;

  bool _loadingInterstitial = false;
  bool _loadingAppOpen = false;
  bool _loadingReward = false;

  bool _configuredOnce = false;
  bool _showAppOpenWhenReady = false;

  // ---- Status iklan layar penuh ----
  /// True selama salah satu iklan layar penuh sedang tampil. Dipakai agar dua
  /// iklan layar penuh tidak pernah tampil bertumpuk.
  bool _fullScreenShowing = false;

  /// Waktu iklan layar penuh terakhir tampil (untuk memberi jeda).
  DateTime? _lastFullScreen;

  /// App open hanya sekali per proses aplikasi (cold start).
  bool _appOpenShownThisSession = false;

  // ---- Pengaturan frekuensi ----
  int _songOpens = 0;
  DateTime? _lastInterstitial;
  DateTime? _lastAppOpen;

  /// Interstitial ditampilkan tiap sekian pemutaran lagu.
  static const int _interstitialEvery = 3;

  /// Jeda minimum antar interstitial.
  static const Duration _interstitialCooldown = Duration(minutes: 3);

  /// Jeda minimum antar app open (lintas sesi).
  static const Duration _appOpenCooldown = Duration(hours: 4);

  /// Jeda minimum sebelum iklan layar penuh berikutnya boleh tampil.
  static const Duration _fullScreenGap = Duration(seconds: 45);

  static const String _prefLastAppOpen = 'admob_last_app_open_ms';

  /// Terapkan konfigurasi dari data aplikasi. Aman dipanggil berulang.
  void configure(ApplicationModel config) {
    if (!_supported) return;

    _interstitialUnit = null;
    _appOpenUnit = null;
    _rewardUnit = null;

    final slots = <AdSlotConfig>[
      if (config.isAds1Active) config.ads1Config,
      if (config.isAds2Active) config.ads2Config,
      if (config.isAdsHomeActive) config.adsHomeConfig,
      if (config.isAdsHomeTopActive) config.adsHomeTopConfig,
      if (config.isAdsHomeBottomActive) config.adsHomeBottomConfig,
      if (config.isAdsLyricActive) config.adsLyricConfig,
      if (config.isAdsLyricTopActive) config.adsLyricTopConfig,
      if (config.isAdsLyricBottomActive) config.adsLyricBottomConfig,
      if (config.isAdsMusikTopActive) config.adsMusikTopConfig,
      if (config.isAdsMusikActive) config.adsMusikConfig,
      if (config.isAdsMusikBottomActive) config.adsMusikBottomConfig,
      if (config.isAdsBottomActive) config.adsBottomConfig,
    ];
    for (final slot in slots) {
      if (!slot.isAdMob) continue;
      final unit = slot.unit;
      if (slot.isInterstitial && _interstitialUnit == null)
        _interstitialUnit = unit;
      if (slot.isAppOpen && _appOpenUnit == null) _appOpenUnit = unit;
      if (slot.isReward && _rewardUnit == null) _rewardUnit = unit;
    }

    if (!_configuredOnce) {
      _configuredOnce = true;
      _showAppOpenWhenReady = true;
    }

    // Iklan yang sudah terlanjur dimuat harus dibuang saat slotnya dinonaktifkan,
    // agar tidak tetap tampil walau admin sudah mematikan slot tersebut.
    if (_interstitialUnit == null && _interstitial != null) {
      _interstitial!.dispose();
      _interstitial = null;
    }
    if (_appOpenUnit == null && _appOpen != null) {
      _appOpen!.dispose();
      _appOpen = null;
    }
    if (_rewardUnit == null && _reward != null) {
      _reward!.dispose();
      _reward = null;
    }

    _loadInterstitial();
    _loadAppOpen();
  }

  // ---------------------------------------------------------------------------
  // Interstitial — tampil saat pengguna mengganti/memutar lagu.
  // ---------------------------------------------------------------------------

  void _loadInterstitial() {
    final unit = _interstitialUnit;
    if (unit == null ||
        unit.isEmpty ||
        _interstitial != null ||
        _loadingInterstitial)
      return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint(
            'AdMob: gagal memuat interstitial. ${error.code}: ${error.message}',
          );
        },
      ),
    );
  }

  /// Panggil saat pengguna memutar lagu. Menampilkan interstitial secara
  /// berkala (tiap [_interstitialEvery] pemutaran, dengan jeda
  /// [_interstitialCooldown]).
  void maybeShowInterstitial() {
    if (!_supported) return;
    if (_interstitialUnit == null || _interstitialUnit!.isEmpty) return;
    if (_fullScreenShowing) return;

    _songOpens++;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    if (_songOpens < _interstitialEvery) return;
    final DateTime now = DateTime.now();
    if (_lastInterstitial != null &&
        now.difference(_lastInterstitial!) < _interstitialCooldown) {
      return;
    }
    // Jangan menumpuk dengan iklan layar penuh lain (mis. app open) yang baru
    // saja tampil.
    if (_lastFullScreen != null &&
        now.difference(_lastFullScreen!) < _fullScreenGap) {
      return;
    }

    _songOpens = 0;
    _lastInterstitial = now;
    _lastFullScreen = now;
    _fullScreenShowing = true;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _fullScreenShowing = false;
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _fullScreenShowing = false;
        debugPrint(
          'AdMob: gagal menampilkan interstitial. ${error.code}: ${error.message}',
        );
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  // ---------------------------------------------------------------------------
  // App open — tampil saat aplikasi dibuka/dikembalikan dari background.
  // ---------------------------------------------------------------------------

  void _loadAppOpen() {
    final unit = _appOpenUnit;
    if (unit == null || unit.isEmpty || _appOpen != null || _loadingAppOpen)
      return;
    _loadingAppOpen = true;
    AppOpenAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingAppOpen = false;
          _appOpen = ad;
          if (_showAppOpenWhenReady) {
            _showAppOpenWhenReady = false;
            maybeShowAppOpen();
          }
        },
        onAdFailedToLoad: (error) {
          _loadingAppOpen = false;
          debugPrint(
            'AdMob: gagal memuat app open. ${error.code}: ${error.message}',
          );
        },
      ),
    );
  }

  /// Tampilkan app open **hanya saat cold start**, dengan jeda minimal
  /// [_appOpenCooldown] lintas sesi.
  ///
  /// Iklan ini tidak dipanggil dari lifecycle `resumed` agar tidak muncul
  /// setiap pengguna kembali ke aplikasi (melanggar kebijakan navigasi AdMob).
  Future<void> maybeShowAppOpen() async {
    if (!_supported) return;
    if (_appOpenUnit == null || _appOpenUnit!.isEmpty) return;
    if (_appOpenShownThisSession || _fullScreenShowing) return;

    final ad = _appOpen;
    if (ad == null) {
      _loadAppOpen();
      return;
    }

    final DateTime now = DateTime.now();
    final last = _lastAppOpen ?? await _readLastAppOpen();
    if (last != null && now.difference(last) < _appOpenCooldown) return;
    if (_lastFullScreen != null &&
        now.difference(_lastFullScreen!) < _fullScreenGap) {
      return;
    }

    _appOpenShownThisSession = true;
    _lastAppOpen = now;
    _lastFullScreen = now;
    _fullScreenShowing = true;
    _appOpen = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _fullScreenShowing = false;
        ad.dispose();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _fullScreenShowing = false;
        debugPrint(
          'AdMob: gagal menampilkan app open. ${error.code}: ${error.message}',
        );
        ad.dispose();
        _loadAppOpen();
      },
    );
    ad.show();
    _persistLastAppOpen(_lastAppOpen!);
  }

  Future<DateTime?> _readLastAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_prefLastAppOpen);
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  void _persistLastAppOpen(DateTime t) {
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_prefLastAppOpen, t.millisecondsSinceEpoch))
        .catchError((Object _) => false);
  }

  // ---------------------------------------------------------------------------
  // Reward — ditampilkan atas aksi pengguna.
  // ---------------------------------------------------------------------------

  /// True bila ada Ad Unit reward yang dikonfigurasi.
  bool get hasReward => _rewardUnit != null && _rewardUnit!.isNotEmpty;

  /// Muat (bila perlu) lalu tampilkan iklan reward. [onReward] dipanggil bila
  /// pengguna menonton sampai selesai.
  Future<void> showReward({VoidCallback? onReward}) async {
    if (!_supported) return;
    final unit = _rewardUnit;
    if (unit == null || unit.isEmpty) return;
    if (_fullScreenShowing) return;

    final loaded = _reward;
    if (loaded != null) {
      _presentReward(loaded, onReward);
      return;
    }
    if (_loadingReward) return;

    _loadingReward = true;
    RewardedAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingReward = false;
          _presentReward(ad, onReward);
        },
        onAdFailedToLoad: (error) {
          _loadingReward = false;
          debugPrint(
            'AdMob: gagal memuat reward. ${error.code}: ${error.message}',
          );
        },
      ),
    );
  }

  void _presentReward(RewardedAd ad, VoidCallback? onReward) {
    _reward = null;
    var earned = false;
    _fullScreenShowing = true;
    _lastFullScreen = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _fullScreenShowing = false;
        ad.dispose();
        if (earned) onReward?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _fullScreenShowing = false;
        debugPrint(
          'AdMob: gagal menampilkan reward. ${error.code}: ${error.message}',
        );
        ad.dispose();
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
      },
    );
  }
}

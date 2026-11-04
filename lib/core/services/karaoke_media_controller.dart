import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Pembungkus `media_kit` untuk pemutaran video karaoke.
///
/// Satu `Player` menangani video sekaligus audio sehingga kontrol pitch
/// (naik/turun nada) tidak memerlukan sinkronisasi dua pemutar terpisah.
class KaraokeMediaController {
  /// Nilai pitch maksimum/minimum dalam semitone.
  static const int minSemitone = -6;
  static const int maxSemitone = 6;

  /// Rentang tempo relatif (1.0 = tempo asli).
  static const double minRate = 0.75;
  static const double maxRate = 1.25;
  static const double rateStep = 0.05;

  final bool isTestMode;

  Player? _player;
  VideoController? _videoController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<bool> playingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> bufferingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> audioOnlyNotifier = ValueNotifier<bool>(false);

  String? _videoUrl;
  String? _audioUrl;
  bool _usingAudioOnly = false;
  bool _audioFallbackTried = false;
  bool _completionHandled = false;
  bool _disposed = false;

  int _pitchSemitones = 0;
  double _rate = 1.0;
  double _volume = 0.8;
  Duration _duration = Duration.zero;

  VoidCallback? onCompleted;
  ValueChanged<String>? onError;
  ValueChanged<bool>? onPlayingChanged;
  ValueChanged<bool>? onBufferingChanged;
  ValueChanged<Duration>? onDurationChanged;
  VoidCallback? onSourceChanged;

  KaraokeMediaController({this.isTestMode = false});

  /// Faktor pitch untuk sejumlah semitone (mis. +12 = 2.0).
  static double pitchFactorForSemitones(int semitones) =>
      math.pow(2, semitones / 12).toDouble();

  /// Membatasi tempo ke rentang yang didukung pemutar.
  static double clampRate(double rate) =>
      rate.clamp(minRate, maxRate).toDouble();

  /// Label level tempo: `1` untuk tempo asli (1.00x), angka negatif untuk
  /// tempo lebih lambat, dan angka positif untuk tempo lebih cepat.
  static String tempoLevelLabelForRate(double rate) {
    final steps = ((clampRate(rate) - 1.0) / rateStep).round();
    if (steps == 0) return '1';
    if (steps < 0) return '$steps';
    return '${steps + 1}';
  }

  VideoController? get videoController => _videoController;
  bool get isReady => _player != null && _videoController != null;
  bool get isAudioOnly => _usingAudioOnly;
  int get pitchSemitones => _pitchSemitones;
  double get rate => _rate;
  Duration get duration => _duration;
  String? get currentUrl => _usingAudioOnly ? _audioUrl : _videoUrl;

  void _ensureInitialized() {
    if (isTestMode || _player != null) return;
    _player = Player(
      configuration: const PlayerConfiguration(
        title: 'Nyanyian Rohani Methodist',
        pitch: true,
        logLevel: MPVLogLevel.error,
      ),
    );
    _videoController = VideoController(_player!);
    _attachListeners();
  }

  double? _videoWidth;
  double? _videoHeight;

  double? get videoAspectRatio {
    final width = _videoWidth;
    final height = _videoHeight;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return (width / height).clamp(0.5, 3.0).toDouble();
  }

  void _attachListeners() {
    final player = _player;
    if (player == null) return;

    _subscriptions.add(
      player.stream.width.listen((value) {
        if (_disposed || value == null || value <= 0) return;
        final width = value.toDouble();
        if (width == _videoWidth) return;
        _videoWidth = width;
        onSourceChanged?.call();
      }),
    );

    _subscriptions.add(
      player.stream.height.listen((value) {
        if (_disposed || value == null || value <= 0) return;
        final height = value.toDouble();
        if (height == _videoHeight) return;
        _videoHeight = height;
        onSourceChanged?.call();
      }),
    );

    _subscriptions.add(
      player.stream.position.listen((value) {
        if (_disposed) return;
        positionNotifier.value = value;
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((value) {
        if (_disposed || value <= Duration.zero || value == _duration) return;
        _duration = value;
        onDurationChanged?.call(value);
      }),
    );

    _subscriptions.add(
      player.stream.playing.listen((value) {
        if (_disposed) return;
        playingNotifier.value = value;
        onPlayingChanged?.call(value);
      }),
    );

    _subscriptions.add(
      player.stream.buffering.listen((value) {
        if (_disposed) return;
        bufferingNotifier.value = value;
        onBufferingChanged?.call(value);
      }),
    );

    _subscriptions.add(
      player.stream.completed.listen((value) {
        if (_disposed || !value || _completionHandled) return;
        _completionHandled = true;
        onCompleted?.call();
      }),
    );

    _subscriptions.add(
      player.stream.error.listen((message) {
        if (_disposed) return;
        _handlePlaybackError(message);
      }),
    );
  }

  /// Memuat media. [videoUrl] diprioritaskan; [audioUrl] dipakai sebagai
  /// fallback bila video gagal diputar.
  Future<bool> load({
    String? videoUrl,
    String? audioUrl,
    bool autoPlay = true,
  }) async {
    if (isTestMode) return false;
    _ensureInitialized();
    final player = _player;
    if (player == null) return false;

    final resolvedVideo = (videoUrl ?? '').trim().isEmpty
        ? null
        : videoUrl!.trim();
    final resolvedAudio = (audioUrl ?? '').trim().isEmpty
        ? null
        : audioUrl!.trim();
    final source = resolvedVideo ?? resolvedAudio;
    if (source == null) return false;

    _videoUrl = resolvedVideo;
    _audioUrl = resolvedAudio;
    _usingAudioOnly = resolvedVideo == null;
    audioOnlyNotifier.value = _usingAudioOnly;
    _audioFallbackTried = false;
    _completionHandled = false;
    _duration = Duration.zero;
    _pitchSemitones = 0;
    _rate = 1.0;
    positionNotifier.value = Duration.zero;
    bufferingNotifier.value = true;

    try {
      await player.open(Media(source), play: false);
      bufferingNotifier.value = false;
      await player.setVolume(_volume * 100);
      await _applyPlaybackTuning();
      if (autoPlay) {
        await player.play();
      }
      onSourceChanged?.call();
      return true;
    } catch (error) {
      return _handleLoadFailure(error.toString());
    }
  }

  Future<bool> _handleLoadFailure(String message) async {
    if (!_usingAudioOnly && !_audioFallbackTried && _audioUrl != null) {
      _audioFallbackTried = true;
      _usingAudioOnly = true;
      audioOnlyNotifier.value = true;
      _completionHandled = false;
      _duration = Duration.zero;
      positionNotifier.value = Duration.zero;
      bufferingNotifier.value = true;
      try {
        await _player?.open(Media(_audioUrl!), play: true);
        bufferingNotifier.value = false;
        await _player?.setVolume(_volume * 100);
        await _applyPlaybackTuning();
        onSourceChanged?.call();
        return true;
      } catch (error) {
        bufferingNotifier.value = false;
        onError?.call(error.toString());
        return false;
      }
    }
    bufferingNotifier.value = false;
    onError?.call(message);
    return false;
  }

  void _handlePlaybackError(String message) {
    if (_disposed || message.trim().isEmpty) return;
    // Coba sekali beralih ke audio sebelum menampilkan error ke pengguna.
    if (!_usingAudioOnly && !_audioFallbackTried && _audioUrl != null) {
      _audioFallbackTried = true;
      unawaited(_switchToAudioFallback());
      return;
    }
    onError?.call(message);
  }

  Future<void> _switchToAudioFallback() async {
    _usingAudioOnly = true;
    audioOnlyNotifier.value = true;
    _completionHandled = false;
    _duration = Duration.zero;
    positionNotifier.value = Duration.zero;
    bufferingNotifier.value = true;
    try {
      await _player?.open(Media(_audioUrl!), play: true);
      bufferingNotifier.value = false;
      await _player?.setVolume(_volume * 100);
      await _applyPlaybackTuning();
      onSourceChanged?.call();
    } catch (error) {
      bufferingNotifier.value = false;
      onError?.call(error.toString());
    }
  }

  Future<void> play() async {
    if (isTestMode) return;
    await _player?.play();
  }

  Future<void> pause() async {
    if (isTestMode) return;
    await _player?.pause();
  }

  Future<void> toggle() async {
    if (isTestMode) return;
    await _player?.playOrPause();
  }

  Future<void> seek(Duration position) async {
    if (isTestMode) return;
    positionNotifier.value = position;
    await _player?.seek(position);
  }

  Future<void> stop() async {
    if (isTestMode) return;
    _completionHandled = true;
    await _player?.pause();
    await _player?.seek(Duration.zero);
    positionNotifier.value = Duration.zero;
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (isTestMode) return;
    await _player?.setVolume(_volume * 100);
  }

  Future<void> setPitchSemitones(int semitones) async {
    final clamped = semitones.clamp(minSemitone, maxSemitone);
    if (clamped == _pitchSemitones) return;
    _pitchSemitones = clamped;
    if (isTestMode) return;
    await _applyPlaybackTuning();
  }

  Future<void> setRate(double rate) async {
    final clamped = clampRate(rate);
    if ((clamped - _rate).abs() < 0.0001) return;
    _rate = clamped;
    if (isTestMode) return;
    await _applyPlaybackTuning();
  }

  /// Menerapkan tempo dan pitch secara berurutan.
  ///
  /// `media_kit` menyimpan tempo di filter `scaletempo`; memanggil `setPitch`
  /// setelah `setRate` membuat keduanya dihitung ulang dari nilai terbaru.
  Future<void> _applyPlaybackTuning() async {
    final player = _player;
    if (player == null) return;
    final factor = pitchFactorForSemitones(_pitchSemitones);
    try {
      await player.setRate(_rate);
      await player.setPitch(factor);
    } catch (_) {
      // Pitch/tempo tidak tersedia pada backend tertentu; playback tetap jalan.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    onCompleted = null;
    onError = null;
    onPlayingChanged = null;
    onBufferingChanged = null;
    onDurationChanged = null;
    onSourceChanged = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    positionNotifier.dispose();
    playingNotifier.dispose();
    bufferingNotifier.dispose();
    audioOnlyNotifier.dispose();
    await _player?.dispose();
    _player = null;
    _videoController = null;
  }
}

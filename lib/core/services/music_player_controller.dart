import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import 'karaoke_media_controller.dart';

/// Pemutar audio khusus menu Musik.
///
/// Berbeda dengan `KaraokeMediaController`, kelas ini tidak membuat
/// `VideoController` karena menu Musik hanya membutuhkan kontrol audio.
class MusicPlayerController {
  MusicPlayerController({this.isTestMode = false});

  final bool isTestMode;

  Player? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _disposed = false;
  bool _completionHandled = false;
  double _volume = 0.8;

  int _pitchSemitones = 0;
  double _rate = 1.0;

  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<bool> playingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> bufferingNotifier = ValueNotifier<bool>(false);

  VoidCallback? onCompleted;
  ValueChanged<String>? onError;
  ValueChanged<bool>? onPlayingChanged;
  ValueChanged<Duration>? onDurationChanged;

  bool get isReady => isTestMode || _player != null;
  Duration get position => positionNotifier.value;
  Duration get duration => durationNotifier.value;
  bool get isPlaying => playingNotifier.value;
  int get pitchSemitones => _pitchSemitones;
  double get rate => _rate;

  void _ensureInitialized() {
    if (isTestMode || _player != null) return;

    _player = Player(
      configuration: const PlayerConfiguration(
        title: 'Musik NRM',
        pitch: true,
        logLevel: MPVLogLevel.error,
      ),
    );

    final player = _player!;

    _subscriptions.add(
      player.stream.position.listen((value) {
        if (!_disposed) positionNotifier.value = value;
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((value) {
        if (_disposed || value <= Duration.zero) return;
        if (value == durationNotifier.value) return;
        durationNotifier.value = value;
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
        if (!_disposed) bufferingNotifier.value = value;
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
        onError?.call(message);
      }),
    );
  }

  /// Muat URL streaming dan mulai pemutaran.
  Future<bool> load(String url, {bool autoPlay = true}) async {
    if (isTestMode) {
      _pitchSemitones = 0;
      _rate = 1.0;
      positionNotifier.value = Duration.zero;
      durationNotifier.value = Duration.zero;
      playingNotifier.value = autoPlay;
      onPlayingChanged?.call(autoPlay);
      return true;
    }

    _ensureInitialized();
    final player = _player;
    if (player == null) return false;

    _completionHandled = false;
    _pitchSemitones = 0;
    _rate = 1.0;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;

    try {
      await player.open(Media(url), play: autoPlay);
      await player.setVolume(_volume * 100);
      await _applyPlaybackTuning();
      return true;
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }
  }

  Future<void> play() async {
    if (isTestMode) {
      playingNotifier.value = true;
      onPlayingChanged?.call(true);
      return;
    }
    await _player?.play();
  }

  Future<void> pause() async {
    if (isTestMode) {
      playingNotifier.value = false;
      onPlayingChanged?.call(false);
      return;
    }
    await _player?.pause();
  }

  Future<void> seek(Duration position) async {
    if (isTestMode) {
      positionNotifier.value = position;
      return;
    }
    await _player?.seek(position);
  }

  Future<void> stop() async {
    _completionHandled = false;
    if (isTestMode) {
      playingNotifier.value = false;
      positionNotifier.value = Duration.zero;
      onPlayingChanged?.call(false);
      return;
    }
    await _player?.stop();
    if (!_disposed) {
      positionNotifier.value = Duration.zero;
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0).toDouble();
    if (isTestMode) return;
    await _player?.setVolume(_volume * 100);
  }

  Future<void> setPitchSemitones(int semitones) async {
    final clamped = semitones.clamp(
      KaraokeMediaController.minSemitone,
      KaraokeMediaController.maxSemitone,
    );
    if (clamped == _pitchSemitones) return;
    _pitchSemitones = clamped;
    if (isTestMode) return;
    await _applyPlaybackTuning();
  }

  Future<void> setRate(double rate) async {
    final clamped = KaraokeMediaController.clampRate(rate);
    if ((clamped - _rate).abs() < 0.0001) return;
    _rate = clamped;
    if (isTestMode) return;
    await _applyPlaybackTuning();
  }

  /// Menerapkan tempo lalu pitch agar kedua nilai dihitung ulang dari state
  /// terbaru oleh `media_kit`.
  Future<void> _applyPlaybackTuning() async {
    final player = _player;
    if (player == null) return;
    final factor = KaraokeMediaController.pitchFactorForSemitones(
      _pitchSemitones,
    );
    try {
      await player.setRate(_rate);
      await player.setPitch(factor);
    } catch (_) {
      // Pitch/tempo tidak tersedia pada backend tertentu; playback tetap jalan.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _player?.dispose();
    _player = null;
    positionNotifier.dispose();
    durationNotifier.dispose();
    playingNotifier.dispose();
    bufferingNotifier.dispose();
  }
}

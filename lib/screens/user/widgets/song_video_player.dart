import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;

import '../../../core/services/karaoke_media_controller.dart';
import '../../../core/theme/app_colors.dart';

/// Pemutar video karaoke berbasis `media_kit`.
///
/// Video ditampilkan tanpa kontrol bawaan; kontrol utama ada di
/// [PlayerControls]. Saat fullscreen, overlay kontrol ringkas ditampilkan di
/// dalam rute fullscreen milik `media_kit`.
class SongVideoPlayer extends StatelessWidget {
  final KaraokeMediaController controller;
  final GlobalKey<media_kit_video.VideoState>? videoKey;
  final String songTitle;
  final String songSinger;
  final String? thumbnailUrl;
  final bool isPlaying;
  final bool isCasting;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onTogglePlayback;
  final ValueChanged<bool>? onFullscreenChanged;

  const SongVideoPlayer({
    super.key,
    required this.controller,
    this.videoKey,
    required this.songTitle,
    required this.songSinger,
    this.thumbnailUrl,
    this.isPlaying = false,
    this.isCasting = false,
    this.errorMessage,
    this.onRetry,
    this.onTogglePlayback,
    this.onFullscreenChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _buildMessageStage(
        icon: Icons.error_outline_rounded,
        title: 'Video tidak dapat diputar',
        subtitle: errorMessage!,
        action: onRetry == null
            ? null
            : TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
              ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: controller.audioOnlyNotifier,
      builder: (context, audioOnly, _) {
        final videoController = controller.videoController;
        if (videoController == null || audioOnly) {
          return _buildAudioStage();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            media_kit_video.Video(
              key: videoKey,
              controller: videoController,
              controls: _buildControls,
              fit: BoxFit.contain,
              fill: Colors.black,
              wakelock: false,
              pauseUponEnteringBackgroundMode: true,
              onEnterFullscreen: () => _setFullscreen(context, true),
              onExitFullscreen: () => _setFullscreen(context, false),
            ),
            _buildTapLayer(context),
            _buildBufferingLayer(),
          ],
        );
      },
    );
  }

  Widget _buildControls(media_kit_video.VideoState state) {
    final fullscreen = media_kit_video.isFullscreen(state.context);
    if (!fullscreen) return const SizedBox.shrink();
    return _FullscreenControls(
      controller: controller,
      songTitle: songTitle,
      songSinger: songSinger,
      onTogglePlayback: onTogglePlayback ?? controller.toggle,
      onExit: () => state.exitFullscreen(),
    );
  }

  Future<void> _setFullscreen(BuildContext context, bool fullscreen) async {
    onFullscreenChanged?.call(fullscreen);
    if (fullscreen) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Widget _buildTapLayer(BuildContext context) {
    if (isCasting) {
      return Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTogglePlayback,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentCyan),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cast_connected_rounded,
                      color: AppColors.accentCyan,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Diputar di TV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTogglePlayback ?? controller.toggle,
        child: ValueListenableBuilder<bool>(
          valueListenable: controller.playingNotifier,
          builder: (context, playing, _) {
            return AnimatedOpacity(
              opacity: playing ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBufferingLayer() {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.bufferingNotifier,
      builder: (context, buffering, _) {
        if (!buffering) return const SizedBox.shrink();
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accentCyan,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioStage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
          Image.network(
            thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackBackground(),
          )
        else
          _buildFallbackBackground(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        Center(
          child: isCasting
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.accentCyan),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cast_connected_rounded,
                        color: AppColors.accentCyan,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Diputar di TV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: controller.playingNotifier,
                  builder: (context, playing, _) {
                    return InkWell(
                      onTap: onTogglePlayback ?? controller.toggle,
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryElectric.withValues(
                            alpha: 0.85,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              const Icon(
                Icons.audiotrack_rounded,
                color: AppColors.accentSky,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$songTitle - $songSinger',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Icon(
          Icons.music_video_rounded,
          size: 60,
          color: AppColors.accentCyan.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildMessageStage({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.accentLight),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}

class _FullscreenControls extends StatefulWidget {
  final KaraokeMediaController controller;
  final String songTitle;
  final String songSinger;
  final VoidCallback onTogglePlayback;
  final VoidCallback onExit;

  const _FullscreenControls({
    required this.controller,
    required this.songTitle,
    required this.songSinger,
    required this.onTogglePlayback,
    required this.onExit,
  });

  @override
  State<_FullscreenControls> createState() => _FullscreenControlsState();
}

class _FullscreenControlsState extends State<_FullscreenControls> {
  bool _dragging = false;
  double _dragValue = 0;

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.65),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.songTitle} - ${widget.songSinger}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onExit,
                    tooltip: 'Keluar layar penuh',
                    icon: const Icon(
                      Icons.fullscreen_exit_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.controller.playingNotifier,
                    builder: (context, playing, _) {
                      return IconButton(
                        onPressed: widget.onTogglePlayback,
                        iconSize: 42,
                        tooltip: playing ? 'Jeda' : 'Putar',
                        icon: Icon(
                          playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: ValueListenableBuilder<Duration>(
                valueListenable: widget.controller.positionNotifier,
                builder: (context, position, _) {
                  final duration = widget.controller.duration;
                  final maxSeconds = duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0;
                  final value = _dragging
                      ? _dragValue.clamp(0.0, maxSeconds)
                      : position.inMilliseconds
                            .clamp(0, maxSeconds.toInt())
                            .toDouble();

                  return Row(
                    children: [
                      Text(
                        _format(
                          _dragging
                              ? Duration(milliseconds: _dragValue.toInt())
                              : position,
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: value,
                          min: 0,
                          max: maxSeconds,
                          onChangeStart: (v) {
                            setState(() {
                              _dragging = true;
                              _dragValue = v;
                            });
                          },
                          onChanged: (v) {
                            setState(() => _dragValue = v);
                          },
                          onChangeEnd: (v) {
                            setState(() => _dragging = false);
                            widget.controller.seek(
                              Duration(milliseconds: v.toInt()),
                            );
                          },
                        ),
                      ),
                      Text(
                        _format(duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

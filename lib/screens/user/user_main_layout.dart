import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/services/api_auth_service.dart';
import '../../core/services/api_category_service.dart';
import '../../core/services/api_song_service.dart';
import '../../core/services/category_service.dart';
import '../../core/services/karaoke_media_controller.dart';
import '../../core/services/song_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/application_service.dart';
import '../../core/services/api_application_service.dart';
import '../../models/application_model.dart';
import '../../services/ad_manager.dart';
import '../../widgets/ad_popup.dart';
import '../../widgets/ad_slot_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/lyric_parser.dart';
import '../../core/utils/media_url_helper.dart';
import '../../core/utils/youtube_helper.dart';
import '../../models/category_model.dart';
import '../../models/display_mode.dart';
import '../../models/song_model.dart';
import '../../models/user_model.dart';
import '../login_screen.dart';
import '../../services/cast/cast_device_model.dart';
import '../../services/cast/smart_tv_cast_service.dart';
import 'widgets/cast_device_modal.dart';
import 'widgets/lyrics_display.dart';
import 'widgets/playback_tuning_sheet.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_display.dart';
import 'widgets/song_catalog_playlist_section.dart';
import 'widgets/song_search_modal.dart';
import 'widgets/song_search_panel.dart';
import 'widgets/text_only_controls.dart';

class UserMainLayout extends StatefulWidget {
  final SongService? songService;
  final CategoryService? categoryService;
  final SmartTvCastService? castService;
  final ApplicationService? applicationService;
  final bool isTestMode;
  final int? initialCategoryFilter;
  final DisplayMode initialDisplayMode;

  const UserMainLayout({
    super.key,
    this.songService,
    this.categoryService,
    this.castService,
    this.applicationService,
    this.isTestMode = false,
    this.initialCategoryFilter,
    this.initialDisplayMode = DisplayMode.normal,
  });

  @override
  State<UserMainLayout> createState() => _UserMainLayoutState();
}

class _UserMainLayoutState extends State<UserMainLayout>
    with WidgetsBindingObserver {
  late final SongService _songService;
  late final CategoryService _categoryService;
  late final SmartTvCastService _castService;
  late final ApplicationService _applicationService;
  StreamSubscription? _castSubscription;

  ApplicationModel? _appConfig;
  bool _pageAdShown = false;

  // Slot iklan atas/bawah yang sudah ditutup pengguna pada sesi ini.
  bool _topAdClosed = false;
  bool _bottomAdClosed = false;

  UserModel? _currentUser;
  List<SongModel> _allSongs = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  /// Filter awal yang sudah divalidasi terhadap kategori aktif.
  int? _initialCategoryFilter;

  bool get _isTextOnly => widget.initialDisplayMode == DisplayMode.textOnly;

  /// Slot iklan atas: halaman musik memakai slot 1, halaman lirik memakai slot
  /// khusus lirik agar pengaturannya terpisah di panel admin website.
  AdSlotConfig? get _topAdConfig {
    final config = _appConfig;
    if (config == null) return null;
    return _isTextOnly ? config.adsLyricTopConfig : config.ads1Config;
  }

  bool get _topAdActive {
    final config = _appConfig;
    if (config == null) return false;
    return _isTextOnly ? config.isAdsLyricTopActive : config.isAds1Active;
  }

  /// Slot iklan bawah: halaman musik memakai footer biasa, halaman lirik
  /// memakai slot khusus lirik.
  AdSlotConfig? get _bottomAdConfig {
    final config = _appConfig;
    if (config == null) return null;
    return _isTextOnly ? config.adsLyricBottomConfig : config.adsBottomConfig;
  }

  bool get _bottomAdActive {
    final config = _appConfig;
    if (config == null) return false;
    return _isTextOnly
        ? config.isAdsLyricBottomActive
        : config.isAdsBottomActive;
  }

  List<LyricVerse> get _currentVerses =>
      LyricParser.parse(_currentSong?.songlyric);

  // Playback state
  SongModel? _currentSong;
  bool _isPlaying = false;
  int _currentVerseIndex = 0;
  Duration _currentPosition = Duration.zero;
  final ValueNotifier<Duration> _currentPositionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  Duration _totalDuration = const Duration(minutes: 3, seconds: 30);
  Timer? _playbackTimer;

  // Pemutar media tersimpan (video MP4 + nada/tempo) dan fallback YouTube.
  late final KaraokeMediaController _mediaController;
  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();
  bool _isMediaActive = false;
  String? _mediaError;
  int _pitchSemitones = 0;
  double _tempoRate = 1.0;

  // Status cast: pemutar lokal dijeda selama TV aktif, lalu dilanjutkan lagi.
  Timer? _castPositionTimer;
  bool _castWasConnected = false;

  bool get _isCasting => _castService.connectedDevice != null;

  void _updateCurrentPosition(Duration position) {
    _currentPosition = position;
    _currentPositionNotifier.value = position;
  }

  void _handleMediaPosition() {
    if (!mounted) return;
    _updateCurrentPosition(_mediaController.positionNotifier.value);
  }

  void _handleMediaPlayingChanged(bool playing) {
    if (!mounted || _isCasting || !_isMediaActive || playing == _isPlaying) {
      return;
    }
    final isRecentManualAction =
        _lastManualActionTime != null &&
        DateTime.now().difference(_lastManualActionTime!).inMilliseconds < 600;
    if (isRecentManualAction && playing != _isPlaying) return;
    setState(() => _isPlaying = playing);
  }

  void _handleMediaDurationChanged(Duration duration) {
    if (!mounted || duration <= Duration.zero || duration == _totalDuration) {
      return;
    }
    setState(() => _totalDuration = duration);
  }

  void _handleMediaError(String message) {
    if (!mounted) return;
    setState(() {
      _mediaError = message;
      if (!_isCasting) {
        _isPlaying = false;
      }
    });
  }

  void _handleMediaSourceChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleCastConnectionChanged(CastDevice? device) {
    if (!mounted) return;

    final wasConnected = _castWasConnected;
    _castWasConnected = device != null;

    if (!wasConnected && device != null) {
      _pauseLocalForCast();
      if (_isPlaying && _currentSong != null) {
        _startCastPositionTimer();
      }
    } else if (wasConnected && device == null) {
      _stopCastPositionTimer();
      if (_isPlaying && _currentSong != null) {
        _resumeLocalPlayback();
      }
    }

    setState(() {});
  }

  void _pauseLocalForCast() {
    if (_isMediaActive) {
      unawaited(_mediaController.pause());
    } else {
      try {
        _youtubeController?.pauseVideo();
      } catch (_) {}
    }
  }

  void _resumeLocalPlayback() {
    if (_isMediaActive) {
      unawaited(_mediaController.seek(_currentPosition));
      unawaited(_mediaController.play());
    } else {
      try {
        _youtubeController?.seekTo(
          seconds: _currentPosition.inSeconds.toDouble(),
          allowSeekAhead: true,
        );
        _youtubeController?.playVideo();
      } catch (_) {}
    }
  }

  void _startCastPositionTimer() {
    _stopCastPositionTimer();
    if (!_isCasting) return;

    _castPositionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCasting || !_isPlaying || _currentSong == null) {
        return;
      }

      final next = _currentPosition + const Duration(seconds: 1);
      if (_totalDuration > Duration.zero && next >= _totalDuration) {
        _updateCurrentPosition(_totalDuration);
        timer.cancel();
        _onSongFinished();
      } else {
        _updateCurrentPosition(next);
      }
    });
  }

  void _stopCastPositionTimer() {
    _castPositionTimer?.cancel();
    _castPositionTimer = null;
  }

  Future<void> _castSong(
    SongModel song, {
    String? videoUrl,
    String? videoId,
  }) async {
    if (!_isCasting) return;

    final thumbnailUrl = videoId != null
        ? YoutubeHelper.getThumbnailUrl(videoId)
        : null;

    if (videoUrl != null && videoUrl.isNotEmpty) {
      final direct = await _castService.castDirectVideo(
        videoUrl,
        title: song.songtitle,
        artist: song.songsinger,
        thumbnailUrl: thumbnailUrl,
      );
      if (direct) return;
    }

    if (videoId != null && videoId.isNotEmpty) {
      await _castService.castVideo(
        videoId,
        title: song.songtitle,
        artist: song.songsinger,
        thumbnailUrl: thumbnailUrl,
      );
    }
  }

  // Audio & Display Settings
  double _volume = 0.8;
  bool _isMuted = false;
  bool _isFullscreen = false;
  DateTime? _lastManualActionTime;
  final List<SongModel> _queue = [];

  // YouTube Player Controller
  final GlobalKey _playerDisplayKey = GlobalKey();
  YoutubePlayerController? _youtubeController;
  StreamSubscription? _youtubePlayerSubscription;
  StreamSubscription<YoutubeVideoState>? _videoStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _songService = widget.songService ?? ApiSongService();
    _categoryService = widget.categoryService ?? ApiCategoryService();
    _castService =
        widget.castService ?? SmartTvCastService(isTestMode: widget.isTestMode);
    _applicationService = widget.applicationService ?? ApiApplicationService();
    _initialCategoryFilter = widget.initialCategoryFilter;
    _mediaController = KaraokeMediaController(isTestMode: widget.isTestMode)
      ..onCompleted = _onSongFinished
      ..onPlayingChanged = _handleMediaPlayingChanged
      ..onDurationChanged = _handleMediaDurationChanged
      ..onError = _handleMediaError
      ..onSourceChanged = _handleMediaSourceChanged;
    _mediaController.positionNotifier.addListener(_handleMediaPosition);
    _castWasConnected = _castService.connectedDevice != null;
    _castSubscription = _castService.connectedDeviceStream.listen(
      _handleCastConnectionChanged,
    );
    _loadData();
  }

  void _createYoutubeController(String videoId, {bool autoPlay = true}) {
    if (widget.isTestMode) return;
    try {
      _youtubePlayerSubscription?.cancel();
      _videoStateSubscription?.cancel();
      if (_youtubeController != null) {
        try {
          _youtubeController?.stopVideo();
        } catch (_) {}
        _youtubeController?.close();
      }

      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: autoPlay,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          showVideoAnnotations: false,
          pointerEvents: PointerEvents.auto,
          mute: false,
          enableCaption: true,
          captionLanguage: 'id',
          interfaceLanguage: 'id',
          videoStateUpdateInterval: 250,
        ),
      );

      // Sinkronisasi posisi real-time dari video YouTube secara terisolasi tanpa memicu root setState
      _videoStateSubscription = _youtubeController!.videoStateStream.listen((
        state,
      ) {
        if (!mounted) return;
        _updateCurrentPosition(state.position);
      });

      _youtubePlayerSubscription = _youtubeController!.listen((value) {
        if (!mounted) return;

        // Cegah race condition: jangan menimpa status pemutaran jika baru saja ada aksi manual user (<800ms)
        final isRecentManualAction =
            _lastManualActionTime != null &&
            DateTime.now().difference(_lastManualActionTime!).inMilliseconds <
                800;

        if (!_isCasting && !isRecentManualAction) {
          if (value.playerState == PlayerState.playing && !_isPlaying) {
            setState(() {
              _isPlaying = true;
            });
          } else if (value.playerState == PlayerState.paused && _isPlaying) {
            setState(() {
              _isPlaying = false;
            });
          }
        }

        // Sinkronisasi status fullscreen jika controller berubah
        if (_isFullscreen != value.fullScreenOption.enabled) {
          setState(() {
            _isFullscreen = value.fullScreenOption.enabled;
          });
        }

        // Sinkronisasi total durasi video YouTube jika terdeteksi
        if (value.metaData.duration > Duration.zero &&
            _totalDuration != value.metaData.duration) {
          setState(() {
            _totalDuration = value.metaData.duration;
          });
        }

        // Otomatis putar lagu berikutnya jika video selesai
        if (value.playerState == PlayerState.ended) {
          _onSongFinished();
        }
      });
    } catch (_) {
      _youtubeController = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _castSubscription?.cancel();
    if (widget.castService == null) {
      _castService.dispose();
    }
    _youtubePlayerSubscription?.cancel();
    _videoStateSubscription?.cancel();
    try {
      _youtubeController?.stopVideo();
    } catch (_) {}
    _youtubeController?.close();
    _mediaController.positionNotifier.removeListener(_handleMediaPosition);
    _mediaController.dispose();
    _stopCastPositionTimer();
    _stopPlaybackTimer();
    _currentPositionNotifier.dispose();
    super.dispose();
  }

  /// Muat ulang konfigurasi iklan saat aplikasi kembali ke foreground agar
  /// perubahan status slot dari panel admin website langsung diterapkan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAppConfig();
    }
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    // Hanya gunakan timer manual jika dalam mode pengujian
    if (!widget.isTestMode) return;
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isPlaying || _currentSong == null) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentPosition.inSeconds < _totalDuration.inSeconds) {
          _updateCurrentPosition(_currentPosition + const Duration(seconds: 1));
        } else {
          timer.cancel();
          _onSongFinished();
        }
      });
    });
  }

  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  void _onSongFinished() {
    _stopCastPositionTimer();
    if (_queue.isNotEmpty) {
      final nextSong = _queue.removeAt(0);
      _playSong(nextSong);
    } else {
      _stopPlaybackTimer();
      if (_isCasting) {
        unawaited(_castService.pause());
      }
      _updateCurrentPosition(Duration.zero);
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Duration _parseSongDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) {
      return const Duration(minutes: 3, seconds: 30);
    }
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 3;
      final s = int.tryParse(parts[1]) ?? 30;
      return Duration(minutes: m, seconds: s);
    }
    return const Duration(minutes: 3, seconds: 30);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final storage = await StorageService.getInstance();
      final user = await storage.getUser();

      var categoryLoadFailed = false;
      var songLoadFailed = false;

      final results = await Future.wait([
        _categoryService.getCategories().catchError((e) {
          debugPrint('User layout category load error: $e');
          categoryLoadFailed = true;
          return <CategoryModel>[];
        }),
        _songService.getSongs().catchError((e) {
          debugPrint('User layout song load error: $e');
          songLoadFailed = true;
          return <SongModel>[];
        }),
      ]);

      final allCategories = results[0] as List<CategoryModel>;
      final songs = results[1] as List<SongModel>;
      final activeCategories = allCategories
          .where((category) => category.isActive)
          .toList();
      final activeCategoryIds = activeCategories
          .map((category) => category.songcategoryid)
          .toSet();

      if (mounted) {
        setState(() {
          _currentUser = user;

          if (!categoryLoadFailed) {
            _categories = activeCategories;

            // Lagu dari kategori nonaktif ikut disembunyikan dari katalog,
            // pencarian, dan navigasi next/previous.
            final visibleSongs = songLoadFailed
                ? _allSongs
                      .where(
                        (song) => activeCategoryIds.contains(song.songcategory),
                      )
                      .toList()
                : songs
                      .where(
                        (song) => activeCategoryIds.contains(song.songcategory),
                      )
                      .toList();
            _allSongs = visibleSongs;

            final requestedCategory = _initialCategoryFilter;
            if (requestedCategory != null &&
                !activeCategoryIds.contains(requestedCategory)) {
              _initialCategoryFilter = null;
            }
          } else if (!songLoadFailed) {
            _allSongs = songs;
          }

          // Saat pertama kali dibuka, player dalam kondisi kosong (standby).
          // Lagu baru muncul ketika pengguna memilih lagu dari katalog.
          _currentSong = null;
          _isLoading = false;
        });
      }

      await _loadAppConfig();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAppConfig() async {
    try {
      final config = await _applicationService.getApplicationConfig();
      if (!mounted) return;
      setState(() => _appConfig = config);
      AdManager.instance.configure(config);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPageAd());
    } catch (e) {
      debugPrint('User layout app config load error: $e');
    }
  }

  /// Menampilkan pop-up iklan satu kali per layar: slot halaman lirik untuk
  /// mode teks-only, atau slot konten untuk halaman player biasa. Format
  /// full-screen ditangani AdManager.
  void _maybeShowPageAd() {
    if (_pageAdShown || !mounted) return;
    final config = _appConfig;
    if (config == null) return;

    final ad = _isTextOnly ? config.adsLyricConfig : config.ads2Config;
    final active = _isTextOnly ? config.isAdsLyricActive : config.isAds2Active;
    if (!active || !hasAdPopupContent(ad)) return;

    _pageAdShown = true;
    showAdPopup(context, ad);
  }

  void _detachYoutubePlayback() {
    _youtubePlayerSubscription?.cancel();
    _youtubePlayerSubscription = null;
    _videoStateSubscription?.cancel();
    _videoStateSubscription = null;
    try {
      _youtubeController?.stopVideo();
    } catch (_) {}
    _youtubeController?.close();
    _youtubeController = null;
  }

  void _startYoutubePlayback(String videoId, {bool autoPlay = true}) {
    if (_youtubeController != null) {
      try {
        _youtubeController!.loadVideoById(videoId: videoId, startSeconds: 0);
        _youtubeController!.seekTo(seconds: 0, allowSeekAhead: true);
        if (autoPlay) {
          _youtubeController!.playVideo();
        } else {
          _youtubeController!.pauseVideo();
        }
      } catch (_) {
        _detachYoutubePlayback();
        _createYoutubeController(videoId, autoPlay: autoPlay);
      }
    } else {
      _createYoutubeController(videoId, autoPlay: autoPlay);
    }
  }

  Future<void> _loadMedia(
    SongModel song, {
    String? videoUrl,
    String? audioUrl,
    bool autoPlay = true,
  }) async {
    _mediaError = null;
    final loaded = await _mediaController.load(
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      autoPlay: autoPlay,
    );
    if (!mounted || _currentSong?.songid != song.songid) return;
    if (!loaded) {
      setState(() {
        _mediaError = 'Media lagu tidak dapat dimuat.';
        if (!_isCasting) {
          _isPlaying = false;
        }
      });
    }
  }

  void _retryMedia() {
    final song = _currentSong;
    if (song == null) return;
    if (mounted) {
      setState(() {
        _mediaError = null;
        _isPlaying = true;
      });
    }
    final resolvedVideoUrl = MediaUrlHelper.resolve(song.songvideourl);
    unawaited(
      _loadMedia(
        song,
        videoUrl: MediaUrlHelper.isDirectVideo(resolvedVideoUrl)
            ? resolvedVideoUrl
            : null,
        audioUrl: MediaUrlHelper.resolve(song.songurl),
        autoPlay: !_isCasting,
      ),
    );
  }

  void _applyPitchSemitones(int value) {
    if (!_isMediaActive || _currentSong == null) return;
    final next = value.clamp(
      KaraokeMediaController.minSemitone,
      KaraokeMediaController.maxSemitone,
    );
    if (next == _pitchSemitones) return;
    setState(() => _pitchSemitones = next);
    unawaited(_mediaController.setPitchSemitones(next));
  }

  void _applyTempoRate(double value) {
    if (!_isMediaActive || _currentSong == null) return;
    final next = KaraokeMediaController.clampRate(value);
    if ((next - _tempoRate).abs() < 0.0001) return;
    setState(() => _tempoRate = next);
    unawaited(_mediaController.setRate(next));
  }

  void _openTuningSheet() {
    if (!_isMediaActive || _currentSong == null) return;
    PlaybackTuningSheet.show(
      context,
      pitchSemitones: _pitchSemitones,
      tempoRate: _tempoRate,
      onPitchChanged: _applyPitchSemitones,
      onTempoChanged: _applyTempoRate,
    );
  }

  void _playSong(SongModel song) {
    _lastManualActionTime = DateTime.now();
    _stopPlaybackTimer();

    final resolvedVideoUrl = MediaUrlHelper.resolve(song.songvideourl);
    final videoUrl = MediaUrlHelper.isDirectVideo(resolvedVideoUrl)
        ? resolvedVideoUrl
        : null;
    final directAudioUrl =
        MediaUrlHelper.isDirectAudio(song.songurl) ||
            MediaUrlHelper.isDirectVideo(song.songurl)
        ? MediaUrlHelper.resolve(song.songurl)
        : null;
    final useMediaKit =
        !_isTextOnly &&
        !widget.isTestMode &&
        (videoUrl != null || directAudioUrl != null);
    final videoId =
        YoutubeHelper.extractVideoId(song.songyoutubeurl) ??
        YoutubeHelper.extractVideoId(song.songurl);
    final casting = _isCasting;

    _mediaError = null;
    _pitchSemitones = 0;
    _tempoRate = 1.0;
    _stopCastPositionTimer();

    if (useMediaKit) {
      _isMediaActive = true;
      _detachYoutubePlayback();
      unawaited(
        _loadMedia(
          song,
          videoUrl: videoUrl,
          audioUrl: directAudioUrl,
          autoPlay: !casting,
        ),
      );
    } else {
      _isMediaActive = false;
      unawaited(_mediaController.stop());
      if (!_isTextOnly && videoId != null && !widget.isTestMode) {
        _startYoutubePlayback(videoId, autoPlay: !casting);
      }
    }

    setState(() {
      _currentSong = song;
      _currentVerseIndex = 0;
      _updateCurrentPosition(Duration.zero);
      _totalDuration = _isTextOnly
          ? Duration.zero
          : _parseSongDuration(song.songduration);
      _isPlaying = !_isTextOnly;
    });

    if (!_isTextOnly && casting) {
      unawaited(
        _castSong(
          song,
          videoUrl: useMediaKit ? videoUrl : null,
          videoId: videoId,
        ),
      );
      _startCastPositionTimer();
    }

    if (!_isTextOnly) {
      _startPlaybackTimer();
    }
    AdManager.instance.maybeShowInterstitial();
  }

  void _togglePlayPause() {
    if (_currentSong == null) {
      if (_allSongs.isNotEmpty) {
        _playSong(_allSongs.first);
      }
      return;
    }
    _lastManualActionTime = DateTime.now();
    final willPlay = !_isPlaying;
    setState(() {
      _isPlaying = willPlay;
    });

    if (_isCasting) {
      if (willPlay) {
        if (_totalDuration > Duration.zero &&
            _currentPosition >= _totalDuration) {
          _seek(Duration.zero);
        }
        unawaited(_castService.play());
        _startCastPositionTimer();
      } else {
        unawaited(_castService.pause());
        _stopCastPositionTimer();
      }
      return;
    }

    if (_isMediaActive) {
      if (willPlay) {
        if (_totalDuration > Duration.zero &&
            _currentPosition >= _totalDuration) {
          unawaited(_mediaController.seek(Duration.zero));
        }
        unawaited(_mediaController.play());
      } else {
        unawaited(_mediaController.pause());
      }
    } else {
      try {
        if (willPlay) {
          _youtubeController?.playVideo();
        } else {
          _youtubeController?.pauseVideo();
        }
      } catch (_) {}
    }

    if (willPlay) {
      if (_castService.connectedDevice != null) {
        _castService.play();
      }
      _startPlaybackTimer();
    } else {
      if (_castService.connectedDevice != null) {
        _castService.pause();
      }
      _stopPlaybackTimer();
    }
  }

  void _stopSong() {
    _lastManualActionTime = DateTime.now();
    _stopPlaybackTimer();
    _stopCastPositionTimer();
    if (_isMediaActive) {
      unawaited(_mediaController.stop());
    } else {
      try {
        _youtubeController?.pauseVideo();
        _youtubeController?.stopVideo();
        _youtubeController?.seekTo(seconds: 0, allowSeekAhead: true);
      } catch (_) {}
    }
    if (_castService.connectedDevice != null) {
      _castService.pause();
    }
    setState(() {
      _isPlaying = false;
      _updateCurrentPosition(Duration.zero);
    });
  }

  void _nextSong() {
    if (_queue.isNotEmpty) {
      final nextSong = _queue.removeAt(0);
      _playSong(nextSong);
    } else if (_allSongs.isNotEmpty && _currentSong != null) {
      final currentIndex = _allSongs.indexWhere(
        (s) => s.songid == _currentSong!.songid,
      );
      if (currentIndex != -1 && currentIndex + 1 < _allSongs.length) {
        _playSong(_allSongs[currentIndex + 1]);
      } else {
        _playSong(_allSongs.first);
      }
    }
  }

  void _previousSong() {
    _lastManualActionTime = DateTime.now();
    if (_currentPosition.inSeconds > 3) {
      _seek(Duration.zero);
    } else if (_allSongs.isNotEmpty && _currentSong != null) {
      final currentIndex = _allSongs.indexWhere(
        (s) => s.songid == _currentSong!.songid,
      );
      if (currentIndex > 0) {
        _playSong(_allSongs[currentIndex - 1]);
      } else {
        _seek(Duration.zero);
      }
    }
  }

  /// Pindah ke ayat berikutnya. Berhenti di ayat terakhir; tidak otomatis
  /// berpindah ke lagu berikutnya.
  void _nextVerse() {
    final verses = _currentVerses;
    if (_currentVerseIndex + 1 < verses.length) {
      setState(() {
        _currentVerseIndex++;
      });
    }
  }

  /// Pindah ke ayat sebelumnya. Berhenti di ayat pertama; tidak otomatis
  /// mundur ke lagu sebelumnya.
  void _previousVerse() {
    if (_currentVerseIndex > 0) {
      setState(() {
        _currentVerseIndex--;
      });
    }
  }

  void _seek(Duration position) {
    _lastManualActionTime = DateTime.now();
    if (_isMediaActive) {
      unawaited(_mediaController.seek(position));
    } else {
      try {
        _youtubeController?.seekTo(
          seconds: position.inSeconds.toDouble(),
          allowSeekAhead: true,
        );
      } catch (_) {}
    }
    if (_castService.connectedDevice != null) {
      _castService.seek(position);
    }
    setState(() {
      _updateCurrentPosition(position);
    });
  }

  void _toggleFullscreen() {
    if (_isMediaActive) {
      final state = _videoKey.currentState;
      if (state == null) return;
      unawaited(state.toggleFullscreen());
      return;
    }

    final nextFullscreen = !_isFullscreen;
    setState(() {
      _isFullscreen = nextFullscreen;
    });
    try {
      if (nextFullscreen) {
        _youtubeController?.enterFullScreen();
      } else {
        _youtubeController?.exitFullScreen();
      }
    } catch (_) {}
  }

  void _onVolumeChanged(double v) {
    setState(() {
      _volume = v;
      _isMuted = false;
    });
    if (_isMediaActive) {
      unawaited(_mediaController.setVolume(v));
      return;
    }
    try {
      _youtubeController?.setVolume((v * 100).toInt());
      if (v > 0) {
        _youtubeController?.unMute();
      } else {
        _youtubeController?.mute();
      }
    } catch (_) {}
  }

  void _toggleMute() {
    final nextMuted = !_isMuted;
    setState(() {
      _isMuted = nextMuted;
    });
    if (_isMediaActive) {
      unawaited(_mediaController.setVolume(nextMuted ? 0 : _volume));
      return;
    }
    try {
      if (nextMuted) {
        _youtubeController?.mute();
      } else {
        _youtubeController?.unMute();
        _youtubeController?.setVolume((_volume * 100).toInt());
      }
    } catch (_) {}
  }

  void _addToQueue(SongModel song) {
    setState(() {
      _queue.add(song);
    });
  }

  void _removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      setState(() {
        _queue.removeAt(index);
      });
    }
  }

  void _clearQueue() {
    setState(() {
      _queue.clear();
    });
  }

  void _reorderQueue(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final song = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, song);
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardGlassBorder),
        ),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari Nyanyian Rohani Methodist?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.accentSky),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authService = ApiAuthService();
      await authService.logout();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _openCastModal(BuildContext context) {
    final videoId =
        YoutubeHelper.extractVideoId(_currentSong?.songyoutubeurl) ??
        YoutubeHelper.extractVideoId(_currentSong?.songurl);
    CastDeviceModal.show(
      context,
      castService: _castService,
      currentVideoId: videoId,
      mediaUrl: _isMediaActive
          ? MediaUrlHelper.resolve(_currentSong?.songvideourl)
          : null,
      songTitle: _currentSong?.songtitle,
      songSinger: _currentSong?.songsinger,
      songThumbnail: videoId != null
          ? YoutubeHelper.getThumbnailUrl(videoId)
          : null,
      onDeviceChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _openSongSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle & close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                  ),

                  // SongSearchPanel (Full space inside modal)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: SongSearchPanel(
                        songs: _allSongs,
                        categories: _categories,
                        initialCategory: _initialCategoryFilter,
                        queue: _queue,
                        currentPlayingSong: _currentSong,
                        isLoading: _isLoading,
                        onPlaySong: (song) {
                          _playSong(song);
                          Navigator.of(modalContext).pop();
                        },
                        onAddToQueue: (song) {
                          _addToQueue(song);
                          setModalState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${song.songtitle} masuk antrean'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onRemoveFromQueue: (index) {
                          _removeFromQueue(index);
                          setModalState(() {});
                        },
                        onClearQueue: () {
                          _clearQueue();
                          setModalState(() {});
                        },
                        onRefresh: _loadData,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerStage({bool fillHeight = false}) {
    if (_isTextOnly) {
      final lyrics = LyricsDisplay(
        song: _currentSong,
        verseIndex: _currentVerseIndex,
      );

      // Di portrait Teks Only, kartu lirik memenuhi ruang yang tersedia agar
      // kontrol ayat dan panel bawah terdorong ke bawah.
      if (fillHeight) return lyrics;

      return AspectRatio(aspectRatio: 4 / 3, child: lyrics);
    }

    return PlayerDisplay(
      key: _playerDisplayKey,
      song: _currentSong,
      isPlaying: _isPlaying,
      currentPosition: _currentPosition,
      totalDuration: _totalDuration,
      queueCount: _queue.length,
      isFullscreen: _isFullscreen,
      youtubeController: _youtubeController,
      mediaController: _isMediaActive ? _mediaController : null,
      videoKey: _videoKey,
      mediaError: _mediaError,
      onRetryMedia: _retryMedia,
      onFullscreenChanged: (value) {
        if (mounted && value != _isFullscreen) {
          setState(() => _isFullscreen = value);
        }
      },
      isTestMode: widget.isTestMode,
      isCasting: _isCasting,
      onPlayPauseTapped: _togglePlayPause,
      onOpenSearchModal: () => _openSongSearchModal(context),
    );
  }

  Widget _buildPlaybackControls() {
    if (_isTextOnly) {
      final verses = _currentVerses;
      return TextOnlyControls(
        canPrevious: _currentSong != null && _currentVerseIndex > 0,
        canNext: _currentSong != null && _currentVerseIndex < verses.length - 1,
        onPrevious: _previousVerse,
        onNext: _nextVerse,
      );
    }

    return PlayerControls(
      song: _currentSong,
      isPlaying: _isPlaying,
      hasSong: _currentSong != null,
      currentPosition: _currentPosition,
      currentPositionListenable: _currentPositionNotifier,
      totalDuration: _totalDuration,
      onSeek: _seek,
      onTogglePlayPause: _togglePlayPause,
      onStop: _stopSong,
      onNext: _nextSong,
      onPrevious: _previousSong,
      volume: _volume,
      isMuted: _isMuted,
      isFullscreen: _isFullscreen,
      onToggleFullscreen:
          _isCasting || (_isMediaActive && _mediaController.isAudioOnly)
          ? null
          : _toggleFullscreen,
      onVolumeChanged: _onVolumeChanged,
      onToggleMute: _toggleMute,
      onCastTapped: () => _openCastModal(context),
      isCasting: _castService.connectedDevice != null,
      pitchSemitones: _pitchSemitones,
      tempoRate: _tempoRate,
      tuningEnabled: _isMediaActive && _currentSong != null && !_isCasting,
      onOpenTuning: _openTuningSheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _currentUser?.displayName ?? 'Penyanyi';
    final username = _currentUser?.username ?? 'user';
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape ||
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isCompactLandscape =
        isLandscape && MediaQuery.of(context).size.height < 550;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header Bar (Minimalis & Tanpa Subteks)
              _buildHeader(
                displayName,
                username,
                isCompact: isCompactLandscape,
              ),

              // Iklan slot atas: slot 1 untuk halaman musik, slot khusus lirik
              // untuk mode Hanya Lirik.
              if (_appConfig != null && !_topAdClosed)
                AdSlotView(
                  key: const ValueKey('ad_slot_top'),
                  ad: _topAdConfig!,
                  active: _topAdActive,
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                  maxHeight: 120,
                  onClose: () => setState(() => _topAdClosed = true),
                ),

              // 2. Main Karaoke Screen Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscapeLayout =
                        isLandscape ||
                        constraints.maxWidth > constraints.maxHeight;

                    // ================= 1. LANDSCAPE LAYOUT (Tablet & Smartphone) =================
                    // Kolom Kiri: Player Display & Controls
                    // Kolom Kanan: Cari Lagu & Playlist
                    if (isLandscapeLayout) {
                      final isCompact = constraints.maxHeight < 550;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 20,
                          vertical: isCompact ? 4 : 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Kolom Kiri: Player Stage & Controls (Adaptif Tinggi)
                            Expanded(
                              flex: isCompact ? 10 : 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Player Cinema Stage (Otomatis menyesuaikan sisa tinggi 16:9)
                                  Expanded(
                                    child: Center(child: _buildPlayerStage()),
                                  ),
                                  SizedBox(height: isCompact ? 6 : 10),

                                  // Studio Playback Controls
                                  _buildPlaybackControls(),
                                ],
                              ),
                            ),

                            SizedBox(width: isCompact ? 10 : 14),

                            // Kolom Kanan: Cari Lagu & Playlist (Vertikal untuk Tablet, Tabbed untuk Smartphone)
                            Expanded(
                              flex: isCompact ? 10 : 9,
                              child: SongCatalogPlaylistSection(
                                axis: Axis.vertical,
                                songs: _allSongs,
                                categories: _categories,
                                initialCategory: _initialCategoryFilter,
                                queue: _queue,
                                currentPlayingSong: _currentSong,
                                isLoading: _isLoading,
                                onPlaySong: _playSong,
                                onAddToQueue: _addToQueue,
                                onRemoveFromQueue: _removeFromQueue,
                                onReorderQueue: _reorderQueue,
                                onClearQueue: _clearQueue,
                                onRefresh: _loadData,
                                onOpenSearchModal: () =>
                                    _openQuickSearchModal(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ================= 2. SMARTPHONE PORTRAIT LAYOUT (< 768px atau Vertikal) =================
                    final isHeightConstrained =
                        MediaQuery.of(context).size.height < 620;

                    if (isHeightConstrained) {
                      final compactLyricsHeight =
                          (constraints.maxWidth - 28) * 3 / 4 +
                          TextOnlyControls.preferredHeight;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Player Cinema Stage (Full Width)
                            if (_isTextOnly)
                              SizedBox(
                                height: compactLyricsHeight,
                                child: _buildPlayerStage(fillHeight: true),
                              )
                            else
                              _buildPlayerStage(),
                            const SizedBox(height: 8),

                            // Studio Playback Controls
                            _buildPlaybackControls(),
                            const SizedBox(height: 10),

                            // Cari Lagu & Playlist Section (Berdampingan secara horizontal di mobile)
                            SizedBox(
                              height: 480,
                              child: SongCatalogPlaylistSection(
                                songs: _allSongs,
                                categories: _categories,
                                initialCategory: _initialCategoryFilter,
                                queue: _queue,
                                currentPlayingSong: _currentSong,
                                isLoading: _isLoading,
                                onPlaySong: _playSong,
                                onAddToQueue: _addToQueue,
                                onRemoveFromQueue: _removeFromQueue,
                                onReorderQueue: _reorderQueue,
                                onClearQueue: _clearQueue,
                                onRefresh: _loadData,
                                onOpenSearchModal: () =>
                                    _openQuickSearchModal(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final catalogSection = SongCatalogPlaylistSection(
                      songs: _allSongs,
                      categories: _categories,
                      initialCategory: _initialCategoryFilter,
                      queue: _queue,
                      currentPlayingSong: _currentSong,
                      isLoading: _isLoading,
                      onPlaySong: _playSong,
                      onAddToQueue: _addToQueue,
                      onRemoveFromQueue: _removeFromQueue,
                      onReorderQueue: _reorderQueue,
                      onClearQueue: _clearQueue,
                      onRefresh: _loadData,
                      onOpenSearchModal: () => _openQuickSearchModal(context),
                    );

                    // Di mode Teks Only, tambah tinggi kartu lirik sebesar
                    // tinggi kartu kontrol. Hasilnya seluruh blok kontrol +
                    // katalog turun tepat satu kartu kontrol (garis hijau).
                    const horizontalPadding = 28.0;
                    const fixedVerticalSpace = 12.0 + 8.0 + 10.0;
                    const minCatalogHeight = 170.0;
                    final baseLyricsHeight =
                        (constraints.maxWidth - horizontalPadding) * 3 / 4;
                    final desiredLyricsHeight =
                        baseLyricsHeight + TextOnlyControls.preferredHeight;
                    final availableLyricsHeight =
                        constraints.maxHeight -
                        fixedVerticalSpace -
                        TextOnlyControls.preferredHeight -
                        minCatalogHeight;
                    final textOnlyLyricsHeight =
                        desiredLyricsHeight > availableLyricsHeight
                        ? availableLyricsHeight
                        : desiredLyricsHeight;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isTextOnly) ...[
                            // Mode Teks Only: lirik lebih tinggi, kontrol ayat
                            // dan panel bawah turun sampai garis pemisah.
                            SizedBox(
                              height: textOnlyLyricsHeight,
                              child: _buildPlayerStage(fillHeight: true),
                            ),
                          ] else ...[
                            // Mode Biasa: player video tetap dengan tinggi tetap.
                            _buildPlayerStage(),
                          ],
                          const SizedBox(height: 8),

                          // Studio Playback Controls (Fixed)
                          _buildPlaybackControls(),
                          const SizedBox(height: 10),

                          // Cari Lagu & Playlist Section
                          Expanded(child: catalogSection),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Iklan slot bawah: footer biasa untuk halaman musik, slot khusus
              // lirik untuk mode Hanya Lirik.
              if (_appConfig != null && !_bottomAdClosed)
                AdSlotView(
                  key: const ValueKey('ad_slot_bottom'),
                  ad: _bottomAdConfig!,
                  active: _bottomAdActive,
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                  maxHeight: 120,
                  onClose: () => setState(() => _bottomAdClosed = true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickSearchModal(BuildContext context) {
    SongSearchModal.show(
      context,
      songs: _allSongs,
      queue: _queue,
      initialCategory: _initialCategoryFilter,
      isLoading: _isLoading,
      onAddToQueue: _addToQueue,
    );
  }

  Widget _buildHeader(
    String displayName,
    String username, {
    bool isCompact = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: isCompact ? 4.0 : 8.0,
      ),
      child: Row(
        children: [
          // Logo & Title (Clean & Minimalist: No subtexts!)
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'asset/image/logo_nrm_transparent.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Nyanyian Rohani Methodist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Logout Button
          IconButton(
            onPressed: _handleLogout,
            tooltip: 'Keluar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

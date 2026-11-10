import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_application_service.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/api_music_service.dart';
import '../../core/services/application_service.dart';
import '../../core/services/karaoke_media_controller.dart';
import '../../core/services/music_player_controller.dart';
import '../../core/services/music_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/media_url_helper.dart';
import '../../core/utils/music_song_adapter.dart';
import '../../models/application_model.dart';
import '../../models/category_model.dart';
import '../../models/music_model.dart';
import '../../models/song_model.dart';
import '../../services/ad_manager.dart';
import '../../widgets/ad_popup.dart';
import '../../widgets/ad_slot_view.dart';
import '../login_screen.dart';
import '../user/widgets/playback_tuning_sheet.dart';
import '../user/widgets/player_controls.dart';
import '../user/widgets/song_catalog_playlist_section.dart';
import '../user/widgets/song_search_modal.dart';
import 'widgets/music_lyrics_display.dart';
import 'widgets/music_player_display.dart';

/// Halaman Musik: player audio, daftar lagu, dan playlist dengan UI yang sama
/// seperti halaman karaoke (tanpa pemutar video).
class MusicScreen extends StatefulWidget {
  final MusicService? musicService;
  final ApplicationService? applicationService;
  final bool isTestMode;

  const MusicScreen({
    super.key,
    this.musicService,
    this.applicationService,
    this.isTestMode = false,
  });

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  late final MusicService _musicService;
  late final ApplicationService _applicationService;
  late final MusicPlayerController _player;

  ApplicationModel? _appConfig;
  bool _pageAdShown = false;
  bool _topAdClosed = false;
  bool _bottomAdClosed = false;

  List<MusicModel> _music = [];
  final List<MusicModel> _queue = [];
  MusicModel? _current;
  bool _isLoading = true;
  String? _error;
  String? _playbackError;
  bool _showLyrics = false;
  double _volume = 0.8;
  bool _isMuted = false;
  int _pitchSemitones = 0;
  double _tempoRate = 1.0;

  List<SongModel> get _uiSongs => musicToSongModels(_music);
  List<SongModel> get _uiQueue => musicToSongModels(_queue);
  SongModel? get _uiCurrent => _current?.toSongModel();

  Duration get _effectiveDuration {
    final fromPlayer = _player.durationNotifier.value;
    if (fromPlayer > Duration.zero) return fromPlayer;

    final seconds = _current?.musicduration ?? 0;
    return Duration(seconds: seconds);
  }

  @override
  void initState() {
    super.initState();
    _musicService = widget.musicService ?? ApiMusicService();
    _applicationService = widget.applicationService ?? ApiApplicationService();
    _player = MusicPlayerController(isTestMode: widget.isTestMode)
      ..onCompleted = _handleCompleted
      ..onPlayingChanged = _handlePlayingChanged
      ..onDurationChanged = _handleDurationChanged
      ..onError = _handlePlayerError;
    _loadMusic();
    _loadAppConfig();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _handleCompleted() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      _playMusic(next);
      return;
    }

    _player.seek(Duration.zero);
    _player.pause();
  }

  void _handlePlayingChanged(bool playing) {
    if (!mounted) return;
    setState(() {});
  }

  void _handleDurationChanged(Duration duration) {
    if (!mounted) return;
    setState(() {});
  }

  void _handlePlayerError(String message) {
    if (!mounted) return;
    setState(() {
      _playbackError = 'Musik tidak dapat diputar. Periksa koneksi Anda.';
    });
  }

  Future<void> _loadMusic() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _musicService.getMusic();
      if (!mounted) return;

      final availableIds = result.map((item) => item.musicid).toSet();
      _queue.removeWhere((item) => !availableIds.contains(item.musicid));

      if (_current != null && !availableIds.contains(_current!.musicid)) {
        _current = null;
        _showLyrics = false;
        _player.stop();
      }

      setState(() {
        _music = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Memuat ulang daftar musik tanpa menampilkan state loading penuh.
  /// Dipakai oleh pull-to-refresh agar halaman dan pemutaran tidak berkedip.
  Future<void> _refreshMusic() async {
    try {
      final result = await _musicService.getMusic();
      if (!mounted) return;

      final availableIds = result.map((item) => item.musicid).toSet();
      _queue.removeWhere((item) => !availableIds.contains(item.musicid));

      var current = _current;
      if (current != null && !availableIds.contains(current.musicid)) {
        current = null;
        _showLyrics = false;
        _player.stop();
      }

      setState(() {
        _music = result;
        _current = current;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Gagal memperbarui daftar musik. Periksa koneksi Anda.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  MusicModel? _musicById(int id) {
    for (final item in _music) {
      if (item.musicid == id) return item;
    }
    return null;
  }

  /// Memuat konfigurasi iklan dari backend. Kegagalan tidak mengganggu
  /// pemutaran musik; slot iklan hanya tidak ditampilkan.
  Future<void> _loadAppConfig() async {
    try {
      final config = await _applicationService.getApplicationConfig();
      if (!mounted) return;
      setState(() => _appConfig = config);
      AdManager.instance.configure(config);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPageAd());
    } catch (e) {
      debugPrint('Music screen app config load error: $e');
    }
  }

  /// Menampilkan pop-up iklan khusus halaman musik satu kali per layar.
  void _maybeShowPageAd() {
    if (_pageAdShown || !mounted) return;
    final config = _appConfig;
    if (config == null) return;

    final ad = config.adsMusikConfig;
    if (!config.isAdsMusikActive || !hasAdPopupContent(ad)) return;

    _pageAdShown = true;
    showAdPopup(context, ad);
  }

  Future<void> _playMusic(MusicModel music) async {
    final url =
        MediaUrlHelper.resolve(music.streamUrl) ??
        '${ApiConfig.baseUrl}/music/${music.musicid}/stream';

    setState(() {
      _current = music;
      _playbackError = null;
      _pitchSemitones = 0;
      _tempoRate = 1.0;
    });

    final loaded = await _player.load(url);
    if (!mounted) return;

    if (!loaded) {
      setState(() {
        _playbackError = 'Musik tidak dapat diputar. Periksa koneksi Anda.';
      });
      return;
    }

    await _player.setVolume(_isMuted ? 0 : _volume);
  }

  void _togglePlayPause() {
    if (_current == null) {
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        _playMusic(next);
      } else if (_music.isNotEmpty) {
        _playMusic(_music.first);
      }
      return;
    }

    if (_player.isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _stopPlayback() {
    _player.pause();
    _player.seek(Duration.zero);
    setState(() {});
  }

  bool get _currentHasLyrics {
    final lyric = _current?.songlyric?.trim();
    return lyric != null && lyric.isNotEmpty;
  }

  void _toggleLyrics() {
    if (_current == null) return;
    setState(() => _showLyrics = !_showLyrics);
  }

  void _playNext() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      _playMusic(next);
      return;
    }

    if (_music.isEmpty) return;

    final index = _current == null
        ? -1
        : _music.indexWhere((item) => item.musicid == _current!.musicid);
    final nextIndex = (index + 1) % _music.length;
    _playMusic(_music[nextIndex]);
  }

  void _playPrevious() {
    if (_player.position > const Duration(seconds: 3)) {
      _player.seek(Duration.zero);
      return;
    }

    if (_music.isEmpty) return;

    final index = _current == null
        ? 0
        : _music.indexWhere((item) => item.musicid == _current!.musicid);
    final previousIndex = index <= 0 ? _music.length - 1 : index - 1;
    _playMusic(_music[previousIndex]);
  }

  void _addToQueue(MusicModel music) {
    if (_queue.any((item) => item.musicid == music.musicid)) {
      return;
    }

    setState(() => _queue.add(music));
  }

  void _removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    setState(() => _queue.removeAt(index));
  }

  void _reorderQueue(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, item);
    });
  }

  void _clearQueue() {
    setState(() => _queue.clear());
  }

  void _onPlaySongFromCatalog(SongModel song) {
    final music = _musicById(song.songid);
    if (music != null) {
      _playMusic(music);
    }
  }

  void _onAddSongToQueue(SongModel song) {
    final music = _musicById(song.songid);
    if (music != null) {
      _addToQueue(music);
    }
  }

  void _openSearchModal() {
    SongSearchModal.show(
      context,
      songs: _uiSongs,
      queue: _uiQueue,
      isLoading: _isLoading,
      onAddToQueue: _onAddSongToQueue,
    );
  }

  void _onVolumeChanged(double value) {
    setState(() {
      _volume = value;
      if (value > 0) _isMuted = false;
    });
    _player.setVolume(_isMuted ? 0 : value);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _player.setVolume(_isMuted ? 0 : _volume);
  }

  void _applyPitchSemitones(int value) {
    if (_current == null) return;
    final next = value.clamp(
      KaraokeMediaController.minSemitone,
      KaraokeMediaController.maxSemitone,
    );
    if (next == _pitchSemitones) return;
    setState(() => _pitchSemitones = next);
    _player.setPitchSemitones(next);
  }

  void _applyTempoRate(double value) {
    if (_current == null) return;
    final next = KaraokeMediaController.clampRate(value);
    if ((next - _tempoRate).abs() < 0.0001) return;
    setState(() => _tempoRate = next);
    _player.setRate(next);
  }

  void _openTuningSheet() {
    if (_current == null) return;
    PlaybackTuningSheet.show(
      context,
      pitchSemitones: _pitchSemitones,
      tempoRate: _tempoRate,
      onPitchChanged: _applyPitchSemitones,
      onTempoChanged: _applyTempoRate,
    );
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

    if (confirm != true || !mounted) return;

    await ApiAuthService().logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_appConfig != null && !_topAdClosed)
                AdSlotView(
                  key: const ValueKey('ad_slot_top'),
                  ad: _appConfig!.adsMusikTopConfig,
                  active: _appConfig!.isAdsMusikTopActive,
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                  maxHeight: 120,
                  onClose: () => setState(() => _topAdClosed = true),
                ),
              Expanded(child: _buildBody()),
              if (_appConfig != null && !_bottomAdClosed)
                AdSlotView(
                  key: const ValueKey('ad_slot_bottom'),
                  ad: _appConfig!.adsMusikBottomConfig,
                  active: _appConfig!.isAdsMusikBottomActive,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Logo & judul aplikasi (sama dengan header halaman utama).
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
          const Expanded(
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

          // Tombol logout dengan gaya yang sama seperti header utama.
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
        ),
      );
    }

    if (_error != null) {
      return _buildMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal memuat musik',
        message: _error!,
        actionLabel: 'Coba Lagi',
        onAction: _loadMusic,
      );
    }

    if (_music.isEmpty) {
      return _buildMessageState(
        icon: Icons.library_music_outlined,
        title: 'Belum ada musik',
        message: 'Admin belum menambahkan musik ke aplikasi.',
        actionLabel: 'Muat Ulang',
        onAction: _loadMusic,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 650;
        final cardHeight = constraints.maxHeight < 550
            ? 120.0
            : (isCompact ? 130.0 : 140.0);
        final showLyrics = _showLyrics && _current != null;
        final desiredLyricsHeight = constraints.maxHeight * 0.5;
        final controlsReserve = constraints.maxWidth < 480 ? 188.0 : 96.0;
        final maxLyricsHeight = constraints.maxHeight - controlsReserve - 80;
        final lyricsHeight = maxLyricsHeight <= 140
            ? desiredLyricsHeight
            : desiredLyricsHeight.clamp(140.0, maxLyricsHeight);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 4 : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: showLyrics ? lyricsHeight : cardHeight,
                child: showLyrics
                    ? MusicLyricsDisplay(
                        music: _current,
                        onClose: _toggleLyrics,
                      )
                    : MusicPlayerDisplay(
                        music: _current,
                        isPlaying: _player.playingNotifier.value,
                        errorMessage: _playbackError,
                        hasLyrics: _currentHasLyrics,
                        onToggleLyrics: _current == null ? null : _toggleLyrics,
                      ),
              ),
              const SizedBox(height: 8),
              _buildPlayerControls(),
              SizedBox(height: isCompact ? 6 : 10),
              Expanded(child: _buildCatalogSection(axis: Axis.horizontal)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerControls() {
    return PlayerControls(
      song: _uiCurrent,
      isPlaying: _player.playingNotifier.value,
      hasSong: _current != null || _music.isNotEmpty,
      currentPosition: _player.positionNotifier.value,
      currentPositionListenable: _player.positionNotifier,
      totalDuration: _effectiveDuration,
      onSeek: _player.seek,
      onTogglePlayPause: _togglePlayPause,
      onStop: _stopPlayback,
      onNext: _playNext,
      onPrevious: _playPrevious,
      volume: _volume,
      isMuted: _isMuted,
      onVolumeChanged: _onVolumeChanged,
      onToggleMute: _toggleMute,
      isFullscreen: false,
      pitchSemitones: _pitchSemitones,
      tempoRate: _tempoRate,
      tuningEnabled: _current != null,
      onOpenTuning: _openTuningSheet,
    );
  }

  Widget _buildCatalogSection({required Axis axis}) {
    return SongCatalogPlaylistSection(
      axis: axis,
      songs: _uiSongs,
      categories: const <CategoryModel>[],
      queue: _uiQueue,
      currentPlayingSong: _uiCurrent,
      isLoading: _isLoading,
      onPlaySong: _onPlaySongFromCatalog,
      onAddToQueue: _onAddSongToQueue,
      onRemoveFromQueue: _removeFromQueue,
      onReorderQueue: _reorderQueue,
      onClearQueue: _clearQueue,
      onRefresh: _refreshMusic,
      enablePullToRefresh: true,
      onOpenSearchModal: _openSearchModal,
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Icon(icon, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

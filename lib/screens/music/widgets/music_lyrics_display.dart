import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/lyric_parser.dart';
import '../../../models/music_model.dart';

/// Panel lirik halaman Musik.
///
/// Menampilkan seluruh lirik lagu yang sedang diputar dalam satu panel
/// scrollable. Judul lagu sengaja tidak ditampilkan karena panel ini
/// menggantikan kartu "now playing".
class MusicLyricsDisplay extends StatefulWidget {
  final MusicModel? music;
  final VoidCallback onClose;

  const MusicLyricsDisplay({
    super.key,
    required this.music,
    required this.onClose,
  });

  @override
  State<MusicLyricsDisplay> createState() => _MusicLyricsDisplayState();
}

class _MusicLyricsDisplayState extends State<MusicLyricsDisplay> {
  static const double _minScale = 0.75;
  static const double _maxScale = 1.8;
  static const double _scaleStep = 0.15;

  final ScrollController _scrollController = ScrollController();
  double _textScale = 1.0;

  @override
  void didUpdateWidget(covariant MusicLyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.music?.musicid != widget.music?.musicid &&
        _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changeTextSize(double delta) {
    setState(() {
      _textScale = (_textScale + delta).clamp(_minScale, _maxScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final verses = LyricParser.parse(widget.music?.songlyric);

    return Container(
      key: const ValueKey('music_lyrics_display'),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardGlassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryElectric.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildHeader(),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Expanded(
              child: verses.isEmpty
                  ? _buildEmptyState()
                  : Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < verses.length; i++) ...[
                              if (i > 0) const SizedBox(height: 18),
                              _buildVerse(verses[i], i),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppColors.accentCyan.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.lyrics_rounded,
              size: 17,
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Lirik',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _buildTextSizeControls(),
          const SizedBox(width: 4),
          IconButton(
            onPressed: widget.onClose,
            tooltip: 'Tutup lirik',
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVerse(LyricVerse verse, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          verse.headingLabel(index),
          style: TextStyle(
            fontSize: 15 * _textScale,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: AppColors.accentSky,
          ),
        ),
        if (verse.body.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            verse.body,
            style: TextStyle(
              fontSize: 16 * _textScale,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextSizeControls() {
    final canDecrease = _textScale > _minScale;
    final canIncrease = _textScale < _maxScale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1326).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSizeButton(
            label: 'A-',
            tooltip: 'Perkecil teks lirik',
            enabled: canDecrease,
            onPressed: () => _changeTextSize(-_scaleStep),
          ),
          _buildSizeButton(
            label: 'A+',
            tooltip: 'Perbesar teks lirik',
            enabled: canIncrease,
            onPressed: () => _changeTextSize(_scaleStep),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeButton({
    required String label,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: enabled ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.text_snippet_outlined,
              size: 38,
              color: AppColors.accentLight,
            ),
            SizedBox(height: 10),
            Text(
              'Lirik belum tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Lirik lagu ini belum diisi oleh admin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

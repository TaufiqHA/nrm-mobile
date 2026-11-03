import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/lyric_parser.dart';
import '../../../models/song_model.dart';

/// Panel lirik untuk mode Teks Only.
///
/// Hanya satu ayat ditampilkan pada satu waktu. Navigasi antar ayat dilakukan
/// dari tombol prev/next di luar panel ini. Ukuran teks bisa diatur lewat
/// tombol A-/A+ di pojok kanan atas panel.
class LyricsDisplay extends StatefulWidget {
  final SongModel? song;
  final int verseIndex;

  const LyricsDisplay({
    super.key,
    this.song,
    this.verseIndex = 0,
  });

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  static const double _minScale = 0.7;
  static const double _maxScale = 2.0;
  static const double _scaleStep = 0.15;

  double _textScale = 1.0;

  static const double _baseHeadingSize = 21;
  static const double _baseBodySize = 20;

  void _increaseTextSize() {
    setState(() {
      _textScale = (_textScale + _scaleStep).clamp(_minScale, _maxScale);
    });
  }

  void _decreaseTextSize() {
    setState(() {
      _textScale = (_textScale - _scaleStep).clamp(_minScale, _maxScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final verses = LyricParser.parse(widget.song?.songlyric);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: widget.song == null
            ? _buildEmptyState(
                icon: Icons.lyrics_rounded,
                title: 'Pilih lagu untuk melihat lirik',
                subtitle: 'Pilih lagu dari daftar di bawah',
              )
            : verses.isEmpty
            ? _buildEmptyState(
                icon: Icons.text_snippet_outlined,
                title: 'Lirik belum tersedia',
                subtitle: 'Lirik lagu ini belum diisi oleh admin',
              )
            : Stack(
                children: [
                  Positioned.fill(child: _buildVerse(verses)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildTextSizeControls(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVerse(List<LyricVerse> verses) {
    final index = widget.verseIndex.clamp(0, verses.length - 1);
    final verse = verses[index];

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 104),
              child: Text(
                verse.headingLabel(index),
                style: TextStyle(
                  fontSize: _baseHeadingSize * _textScale,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (verse.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                verse.body,
                style: TextStyle(
                  fontSize: _baseBodySize * _textScale,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeControls() {
    final canDecrease = _textScale > _minScale;
    final canIncrease = _textScale < _maxScale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1326).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSizeButton(
            label: 'A-',
            tooltip: 'Perkecil teks',
            enabled: canDecrease,
            onPressed: _decreaseTextSize,
          ),
          Container(
            width: 1,
            height: 18,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          _buildSizeButton(
            label: 'A+',
            tooltip: 'Perbesar teks',
            enabled: canIncrease,
            onPressed: _increaseTextSize,
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
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: enabled ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: AppColors.accentLight),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

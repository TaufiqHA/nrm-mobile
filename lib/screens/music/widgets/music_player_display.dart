import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/music_model.dart';

/// Kartu "now playing" menu Musik: cover di kiri, judul dan tombol lirik
/// di kanan. Tanpa pemutar video.
class MusicPlayerDisplay extends StatelessWidget {
  final MusicModel? music;
  final bool isPlaying;
  final String? errorMessage;
  final bool hasLyrics;
  final VoidCallback? onToggleLyrics;

  const MusicPlayerDisplay({
    super.key,
    this.music,
    this.isPlaying = false,
    this.errorMessage,
    this.hasLyrics = false,
    this.onToggleLyrics,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = music?.coverUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final coverSize = (constraints.maxHeight - 24).clamp(56.0, 104.0);

        return Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Cover lagu.
              Container(
                key: const ValueKey('music_cover'),
                width: coverSize,
                height: coverSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(coverSize * 0.2),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentCyan.withValues(alpha: 0.35),
                      AppColors.primaryElectric.withValues(alpha: 0.35),
                    ],
                  ),
                  border: Border.all(
                    color: isPlaying
                        ? AppColors.accentCyan.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(coverSize * 0.2),
                  child: coverUrl == null
                      ? Icon(
                          Icons.music_note_rounded,
                          color: AppColors.accentSky,
                          size: coverSize * 0.42,
                        )
                      : Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.music_note_rounded,
                            color: AppColors.accentSky,
                            size: coverSize * 0.42,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Judul dan aksi lirik.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, infoConstraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: infoConstraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              music?.musictitle ?? 'Pilih musik untuk diputar',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            if (onToggleLyrics != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _buildLyricsButton(),
                              ),
                            ],
                            if (errorMessage != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                errorMessage!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricsButton() {
    final enabled = music != null && hasLyrics;

    return Tooltip(
      message: enabled ? 'Tampilkan lirik' : 'Lirik belum tersedia',
      child: InkWell(
        onTap: enabled ? onToggleLyrics : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 32,
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.accentOrange.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? AppColors.accentOrange.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lyrics_rounded,
                  size: 16,
                  color: enabled ? AppColors.accentOrange : AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Klik untuk tampilkan lirik',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? AppColors.accentOrange
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

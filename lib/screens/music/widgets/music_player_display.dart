import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/music_model.dart';

/// Kartu "now playing" menu Musik: cover di kiri, informasi lagu di kanan.
/// Tanpa pemutar video.
class MusicPlayerDisplay extends StatelessWidget {
  final MusicModel? music;
  final bool isPlaying;
  final String? errorMessage;

  const MusicPlayerDisplay({
    super.key,
    this.music,
    this.isPlaying = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = music?.coverUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final coverSize = (constraints.maxHeight - 28).clamp(56.0, 120.0);

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Cover lagu.
              Container(
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

              // Informasi lagu.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 4),
                    Text(
                      music?.musicartist ?? 'NRM',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.accentSky,
                      ),
                    ),
                    if (isPlaying) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentCyan.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              size: 12,
                              color: AppColors.accentCyan,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sedang diputar',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentSky,
                              ),
                            ),
                          ],
                        ),
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
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/application_model.dart';
import 'ad_slot_view.dart';

/// True bila slot berisi iklan gambar yang bisa dirender di dalam pop-up.
///
/// Pop-up hanya dipakai untuk banner gambar hasil unggahan admin
/// (jenis `image`). Format AdMob layar penuh dikelola `AdManager`, sedangkan
/// native/banner AdMob tetap dirender inline di slot halaman.
bool hasAdPopupContent(AdSlotConfig ad) =>
    ad.isImage && (ad.image ?? '').trim().isNotEmpty;

/// Menampilkan iklan gambar sebagai dialog pop-up.
///
/// Gambar dimuat lebih dulu; dialog baru dibuka setelah gambar siap. Bila gagal
/// dimuat (atau melewati batas tunggu), pop-up tidak ditampilkan.
Future<void> showAdPopup(BuildContext context, AdSlotConfig ad) async {
  if (!hasAdPopupContent(ad)) return;

  final String url = resolveAdImageUrl(ad.image ?? '');
  if (url.isEmpty) return;

  final ImageProvider provider = buildAdImageProvider(ad.image ?? '');

  bool failed = false;
  try {
    await precacheImage(
      provider,
      context,
      onError: (_, _) => failed = true,
    ).timeout(const Duration(seconds: 10), onTimeout: () => failed = true);
  } catch (_) {
    failed = true;
  }
  if (failed || !context.mounted) return;

  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      key: const ValueKey('ad_popup_dialog'),
      backgroundColor: AppColors.surfaceDark,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardGlassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.16),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.45),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Iklan',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('ad_popup_close'),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardGlassBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: AdSlotView(
              ad: ad,
              padding: EdgeInsets.zero,
              showLabel: false,
            ),
          ),
        ],
      ),
    ),
  );
}

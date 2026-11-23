import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/application_model.dart';
import 'ad_slot_view.dart';

/// True bila slot berisi iklan inline yang bisa dirender di dalam pop-up.
bool hasAdPopupContent(AdSlotConfig ad) {
  final hasContent =
      (ad.isImage && (ad.image ?? '').trim().isNotEmpty) ||
      ((ad.isNative || ad.isBanner) && ad.hasUnit);
  return ad.isInline && hasContent;
}

/// Menampilkan iklan inline (gambar/native/banner) sebagai dialog pop-up.
///
/// Iklan dimuat lebih dulu; dialog baru dibuka setelah iklan siap. Bila gagal
/// dimuat (atau melewati batas tunggu), pop-up tidak ditampilkan.
/// Slot kosong atau berjenis full-screen tidak ditampilkan karena format
/// layar penuh dikelola oleh `AdManager`.
Future<void> showAdPopup(BuildContext context, AdSlotConfig ad) async {
  if (!hasAdPopupContent(ad)) return;

  bool ready;
  try {
    ready = await preloadAdSlotContent(context, ad).timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
  } catch (_) {
    ready = false;
  }
  if (!ready || !context.mounted) return;

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
              startReady: true,
            ),
          ),
        ],
      ),
    ),
  );
}

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
/// Slot kosong atau berjenis full-screen tidak ditampilkan karena format
/// layar penuh dikelola oleh `AdManager`.
Future<void> showAdPopup(BuildContext context, AdSlotConfig ad) {
  if (!hasAdPopupContent(ad)) return Future<void>.value();

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
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              key: const ValueKey('ad_popup_close'),
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AdSlotView(ad: ad, padding: EdgeInsets.zero),
          ),
        ],
      ),
    ),
  );
}

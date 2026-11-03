import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Kontrol minimal untuk mode Teks Only: navigasi ayat sebelumnya/berikutnya.
class TextOnlyControls extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool canPrevious;
  final bool canNext;

  const TextOnlyControls({
    super.key,
    this.onPrevious,
    this.onNext,
    this.canPrevious = false,
    this.canNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.skip_previous_rounded,
            label: 'Ayat sebelumnya',
            onPressed: canPrevious ? onPrevious : null,
          ),
          _buildNavButton(
            icon: Icons.skip_next_rounded,
            label: 'Ayat berikutnya',
            onPressed: canNext ? onNext : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: onPressed == null
                    ? AppColors.textMuted.withValues(alpha: 0.5)
                    : AppColors.warning,
                width: 2.5,
              ),
            ),
            child: Icon(
              icon,
              size: 26,
              color: onPressed == null
                  ? AppColors.textMuted.withValues(alpha: 0.5)
                  : AppColors.warning,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/services/karaoke_media_controller.dart';
import '../../../core/theme/app_colors.dart';

/// Panel gabungan untuk mengatur nada (pitch) dan tempo lagu.
class PlaybackTuningSheet extends StatefulWidget {
  final int pitchSemitones;
  final double tempoRate;
  final ValueChanged<int> onPitchChanged;
  final ValueChanged<double> onTempoChanged;

  const PlaybackTuningSheet({
    super.key,
    required this.pitchSemitones,
    required this.tempoRate,
    required this.onPitchChanged,
    required this.onTempoChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required int pitchSemitones,
    required double tempoRate,
    required ValueChanged<int> onPitchChanged,
    required ValueChanged<double> onTempoChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaybackTuningSheet(
        pitchSemitones: pitchSemitones,
        tempoRate: tempoRate,
        onPitchChanged: onPitchChanged,
        onTempoChanged: onTempoChanged,
      ),
    );
  }

  @override
  State<PlaybackTuningSheet> createState() => _PlaybackTuningSheetState();
}

class _PlaybackTuningSheetState extends State<PlaybackTuningSheet> {
  late int _pitch;
  late double _tempo;

  @override
  void initState() {
    super.initState();
    _pitch = widget.pitchSemitones;
    _tempo = widget.tempoRate;
  }

  void _setPitch(int value) {
    final next = value.clamp(
      KaraokeMediaController.minSemitone,
      KaraokeMediaController.maxSemitone,
    );
    if (next == _pitch) return;
    setState(() => _pitch = next);
    widget.onPitchChanged(next);
  }

  void _setTempo(double value) {
    final next = KaraokeMediaController.clampRate(value);
    if ((next - _tempo).abs() < 0.0001) return;
    setState(() => _tempo = next);
    widget.onTempoChanged(next);
  }

  void _resetPitch() => _setPitch(0);

  void _resetTempo() => _setTempo(1.0);

  void _resetAll() {
    _resetPitch();
    _resetTempo();
  }

  String get _pitchLabel =>
      _pitch == 0 ? '0' : '${_pitch > 0 ? '+' : ''}$_pitch';

  String get _tempoLabel =>
      KaraokeMediaController.tempoLevelLabelForRate(_tempo);

  bool get _canDecreaseTempo =>
      _tempo > KaraokeMediaController.minRate + 0.0001;

  bool get _canIncreaseTempo =>
      _tempo < KaraokeMediaController.maxRate - 0.0001;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Text(
                'Nada & Tempo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Atur tinggi nada dan kecepatan lagu tanpa mengubah faktor lainnya.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              _buildPitchSection(),
              const SizedBox(height: 18),
              _buildTempoSection(),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _pitch == 0 && (_tempo - 1.0).abs() < 0.0001
                    ? null
                    : _resetAll,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Kembalikan ke asli'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentSky,
                  side: BorderSide(
                    color: AppColors.accentSky.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPitchSection() {
    return _buildSection(
      title: 'Nada',
      subtitle: 'Mengubah tinggi suara tanpa mengubah tempo.',
      valueWidget: Text(
        _pitchLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      control: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Turunkan nada',
            enabled: _pitch > KaraokeMediaController.minSemitone,
            onPressed: () => _setPitch(_pitch - 1),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 76,
            child: Text(
              _pitchLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accentSky,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 18),
          _buildStepButton(
            icon: Icons.add_rounded,
            tooltip: 'Naikkan nada',
            enabled: _pitch < KaraokeMediaController.maxSemitone,
            onPressed: () => _setPitch(_pitch + 1),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _pitch == 0 ? null : _resetPitch,
            tooltip: 'Reset nada',
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
            color: AppColors.accentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildTempoSection() {
    return _buildSection(
      title: 'Tempo',
      subtitle:
          'Mengubah kecepatan lagu tanpa mengubah tinggi nada. 1 = tempo asli.',
      valueWidget: Text(
        _tempoLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      control: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Turunkan tempo',
            enabled: _canDecreaseTempo,
            onPressed: () =>
                _setTempo(_tempo - KaraokeMediaController.rateStep),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 76,
            child: Text(
              _tempoLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accentSky,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 18),
          _buildStepButton(
            icon: Icons.add_rounded,
            tooltip: 'Naikkan tempo',
            enabled: _canIncreaseTempo,
            onPressed: () =>
                _setTempo(_tempo + KaraokeMediaController.rateStep),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (_tempo - 1.0).abs() < 0.0001 ? null : _resetTempo,
            tooltip: 'Reset tempo',
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
            color: AppColors.accentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget valueWidget,
    required Widget control,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              valueWidget,
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          control,
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primaryElectric.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? AppColors.accentCyan.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.accentLight : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

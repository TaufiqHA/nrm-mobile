import 'application_model.dart';

/// Satu slot iklan milik kategori lagu (atas, pop-up, atau bawah).
///
/// Slot dibuat otomatis oleh backend saat kategori baru ditambahkan dan
/// dikonfigurasi lewat halaman Iklan di panel admin website.
class CategoryAdSlot {
  /// Nama slot: `top`, `popup`, atau `bottom`.
  final String slot;

  /// Path/URL gambar banner (dipakai bila [format] = [AdFormat.image]).
  final String? image;

  final AdFormat format;

  /// Ad Unit ID AdMob (dipakai bila [format] adalah salah satu `admob*`).
  final String? unit;

  final bool active;
  final String? clickUrl;

  const CategoryAdSlot({
    required this.slot,
    this.image,
    this.format = AdFormat.image,
    this.unit,
    this.active = true,
    this.clickUrl,
  });

  AdSlotConfig get config =>
      AdSlotConfig(image: image, format: format, unit: unit);

  factory CategoryAdSlot.fromJson(Map<String, dynamic> json) {
    return CategoryAdSlot(
      slot: (json['slot'] ?? '').toString(),
      image: _nonEmpty(json['image']?.toString()),
      format: AdFormat.fromRaw(json['type']?.toString()),
      unit: _nonEmpty(json['unit']?.toString()),
      active: _parseActive(json['active']),
      clickUrl: _nonEmpty(json['clickurl']?.toString()),
    );
  }

  static bool _parseActive(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return !(normalized == '0' ||
        normalized == 'false' ||
        normalized == 'n' ||
        normalized == 'no');
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

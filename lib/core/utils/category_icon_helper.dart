import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../config/api_config.dart';

/// Ikon dan warna yang dipakai untuk merepresentasikan sebuah kategori lagu
/// pada pemilih kategori berbentuk grid ikon.
class CategoryIconSpec {
  final IconData icon;
  final Color color;

  /// URL gambar ikon kustom dari website admin. Bila tidak null, gambar ini
  /// yang ditampilkan menggantikan [icon].
  final String? imageUrl;

  const CategoryIconSpec(this.icon, this.color, [this.imageUrl]);
}

/// Pemetaan key ikon dari website admin (`config/category_icons.php`) ke ikon
/// Material pada aplikasi. Key harus sama persis dengan katalog di backend.
const Map<String, IconData> categoryIconCatalog = {
  'music_note': Icons.music_note_rounded,
  'library_music': Icons.library_music_rounded,
  'queue_music': Icons.queue_music_rounded,
  'headphones': Icons.headphones_rounded,
  'mic': Icons.mic_rounded,
  'piano': Icons.piano_rounded,
  'music_video': Icons.music_video_rounded,
  'video_library': Icons.video_library_rounded,
  'lyrics': Icons.lyrics_rounded,
  'star': Icons.star_rounded,
  'favorite': Icons.favorite_rounded,
  'celebration': Icons.celebration_rounded,
  'bolt': Icons.bolt_rounded,
  'child_care': Icons.child_care_rounded,
  'ac_unit': Icons.ac_unit_rounded,
  'wb_sunny': Icons.wb_sunny_rounded,
  'church': Icons.church_rounded,
  'menu_book': Icons.menu_book_rounded,
  'language': Icons.language_rounded,
  'public': Icons.public_rounded,
  'flag': Icons.flag_rounded,
  'translate': Icons.translate_rounded,
};

const List<Color> _categoryPalette = [
  Color(0xFFE53935), // merah
  Color(0xFF1E88E5), // biru
  Color(0xFF43A047), // hijau
  Color(0xFFFB8C00), // oranye
  Color(0xFF8E24AA), // ungu
  Color(0xFF00ACC1), // toska
  Color(0xFFD81B60), // magenta
  Color(0xFF3949AB), // indigo
];

/// Menentukan ikon yang paling relevan berdasarkan nama kategori.
///
/// Kategori dari API bisa berupa nama bebas, jadi pencocokan dilakukan lewat
/// kata kunci. Warna diambil dari palet berdasarkan urutan agar setiap
/// kategori tetap terlihat berbeda meskipun ikonnya sama.
CategoryIconSpec categoryIconSpec(CategoryModel category, int index) {
  final name = category.name.toLowerCase();

  // Warna khusus saat nama kategori menyebut warna buku.
  final color =
      _colorFromName(name) ?? _categoryPalette[index % _categoryPalette.length];

  // Prioritas 1: gambar ikon kustom yang diunggah lewat website admin.
  final imageUrl = _resolveIconImageUrl(category);
  if (imageUrl != null) {
    return CategoryIconSpec(Icons.library_music_rounded, color, imageUrl);
  }

  // Prioritas 2: ikon bawaan yang dipilih lewat website admin.
  final builtinIcon = categoryIconCatalog[category.icon];
  if (builtinIcon != null) {
    return CategoryIconSpec(builtinIcon, color);
  }

  // Prioritas 3: tebak ikon dari nama kategori (perilaku lama).
  IconData icon = Icons.library_music_rounded;

  if (_containsAny(name, ['anak', 'sekolah minggu', 'kids', 'children'])) {
    icon = Icons.child_care_rounded;
  } else if (_containsAny(name, ['natal', 'christmas', 'kelahiran'])) {
    icon = Icons.ac_unit_rounded;
  } else if (_containsAny(name, ['paskah', 'easter', 'kebangkitan'])) {
    icon = Icons.wb_sunny_rounded;
  } else if (_containsAny(name, ['karoke', 'karaoke', 'nyanyi bersama'])) {
    icon = Icons.mic_rounded;
  } else if (_containsAny(name, ['instrument', 'piano', 'organ', 'orgel'])) {
    icon = Icons.piano_rounded;
  } else if (_containsAny(name, ['daerah', 'nusantara', 'tradisional'])) {
    icon = Icons.public_rounded;
  } else if (_containsAny(name, [
    'inggris',
    'english',
    'barat',
    'international',
    'internasional',
  ])) {
    icon = Icons.language_rounded;
  } else if (_containsAny(name, [
    'korea',
    'k-pop',
    'jepang',
    'j-pop',
    'anime',
    'mandarin',
  ])) {
    icon = Icons.translate_rounded;
  } else if (name.contains('indonesia')) {
    icon = Icons.flag_rounded;
  } else if (_containsAny(name, ['pujian', 'penyembahan', 'worship'])) {
    icon = Icons.favorite_rounded;
  } else if (name.contains('lirik') && _containsAny(name, ['musik', 'video'])) {
    icon = Icons.music_video_rounded;
  } else if (name.contains('lirik')) {
    icon = Icons.lyrics_rounded;
  } else if (name.contains('video')) {
    icon = Icons.video_library_rounded;
  } else if (name.contains('musik')) {
    icon = Icons.music_note_rounded;
  } else if (name.contains('pop')) {
    icon = Icons.star_rounded;
  } else if (_containsAny(name, ['dangdut', 'koplo'])) {
    icon = Icons.celebration_rounded;
  } else if (_containsAny(name, ['rock', 'metal'])) {
    icon = Icons.bolt_rounded;
  } else if (name.contains('buku')) {
    icon = Icons.menu_book_rounded;
  } else if (_containsAny(name, ['kidung', 'nyanyian', 'rohani'])) {
    icon = Icons.queue_music_rounded;
  } else if (name.contains('akustik') || name.contains('acoustic')) {
    icon = Icons.headphones_rounded;
  }

  return CategoryIconSpec(icon, color);
}

/// Membangun URL gambar ikon dari path relatif yang disimpan backend.
///
/// Path dihitung terhadap origin dari `ApiConfig.baseUrl` (bukan `APP_URL`
/// backend), sehingga tetap benar meskipun aplikasi memakai base URL custom.
String? _resolveIconImageUrl(CategoryModel category) {
  final rawPath = category.iconImage?.trim();
  if (rawPath != null && rawPath.isNotEmpty) {
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    final normalizedPath = rawPath.startsWith('/')
        ? rawPath
        : (rawPath.startsWith('storage/') ? '/$rawPath' : '/storage/$rawPath');

    final base = Uri.tryParse(ApiConfig.baseUrl);
    if (base != null && base.hasScheme && base.host.isNotEmpty) {
      return base
          .replace(path: normalizedPath, query: null, fragment: null)
          .toString();
    }
  }

  final directUrl = category.iconUrl?.trim();
  if (directUrl != null && directUrl.isNotEmpty) {
    return directUrl;
  }

  return null;
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

Color? _colorFromName(String name) {
  if (name.contains('merah')) return const Color(0xFFE53935);
  if (name.contains('biru')) return const Color(0xFF1E88E5);
  if (name.contains('hijau')) return const Color(0xFF43A047);
  if (name.contains('kuning')) return const Color(0xFFF9A825);
  if (name.contains('ungu')) return const Color(0xFF8E24AA);
  return null;
}

import 'package:flutter/material.dart';

import '../../models/category_model.dart';

/// Ikon dan warna yang dipakai untuk merepresentasikan sebuah kategori lagu
/// pada pemilih kategori berbentuk grid ikon.
class CategoryIconSpec {
  final IconData icon;
  final Color color;

  const CategoryIconSpec(this.icon, this.color);
}

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

  // Warna khusus saat nama kategori menyebut warna buku.
  final color =
      _colorFromName(name) ?? _categoryPalette[index % _categoryPalette.length];

  return CategoryIconSpec(icon, color);
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

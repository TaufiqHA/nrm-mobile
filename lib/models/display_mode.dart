/// Pilihan cara menampilkan lagu di layar utama.
enum DisplayMode {
  /// Mode default: video/audio YouTube diputar seperti biasa.
  normal,

  /// Mode teks: hanya menampilkan lirik tanpa video maupun audio.
  textOnly,
}

extension DisplayModeInfo on DisplayMode {
  String get label {
    switch (this) {
      case DisplayMode.normal:
        return 'Mode Biasa (Musik + Video)';
      case DisplayMode.textOnly:
        return 'Teks Only (Lirik Saja)';
    }
  }

  String get shortLabel {
    switch (this) {
      case DisplayMode.normal:
        return 'Mode Biasa';
      case DisplayMode.textOnly:
        return 'Teks Only';
    }
  }
}

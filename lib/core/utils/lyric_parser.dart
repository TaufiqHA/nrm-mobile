/// Satu bait/ayat lirik yang sudah dipisahkan dari teks lagu.
class LyricVerse {
  final String? heading;
  final String body;

  const LyricVerse({this.heading, required this.body});

  bool get isEmpty => heading == null && body.trim().isEmpty;

  /// Label yang ditampilkan di aplikasi. Bila lirik tidak punya judul bait,
  /// gunakan nomor urut ("Ayat 1", "Ayat 2", dst.).
  String headingLabel(int index) {
    final value = heading?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Ayat ${index + 1}';
  }
}

/// Utilitas parsing lirik.
///
/// Format penyimpanan: setiap ayat dipisahkan oleh satu baris kosong.
/// Judul bait lama seperti "Ayat 1" atau "Reff" tetap dikenali lalu dilepas
/// dari isi agar tidak tampil dua kali.
class LyricParser {
  static final RegExp _headingPattern = RegExp(
    r'^(?:(?:ayat|bait)\s*\d+|reff|refrein|chorus|koor)$',
    caseSensitive: false,
  );

  static List<LyricVerse> parse(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return const [];

    final blocks = text
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty);

    final verses = <LyricVerse>[];
    for (final block in blocks) {
      final lines = block.split('\n');
      final firstLine = lines.first.trim();

      if (_headingPattern.hasMatch(firstLine)) {
        final body = lines.skip(1).join('\n').trim();
        verses.add(LyricVerse(heading: firstLine, body: body));
      } else {
        verses.add(LyricVerse(body: block));
      }
    }

    return verses;
  }

  /// Menggabungkan kembali daftar ayat menjadi format penyimpanan.
  static String join(Iterable<String> verses) {
    return verses
        .map((verse) => verse.trim())
        .where((verse) => verse.isNotEmpty)
        .join('\n\n');
  }
}

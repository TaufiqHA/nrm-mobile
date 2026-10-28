import '../../models/song_model.dart';

/// Membandingkan dua lagu bernomor berdasarkan nomor lagu (field `songsinger`).
///
/// Lagu bernomor diurutkan menaik (1, 2, 3, 10). Jika nomornya sama,
/// diurutkan berdasarkan judul.
int compareSongsByNumber(SongModel a, SongModel b) {
  final aNumber = a.songNumber;
  final bNumber = b.songNumber;

  if (aNumber != null && bNumber != null) {
    final byNumber = aNumber.compareTo(bNumber);
    if (byNumber != 0) return byNumber;
  } else if (aNumber != null) {
    return -1;
  } else if (bNumber != null) {
    return 1;
  }

  return a.songtitle.toLowerCase().compareTo(b.songtitle.toLowerCase());
}

/// Mengurutkan daftar lagu secara in-place berdasarkan nomor lagu.
///
/// Lagu tanpa nomor (mis. nama penyanyi biasa) diletakkan di akhir dengan
/// urutan asli dari sumber data tetap dipertahankan.
void sortSongsByNumber(List<SongModel> songs) {
  final numbered = songs.where((song) => song.songNumber != null).toList()
    ..sort(compareSongsByNumber);
  final unnumbered = songs.where((song) => song.songNumber == null).toList();

  songs
    ..clear()
    ..addAll(numbered)
    ..addAll(unnumbered);
}

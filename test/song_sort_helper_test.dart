import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/utils/song_sort_helper.dart';
import 'package:karaoke_app/models/song_model.dart';

SongModel _song(int id, String title, String singer) {
  return SongModel(
    songid: id,
    songtitle: title,
    songsinger: singer,
    songurl: 'https://www.youtube.com/watch?v=test$id',
    songcategory: 1,
  );
}

void main() {
  group('song_sort_helper', () {
    test('songNumber hanya membaca nilai numerik murni', () {
      expect(_song(1, 'A', '12').songNumber, 12);
      expect(_song(2, 'B', ' 7 ').songNumber, 7);
      expect(_song(3, 'C', 'Dewa 19').songNumber, isNull);
      expect(_song(4, 'D', '').songNumber, isNull);
    });

    test('sortSongsByNumber mengurutkan angka menaik bukan abjad', () {
      final songs = [
        _song(1, 'Zebra', '10'),
        _song(2, 'Alpha', '2'),
        _song(3, 'Beta', '1'),
      ];

      sortSongsByNumber(songs);

      expect(songs.map((s) => s.songtitle).toList(), ['Beta', 'Alpha', 'Zebra']);
    });

    test('lagu tanpa nomor diletakkan di akhir dengan urutan asli', () {
      final songs = [
        _song(1, 'Zebra Song', 'Avenged Sevenfold'),
        _song(2, 'Mango', '3'),
        _song(3, 'Apple', 'Dewa 19'),
        _song(4, 'Banana', '1'),
      ];

      sortSongsByNumber(songs);

      expect(
        songs.map((s) => s.songtitle).toList(),
        ['Banana', 'Mango', 'Zebra Song', 'Apple'],
      );
    });

    test('nomor sama diurutkan berdasarkan judul', () {
      final songs = [
        _song(1, 'Beta', '5'),
        _song(2, 'Alpha', '5'),
      ];

      sortSongsByNumber(songs);

      expect(songs.map((s) => s.songtitle).toList(), ['Alpha', 'Beta']);
    });
  });
}

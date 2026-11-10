import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/models/music_model.dart';

void main() {
  group('MusicModel', () {
    test('parses snake_case payload from API', () {
      final music = MusicModel.fromJson({
        'musicid': 7,
        'musictitle': 'Nyanyian Pagi',
        'musicartist': 'NRM',
        'musicfileid': 'drive-7',
        'musicfilename': 'pagi.mp3',
        'musicduration': 225,
        'cover_url': 'https://example.com/cover.jpg',
        'stream_url': 'https://example.com/api/music/7/stream',
        'songlyric': 'Ayat 1\nNyanyian pagi telah tiba',
        'is_active': 1,
        'sort_order': 3,
      });

      expect(music.musicid, 7);
      expect(music.musictitle, 'Nyanyian Pagi');
      expect(music.musicartist, 'NRM');
      expect(music.musicduration, 225);
      expect(music.coverUrl, 'https://example.com/cover.jpg');
      expect(music.streamUrl, 'https://example.com/api/music/7/stream');
      expect(music.songlyric, 'Ayat 1\nNyanyian pagi telah tiba');
      expect(music.isActive, isTrue);
      expect(music.sortOrder, 3);
    });

    test('empty optional fields become null', () {
      final music = MusicModel.fromJson({
        'musicid': '2',
        'musictitle': 'Lagu',
        'musicartist': '  ',
        'cover_url': '',
        'stream_url': null,
      });

      expect(music.musicid, 2);
      expect(music.musicartist, isNull);
      expect(music.coverUrl, isNull);
      expect(music.streamUrl, isNull);
      expect(music.songlyric, isNull);
    });

    test('formats duration as mm:ss and h:mm:ss', () {
      const short = MusicModel(musicid: 1, musictitle: 'A', musicduration: 225);
      const long = MusicModel(musicid: 2, musictitle: 'B', musicduration: 3725);
      const unknown = MusicModel(musicid: 3, musictitle: 'C');

      expect(short.formattedDuration, '03:45');
      expect(long.formattedDuration, '1:02:05');
      expect(unknown.formattedDuration, '--:--');
    });
  });
}

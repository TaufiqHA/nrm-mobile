import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/config/api_config.dart';
import 'package:karaoke_app/core/services/karaoke_media_controller.dart';
import 'package:karaoke_app/core/utils/media_url_helper.dart';
import 'package:karaoke_app/models/song_model.dart';

void main() {
  setUp(() {
    ApiConfig.customBaseUrl = 'https://example.com/api';
  });

  tearDown(() {
    ApiConfig.customBaseUrl = null;
  });

  group('MediaUrlHelper', () {
    test('menggabungkan path relatif ke origin storage', () {
      expect(
        MediaUrlHelper.resolve('songs/1/video.mp4'),
        'https://example.com/storage/songs/1/video.mp4',
      );
      expect(
        MediaUrlHelper.resolve('/storage/songs/1/audio.mp3'),
        'https://example.com/storage/songs/1/audio.mp3',
      );
    });

    test('mengarahkan ulang host localhost ke origin API', () {
      expect(
        MediaUrlHelper.resolve(
          'http://localhost:8000/storage/songs/2/video.mp4',
        ),
        'https://example.com/storage/songs/2/video.mp4',
      );
    });

    test('mempertahankan URL absolut non-lokal', () {
      const url = 'https://cdn.example.org/songs/3/video.mp4';
      expect(MediaUrlHelper.resolve(url), url);
    });

    test('mendeteksi jenis media', () {
      expect(MediaUrlHelper.isYoutube('https://youtu.be/abc'), isTrue);
      expect(MediaUrlHelper.isDirectVideo('songs/1/video.mp4'), isTrue);
      expect(MediaUrlHelper.isDirectAudio('songs/1/audio.mp3'), isTrue);
      expect(MediaUrlHelper.isDirectVideo('songs/1/audio.mp3'), isFalse);
      expect(MediaUrlHelper.resolve('   '), isNull);
    });
  });

  group('SongModel media', () {
    test('membaca songvideourl dan menandai hasVideo', () {
      final song = SongModel.fromJson({
        'songid': 1,
        'songtitle': 'Judul',
        'songsinger': '1',
        'songurl': 'https://example.com/storage/songs/1/audio.mp3',
        'songvideourl': 'https://example.com/storage/songs/1/video.mp4',
        'songcategory': 1,
      });

      expect(song.hasVideo, isTrue);
      expect(song.songvideourl, contains('video.mp4'));
    });

    test('membaca songyoutubeurl asli', () {
      final song = SongModel.fromJson({
        'songid': 3,
        'songtitle': 'Judul',
        'songsinger': '3',
        'songurl': 'https://example.com/storage/songs/3/audio.mp3',
        'songyoutubeurl': 'https://www.youtube.com/watch?v=abcdefghijk',
        'songcategory': 1,
      });

      expect(song.songyoutubeurl, contains('youtube.com'));
    });

    test('songvideourl kosong dianggap tidak punya video', () {
      final song = SongModel.fromJson({
        'songid': 2,
        'songtitle': 'Judul',
        'songsinger': '2',
        'songurl': 'https://youtu.be/abcdefghijk',
        'songvideourl': '   ',
        'songcategory': 1,
      });

      expect(song.hasVideo, isFalse);
      expect(song.songvideourl, isNull);
    });
  });

  test('konversi semitone ke faktor pitch', () {
    expect(KaraokeMediaController.pitchFactorForSemitones(0), 1.0);
    expect(
      KaraokeMediaController.pitchFactorForSemitones(12),
      closeTo(2.0, 0.000001),
    );
    expect(
      KaraokeMediaController.pitchFactorForSemitones(-12),
      closeTo(0.5, 0.000001),
    );
  });

  test('tempo dibatasi pada rentang 0.75x sampai 1.25x', () {
    expect(KaraokeMediaController.clampRate(0.5), 0.75);
    expect(KaraokeMediaController.clampRate(1.0), 1.0);
    expect(KaraokeMediaController.clampRate(1.5), 1.25);
  });

  test(
    'label tempo memakai 1 untuk tempo asli dan minus untuk lebih lambat',
    () {
      expect(KaraokeMediaController.tempoLevelLabelForRate(0.75), '-5');
      expect(KaraokeMediaController.tempoLevelLabelForRate(0.80), '-4');
      expect(KaraokeMediaController.tempoLevelLabelForRate(0.85), '-3');
      expect(KaraokeMediaController.tempoLevelLabelForRate(0.90), '-2');
      expect(KaraokeMediaController.tempoLevelLabelForRate(0.95), '-1');
      expect(KaraokeMediaController.tempoLevelLabelForRate(1.00), '1');
      expect(KaraokeMediaController.tempoLevelLabelForRate(1.05), '2');
      expect(KaraokeMediaController.tempoLevelLabelForRate(1.10), '3');
      expect(KaraokeMediaController.tempoLevelLabelForRate(1.15), '4');
      expect(KaraokeMediaController.tempoLevelLabelForRate(1.20), '5');
      expect(KaraokeMediaController.tempoLevelLabelForRate(1.25), '6');
    },
  );
}

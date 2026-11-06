import '../../models/music_model.dart';
import 'music_service.dart';

class DummyMusicService implements MusicService {
  final List<MusicModel> _music;

  DummyMusicService([List<MusicModel>? initialMusic])
    : _music =
          initialMusic ??
          const [
            MusicModel(
              musicid: 1,
              musictitle: 'Nyanyian Pagi',
              musicartist: 'NRM',
              musicduration: 225,
              streamUrl: 'https://example.com/music/1/stream',
            ),
            MusicModel(
              musicid: 2,
              musictitle: 'Nyanyian Sore',
              musicartist: 'NRM',
              musicduration: 198,
              streamUrl: 'https://example.com/music/2/stream',
            ),
          ];

  @override
  Future<List<MusicModel>> getMusic({String? search}) async {
    final query = search?.trim().toLowerCase();
    if (query == null || query.isEmpty) {
      return List.unmodifiable(_music);
    }

    return _music.where((item) {
      return item.musictitle.toLowerCase().contains(query) ||
          (item.musicartist ?? '').toLowerCase().contains(query);
    }).toList();
  }
}

import '../../models/music_model.dart';

abstract class MusicService {
  Future<List<MusicModel>> getMusic({String? search});
}

import '../../models/music_model.dart';
import '../../models/song_model.dart';

/// Menyesuaikan data musik ke model lagu agar komponen UI katalog/playlist
/// yang sudah ada di halaman karaoke bisa dipakai ulang tanpa duplikasi.
extension MusicSongAdapter on MusicModel {
  SongModel toSongModel() {
    return SongModel(
      songid: musicid,
      songtitle: musictitle,
      songsinger: musicartist ?? 'NRM',
      songurl: streamUrl ?? '',
      songcategory: 0,
      songlyric: songlyric,
      songduration: formattedDuration,
    );
  }
}

List<SongModel> musicToSongModels(Iterable<MusicModel> music) {
  return music.map((item) => item.toSongModel()).toList(growable: false);
}

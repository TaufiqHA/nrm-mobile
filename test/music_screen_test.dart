import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/services/dummy_application_service.dart';
import 'package:karaoke_app/core/services/dummy_music_service.dart';
import 'package:karaoke_app/core/services/music_service.dart';
import 'package:karaoke_app/models/application_model.dart';
import 'package:karaoke_app/models/music_model.dart';
import 'package:karaoke_app/screens/music/music_screen.dart';
import 'package:karaoke_app/screens/music/widgets/music_lyrics_display.dart';
import 'package:karaoke_app/screens/music/widgets/music_player_display.dart';
import 'package:karaoke_app/screens/user/widgets/player_controls.dart';
import 'package:karaoke_app/screens/user/widgets/song_catalog_playlist_section.dart';
import 'package:karaoke_app/widgets/ad_slot_view.dart';
import 'package:media_kit_video/media_kit_video.dart';

const _topAd = 'https://example.com/ads/top.jpg';
const _bottomAd = 'https://example.com/ads/bottom.jpg';

class _CountingMusicService implements MusicService {
  _CountingMusicService(this._music);

  final List<MusicModel> _music;
  int calls = 0;

  @override
  Future<List<MusicModel>> getMusic({String? search}) async {
    calls++;
    return List.unmodifiable(_music);
  }
}

void main() {
  Future<void> pumpMusicScreen(
    WidgetTester tester, {
    List<MusicModel>? music,
    MusicService? musicService,
    ApplicationModel? appConfig,
    Size size = const Size(900, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MusicScreen(
          musicService: musicService ?? DummyMusicService(music),
          applicationService: DummyApplicationService(appConfig),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('music screen shows player, song list, and playlist', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester);

    expect(find.text('Nyanyian Rohani Methodist'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('Putar lagu rohani dari Google Drive'), findsNothing);
    expect(find.byIcon(Icons.headphones_rounded), findsNothing);

    // Area player, daftar lagu, dan playlist dari UI halaman karaoke.
    expect(find.byType(MusicPlayerDisplay), findsOneWidget);
    expect(find.text('Pilih musik untuk diputar'), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(find.text('Cari lagu...'), findsOneWidget);
    expect(find.text('daftar lagu'), findsOneWidget);
    expect(find.text('playlist'), findsOneWidget);
    expect(find.text('Nyanyian Pagi'), findsOneWidget);
    expect(find.text('Nyanyian Sore'), findsOneWidget);
    expect(find.text('Playlist masih kosong'), findsOneWidget);

    // Kontrol pemutaran audio.
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    // Menu Musik tidak boleh memiliki pemutar video.
    expect(find.byType(Video), findsNothing);
  });

  testWidgets('tapping a song adds it to the playlist', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester);

    await tester.tap(find.byKey(const ValueKey('search_song_card_2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('playlist_song_card_2')), findsOneWidget);
    expect(find.text('Nyanyian Sore'), findsNWidgets(2));
    expect(find.text('Playlist masih kosong'), findsNothing);
  });

  testWidgets('playing from the playlist shows the song in the player', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester);

    // Tambahkan ke playlist lalu putar dari kartu playlist.
    await tester.tap(find.byKey(const ValueKey('search_song_card_2')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('playlist_song_card_2')),
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    await tester.pumpAndSettle();

    // Judul tampil di kontrol pemutaran.
    expect(
      find.descendant(
        of: find.byType(PlayerControls),
        matching: find.text('Nyanyian Sore'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'lyrics button replaces the song card with a larger lyric panel',
    (WidgetTester tester) async {
      const lyric = 'Ayat 1\nBeribu lidah patutlah\n\nReff\nMenyembah Dia';
      await pumpMusicScreen(
        tester,
        music: const [
          MusicModel(
            musicid: 2,
            musictitle: 'Nyanyian Sore',
            musicartist: 'NRM',
            musicduration: 198,
            streamUrl: 'https://example.com/music/2/stream',
            songlyric: lyric,
          ),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('search_song_card_2')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('playlist_song_card_2')),
          matching: find.byIcon(Icons.play_arrow_rounded),
        ),
      );
      await tester.pumpAndSettle();

      final normalHeight = tester
          .getSize(find.byType(MusicPlayerDisplay))
          .height;

      await tester.tap(find.byTooltip('Tampilkan lirik'));
      await tester.pumpAndSettle();

      final lyricsFinder = find.byKey(const ValueKey('music_lyrics_display'));
      expect(lyricsFinder, findsOneWidget);
      expect(find.byType(MusicPlayerDisplay), findsNothing);
      expect(find.textContaining('Beribu lidah patutlah'), findsOneWidget);
      expect(find.text('Reff'), findsOneWidget);
      expect(tester.getSize(lyricsFinder).height, greaterThan(normalHeight));

      await tester.tap(find.byTooltip('Tutup lirik'));
      await tester.pumpAndSettle();

      expect(find.byType(MusicLyricsDisplay), findsNothing);
      expect(find.byType(MusicPlayerDisplay), findsOneWidget);
    },
  );

  testWidgets('lyrics panel fits on a small phone without overflow', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(
      tester,
      size: const Size(360, 640),
      music: const [
        MusicModel(
          musicid: 2,
          musictitle: 'Nyanyian Sore',
          musicartist: 'NRM',
          musicduration: 198,
          streamUrl: 'https://example.com/music/2/stream',
          songlyric: 'Ayat 1\nBeribu lidah patutlah',
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('search_song_card_2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('playlist_song_card_2')),
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tampilkan lirik'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('music_lyrics_display')), findsOneWidget);
    expect(find.textContaining('Beribu lidah patutlah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lyrics button is disabled when the song has no lyric', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester);

    await tester.tap(find.byKey(const ValueKey('search_song_card_2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('playlist_song_card_2')),
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Lirik belum tersedia'), findsOneWidget);

    await tester.tap(find.byTooltip('Lirik belum tersedia'));
    await tester.pumpAndSettle();

    expect(find.byType(MusicLyricsDisplay), findsNothing);
  });

  testWidgets('tuning button opens Nada & Tempo and changes pitch', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester);

    // Belum ada lagu aktif: tombol nada belum tersedia.
    expect(find.byTooltip('Nada & Tempo'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('search_song_card_2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('playlist_song_card_2')),
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Nada & Tempo'), findsOneWidget);

    await tester.tap(find.byTooltip('Nada & Tempo'));
    await tester.pumpAndSettle();

    expect(find.text('Nada & Tempo'), findsOneWidget);

    await tester.tap(find.byTooltip('Naikkan nada'));
    await tester.pumpAndSettle();

    expect(find.text('+1'), findsWidgets);

    // Tutup panel dan pastikan ringkasan nada ikut berubah.
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Nada +1 · Tempo 1'), findsOneWidget);
  });

  testWidgets('cover player and controls are positioned above the catalog', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester);

    final displayY = tester.getCenter(find.byType(MusicPlayerDisplay)).dy;
    final controlsY = tester.getCenter(find.byType(PlayerControls)).dy;
    final catalogY = tester
        .getCenter(find.byType(SongCatalogPlaylistSection))
        .dy;

    expect(displayY, lessThan(controlsY));
    expect(controlsY, lessThan(catalogY));
  });

  testWidgets('logout button shows confirmation dialog', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Keluar'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Keluar'), findsNothing);
  });

  testWidgets('landscape layout renders player and catalog without overflow', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester, size: const Size(900, 500));

    expect(find.text('daftar lagu'), findsOneWidget);
    expect(find.text('playlist'), findsOneWidget);
    expect(find.byType(MusicPlayerDisplay), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone portrait layout renders without overflow', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester, size: const Size(360, 640));

    expect(find.text('daftar lagu'), findsOneWidget);
    expect(find.text('playlist'), findsOneWidget);
    expect(find.byType(MusicPlayerDisplay), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state is shown when no music exists', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(tester, music: const <MusicModel>[]);

    expect(find.text('Belum ada musik'), findsOneWidget);
  });

  testWidgets('top and bottom ad slots render and can be closed separately', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(
      tester,
      appConfig: const ApplicationModel(
        applicationid: 1,
        applicationcompany: 'PT Uji',
        applicationname: 'Karaoke Uji',
        applicationadsmusiktop: _topAd,
        applicationadsmusikbottom: _bottomAd,
      ),
    );

    expect(find.byKey(const ValueKey('ad_slot_top')), findsOneWidget);
    expect(find.byKey(const ValueKey('ad_slot_bottom')), findsOneWidget);

    tester
        .widget<AdSlotView>(find.byKey(const ValueKey('ad_slot_top')))
        .onClose!();
    await tester.pump();

    expect(find.byKey(const ValueKey('ad_slot_top')), findsNothing);
    expect(find.byKey(const ValueKey('ad_slot_bottom')), findsOneWidget);
  });

  testWidgets('inactive ad slots do not render ad content', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(
      tester,
      appConfig: const ApplicationModel(
        applicationid: 1,
        applicationcompany: 'PT Uji',
        applicationname: 'Karaoke Uji',
        applicationadsmusiktop: _topAd,
        applicationadsmusiktopactive: 'N',
        applicationadsmusikbottom: _bottomAd,
        applicationadsmusikbottomactive: 'N',
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ad_slot_top')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ad_slot_bottom')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('music page popup ad shows once when the page opens', (
    WidgetTester tester,
  ) async {
    await pumpMusicScreen(
      tester,
      appConfig: const ApplicationModel(
        applicationid: 1,
        applicationcompany: 'PT Uji',
        applicationname: 'Karaoke Uji',
        applicationadsmusik: _topAd,
      ),
    );

    expect(find.byKey(const ValueKey('ad_popup_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ad_popup_close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ad_popup_dialog')), findsNothing);
  });

  testWidgets('pull to refresh on song list reloads the music', (
    WidgetTester tester,
  ) async {
    final service = _CountingMusicService(const [
      MusicModel(
        musicid: 1,
        musictitle: 'Nyanyian Pagi',
        musicartist: 'NRM',
        musicduration: 225,
        streamUrl: 'https://example.com/music/1/stream',
      ),
    ]);

    await pumpMusicScreen(tester, musicService: service);

    expect(service.calls, 1);
    expect(find.text('Nyanyian Pagi'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Nyanyian Pagi'), findsOneWidget);
  });

  testWidgets('pull to refresh on empty playlist reloads the music', (
    WidgetTester tester,
  ) async {
    final service = _CountingMusicService(const [
      MusicModel(
        musicid: 1,
        musictitle: 'Nyanyian Pagi',
        musicartist: 'NRM',
        musicduration: 225,
        streamUrl: 'https://example.com/music/1/stream',
      ),
    ]);

    await pumpMusicScreen(tester, musicService: service);

    expect(service.calls, 1);
    expect(find.text('Playlist masih kosong'), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Playlist masih kosong'), findsOneWidget);
  });
}

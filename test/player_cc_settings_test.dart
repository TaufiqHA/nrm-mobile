import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/models/song_model.dart';
import 'package:karaoke_app/screens/user/widgets/playback_tuning_sheet.dart';
import 'package:karaoke_app/screens/user/widgets/player_controls.dart';
import 'package:karaoke_app/screens/user/widgets/youtube_video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  const testSong = SongModel(
    songid: 1,
    songtitle: 'Test Song Title',
    songsinger: 'Test Singer',
    songduration: '03:30',
    songurl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    songcategory: 1,
  );

  group('Player Native CC & Settings Tests', () {
    testWidgets(
      'PlayerControls does NOT render custom CC and Settings buttons',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerControls(
                song: testSong,
                isPlaying: true,
                hasSong: true,
                currentPosition: const Duration(seconds: 30),
                totalDuration: const Duration(minutes: 3, seconds: 30),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Pastikan tombol custom CC dan Pengaturan Pemutar TIDAK ADA di PlayerControls
        expect(find.byTooltip('Aktifkan Subtitle (CC)'), findsNothing);
        expect(find.byTooltip('Matikan Subtitle (CC)'), findsNothing);
        expect(find.byTooltip('Pengaturan Pemutar'), findsNothing);
        expect(find.byIcon(Icons.closed_caption_rounded), findsNothing);
        expect(find.byIcon(Icons.closed_caption_off_rounded), findsNothing);
        expect(find.byIcon(Icons.settings_rounded), findsNothing);
      },
    );

    test('YoutubePlayerParams enables native controls and captions', () {
      const params = YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        showVideoAnnotations: false,
        pointerEvents: PointerEvents.auto,
        mute: false,
        enableCaption: true,
        captionLanguage: 'id',
        interfaceLanguage: 'id',
      );

      expect(params.showControls, isTrue);
      expect(params.enableCaption, isTrue);
      expect(params.showFullscreenButton, isTrue);
      expect(params.captionLanguage, equals('id'));
      expect(params.interfaceLanguage, equals('id'));

      final map = params.toMap();
      expect(map['controls'], equals(1));
      expect(map['cc_load_policy'], equals(1));
      expect(map['cc_lang_pref'], equals('id'));
      expect(map['hl'], equals('id'));
    });

    testWidgets(
      'buildFullscreenOverlay renders song details and exit button cleanly',
      (tester) async {
        bool exitedFullscreen = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    YoutubeVideoPlayerWidget.buildFullscreenOverlay(
                      context: context,
                      songTitle: 'Test Song',
                      songSinger: 'Test Singer',
                      onExitFullScreen: () => exitedFullscreen = true,
                    ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Info lagu
        expect(find.text('Test Song - Test Singer'), findsOneWidget);

        // Exit fullscreen button
        final exitIcon = find.byIcon(Icons.fullscreen_exit_rounded);
        expect(exitIcon, findsOneWidget);
        await tester.tap(exitIcon);
        expect(exitedFullscreen, isTrue);

        // Tidak ada tombol custom CC / settings di overlay
        expect(find.byIcon(Icons.closed_caption_rounded), findsNothing);
        expect(find.byIcon(Icons.settings_rounded), findsNothing);
      },
    );

    testWidgets('PlayerControls membuka panel Nada & Tempo', (tester) async {
      var opened = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              song: testSong,
              isPlaying: true,
              hasSong: true,
              totalDuration: const Duration(minutes: 3, seconds: 30),
              tuningEnabled: true,
              pitchSemitones: 2,
              tempoRate: 0.9,
              onOpenTuning: () => opened++,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nada +2 · Tempo -2'), findsOneWidget);

      await tester.tap(find.byTooltip('Nada & Tempo'));
      expect(opened, 1);
    });

    testWidgets('PlaybackTuningSheet mengubah nada dan tempo', (tester) async {
      var pitch = 0;
      var tempo = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackTuningSheet(
              pitchSemitones: 0,
              tempoRate: 1.0,
              onPitchChanged: (value) => pitch = value,
              onTempoChanged: (value) => tempo = value,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nada & Tempo'), findsOneWidget);

      // Tempo asli 1.00x ditampilkan sebagai label 1.
      expect(find.text('1'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Naikkan nada'));
      await tester.pump();
      expect(pitch, 1);

      await tester.tap(find.byTooltip('Turunkan tempo'));
      await tester.pump();
      expect(tempo, closeTo(0.95, 0.0001));

      await tester.tap(find.byTooltip('Turunkan tempo'));
      await tester.pump();
      expect(tempo, closeTo(0.90, 0.0001));

      await tester.tap(find.byTooltip('Naikkan tempo'));
      await tester.pump();
      expect(tempo, closeTo(0.95, 0.0001));

      await tester.tap(find.text('Kembalikan ke asli'));
      await tester.pump();
      expect(pitch, 0);
      expect(tempo, 1.0);
    });

    testWidgets('tempo tidak melewati batas 0.75x dan 1.25x', (tester) async {
      var tempo = 1.25;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackTuningSheet(
              pitchSemitones: 0,
              tempoRate: 1.25,
              onPitchChanged: (_) {},
              onTempoChanged: (value) => tempo = value,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('6'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Naikkan tempo'));
      await tester.pump();
      expect(tempo, 1.25);

      for (var i = 0; i < 11; i++) {
        await tester.tap(find.byTooltip('Turunkan tempo'));
        await tester.pump();
      }
      expect(tempo, closeTo(0.75, 0.0001));
      expect(find.text('-5'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Turunkan tempo'));
      await tester.pump();
      expect(tempo, closeTo(0.75, 0.0001));
    });
  });
}

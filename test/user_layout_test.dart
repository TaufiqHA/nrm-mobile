import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karaoke_app/core/services/dummy_category_service.dart';
import 'package:karaoke_app/core/services/dummy_song_service.dart';
import 'package:karaoke_app/screens/login_screen.dart';
import 'package:karaoke_app/models/category_model.dart';
import 'package:karaoke_app/models/song_model.dart';
import 'package:karaoke_app/screens/profile/profile_screen.dart';
import 'package:karaoke_app/screens/user/user_main_layout.dart';
import 'package:karaoke_app/screens/user/widgets/player_controls.dart';
import 'package:karaoke_app/screens/user/widgets/player_display.dart';
import 'package:karaoke_app/screens/user/widgets/song_catalog_playlist_section.dart';
import 'package:karaoke_app/screens/user/widgets/song_search_modal.dart';
import 'package:karaoke_app/screens/user/widgets/youtube_video_player.dart';
import 'package:karaoke_app/services/cast/smart_tv_cast_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UserMainLayout renders header, player display, player controls, and embedded song catalog & playlist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final dummySongService = DummySongService();
    final dummyCatService = DummyCategoryService();

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: dummySongService,
          categoryService: dummyCatService,
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verifikasi Header (Minimalis tanpa subteks & tanpa tombol cari)
    expect(find.text('Nyanyian Rohani Methodist'), findsOneWidget);
    expect(find.text('Ruang Bernyanyi'), findsNothing);
    expect(find.byTooltip('Cari Lagu'), findsNothing);
    expect(find.byTooltip('Manajemen Profil'), findsNothing);
    expect(find.byTooltip('Keluar'), findsOneWidget);

    // 2. Verifikasi Sub-widget Utama
    expect(find.byType(PlayerDisplay), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(find.byType(SongCatalogPlaylistSection), findsOneWidget);

    // 3. Verifikasi Bagian Cari Lagu & Playlist langsung di layar utama
    expect(find.text('Cari lagu...'), findsOneWidget);
    expect(find.text('daftar lagu'), findsOneWidget);
    expect(find.text('playlist'), findsOneWidget);
    // Panel filter sudah dipindah ke halaman landing login
    expect(find.text('Filter Lagu'), findsNothing);
    expect(find.text('judul lagu'), findsNothing);
    expect(find.text('pencipta'), findsNothing);
    expect(find.text('nada'), findsNothing);

    // 4. Verifikasi Status Awal Player Kosong
    expect(find.text('Player'), findsWidgets);
    expect(find.text('STANDBY'), findsNothing);
    expect(find.byType(YoutubeVideoPlayerWidget), findsNothing);

    // 5. Pilih lagu dari hasil pencarian (menambahkan ke playlist) lalu tekan tombol Putar di playlist
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();

    expect(find.text('Playlist masih kosong'), findsNothing);
    await tester.tap(find.byTooltip('Putar Lagu'));
    await tester.pumpAndSettle();

    // 6. Verifikasi Lagu dan Video YouTube muncul setelah dipilih
    expect(find.textContaining('Sial'), findsWidgets);
    expect(find.textContaining('Mahalini'), findsWidgets);
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);
    expect(find.text('Video'), findsNothing);
    expect(find.text('Visualizer'), findsNothing);
  });

  testWidgets('UserMainLayout search, filter category, and play song test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi katalog memuat lagu di layar
    expect(find.text('Rungkad'), findsOneWidget);
    expect(find.text('Happy Asmara'), findsOneWidget);

    // Tap kotak search untuk membuka modal pencarian besar
    await tester.tap(find.text('Cari lagu...'));
    await tester.pumpAndSettle();
    expect(find.byType(SongSearchModal), findsOneWidget);

    // Filter pencarian di dalam modal
    await tester.enterText(find.byKey(SongSearchModal.fieldKey), 'Rungkad');
    await tester.pumpAndSettle();

    final modal = find.byType(SongSearchModal);
    expect(
      find.descendant(
        of: modal,
        matching: find.byKey(const ValueKey('song_search_modal_result_2')),
      ),
      findsOneWidget,
    );
    expect(find.descendant(of: modal, matching: find.text('Sial')), findsNothing);

    // Tap hasil untuk menambahkan ke playlist; modal tetap terbuka
    await tester.tap(find.byKey(const ValueKey('song_search_modal_result_2')));
    await tester.pumpAndSettle();
    expect(find.byType(SongSearchModal), findsOneWidget);
    // Tombol tambah berubah menjadi centang
    expect(
      find.descendant(
        of: find.byType(SongSearchModal),
        matching: find.byTooltip('Sudah di Playlist'),
      ),
      findsOneWidget,
    );

    // Tutup modal lalu putar lagu dari playlist
    await tester.tap(find.byTooltip(SongSearchModal.closeTooltip));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Putar Lagu'));
    await tester.pumpAndSettle();

    // Verifikasi lagu yang diputar di Player berubah menjadi 'Rungkad'
    expect(find.textContaining('Rungkad'), findsWidgets);

    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Putar Lagu'));
    await tester.pumpAndSettle();

    // Verifikasi lagu baru berikutnya berhasil ter-load di player
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);
  });

  testWidgets('Modal search tidak penuh ke atas saat keyboard muncul', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cari lagu...'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(SongSearchModal.sheetKey);
    expect(sheet, findsOneWidget);

    final rect = tester.getRect(sheet);
    // Tidak menempel ke atas layar walau keyboard terbuka.
    expect(rect.top, greaterThan(0));
    // Tinggi maksimal 90% dari area yang tersedia setelah keyboard.
    expect(rect.height, lessThanOrEqualTo((800 - 300) * 0.9 + 0.5));
  });

  testWidgets('Tombol tambah berubah menjadi centang setelah lagu masuk playlist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cari lagu...'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('song_search_modal_result_1')));
    await tester.pumpAndSettle();

    // Centang muncul di modal setelah lagu ditambahkan
    expect(
      find.descendant(
        of: find.byType(SongSearchModal),
        matching: find.byTooltip('Sudah di Playlist'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(SongSearchModal.closeTooltip));
    await tester.pumpAndSettle();

    // Kartu hasil pencarian di halaman utama juga menampilkan centang
    expect(find.byTooltip('Sudah di Playlist'), findsOneWidget);

    // Buka modal lagi: lagu yang sudah di playlist tetap bercentang
    await tester.tap(find.text('Cari lagu...'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sudah di Playlist'), findsWidgets);
  });

  testWidgets('UserMainLayout queue management test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi awal: playlist kosong
    expect(find.text('Playlist masih kosong'), findsOneWidget);

    // Tambah lagu ke playlist via tombol (+)
    final queueButtons = find.byTooltip('Tambah ke Playlist');
    expect(queueButtons, findsWidgets);

    // Klik tombol tambah ke playlist untuk lagu pertama
    await tester.tap(queueButtons.first);
    await tester.pumpAndSettle();

    // Verifikasi playlist memuat 1 lagu, tanpa tombol handle/hapus
    expect(find.text('Playlist masih kosong'), findsNothing);
    expect(find.byTooltip('Hapus dari Playlist'), findsNothing);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
    expect(
      find.byType(ReorderableDelayedDragStartListener),
      findsOneWidget,
    );

    // Swipe ke kiri untuk menghapus lagu dari playlist
    await tester.drag(
      find.byKey(const ValueKey('playlist_song_card_1')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Playlist masih kosong'), findsOneWidget);
  });

  testWidgets('UserMainLayout playback controls and volume test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tambah lagu ke playlist dan putar
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Putar Lagu'));
    await tester.pumpAndSettle();

    // Tombol Berhenti (Stop)
    final stopBtn = find.byIcon(Icons.stop_rounded);
    expect(stopBtn, findsOneWidget);
    await tester.tap(stopBtn);
    await tester.pump(const Duration(milliseconds: 200));

    // Tombol Putar (Play) untuk melanjutkan
    final playBtn = find.byIcon(Icons.play_arrow_rounded);
    expect(playBtn, findsWidgets);
    await tester.tap(playBtn.first);
    await tester.pump(const Duration(milliseconds: 200));

    // Tombol Jeda (Pause)
    final pauseBtn = find.byIcon(Icons.pause_rounded);
    expect(pauseBtn, findsWidgets);
    await tester.tap(pauseBtn.first);
    await tester.pump(const Duration(milliseconds: 200));

    // Tombol Next (Lagu Berikutnya) pada kontroler tablet/desktop
    final nextBtn = find.byTooltip('Lagu Berikutnya');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Kontrol Bisukan (Mute)
    final muteBtn = find.byIcon(Icons.volume_up_rounded).first;
    await tester.tap(muteBtn);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.volume_off_rounded), findsWidgets);

    // Batal Bisukan (Unmute)
    final unMuteBtn = find.byIcon(Icons.volume_off_rounded).first;
    await tester.tap(unMuteBtn);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);

    // Tombol Layar Penuh (Fullscreen)
    final fsBtn = find.byIcon(Icons.fullscreen_rounded);
    if (fsBtn.evaluate().isNotEmpty) {
      await tester.tap(fsBtn.first);
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('UserMainLayout cinema player display test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Masukkan lagu ke playlist dan putar
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Putar Lagu'));
    await tester.pumpAndSettle();

    // Video player langsung aktif di layar panggung tanpa tombol visualizer
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);
    expect(find.text('Visualizer'), findsNothing);
    expect(find.text('Video'), findsNothing);
  });

  testWidgets('UserMainLayout responsive mobile layout test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 680);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('FLUTTER_ERROR_CONTEXT: ${details.context?.toDescription()}');
      if (details.informationCollector != null) {
        for (final node in details.informationCollector!()) {
          debugPrint('COLLECTOR: ${node.toDescription()}');
        }
      }
      oldHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldHandler);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi tetap menampilkan komponen utama secara vertikal tanpa overflow awal
    expect(find.byType(PlayerDisplay), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(find.text('Player'), findsWidgets);

    // Pastikan tidak ada exception overflow sama sekali
    expect(tester.takeException(), isNull);
  });

  testWidgets('UserMainLayout does not display profile button and disables ProfileScreen access', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip('Manajemen Profil'), findsNothing);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('LoginScreen play button navigates to UserMainLayout', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(categoryService: DummyCategoryService()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Klik to play'));
    await tester.pumpAndSettle();

    // Verifikasi diarahkan ke UserMainLayout
    expect(find.byType(UserMainLayout), findsOneWidget);
  });

  testWidgets('Kotak kategori landing pas dengan nama kategori terpanjang', (WidgetTester tester) async {
    const longName = 'Indonesia Lirik + Musik (buku merah)';
    // Data kategori hanya berisi nama pendek; kotak tetap harus muat nama terpanjang.
    final categories = [
      CategoryModel(songcategoryid: 1, songcategoryname: 'Pop'),
      CategoryModel(songcategoryid: 2, songcategoryname: 'Piano + Lirik'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(categoryService: DummyCategoryService(categories)),
      ),
    );
    await tester.pumpAndSettle();

    final boxSize = tester.getSize(find.byKey(const ValueKey('landing_category_selector')));
    final painter = TextPainter(
      text: const TextSpan(
        text: longName,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    // Lebar mengikuti teks terpanjang + ikon, jarak, panah, padding, dan buffer.
    expect(boxSize.width, greaterThanOrEqualTo(painter.width + 20 + 10 + 26 + 28 + 8));
    // Tidak melebihi lebar layar setelah padding halaman (24 kiri + 24 kanan).
    expect(boxSize.width, lessThanOrEqualTo(800 - 48));
  });

  testWidgets('UserMainLayout logout confirmation displays Nyanyian Rohani Methodist', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserMainLayout(isTestMode: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();

    expect(find.text('Apakah Anda yakin ingin keluar dari Nyanyian Rohani Methodist?'), findsOneWidget);
  });

  testWidgets('UserMainLayout cast to Smart TV modal and connection test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final castService = SmartTvCastService(isTestMode: true);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          castService: castService,
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi tombol Cast ada pada kontroler
    final castBtn = find.byIcon(Icons.cast_rounded);
    expect(castBtn, findsOneWidget);

    // Buka modal Cast ke TV
    await tester.tap(castBtn);
    await tester.pumpAndSettle();

    // Verifikasi modal terbuka dan menampilkan pencarian Smart TV
    expect(find.text('Cast ke TV'), findsOneWidget);
    expect(find.text('Mencari Smart TV di jaringan Wi-Fi...'), findsOneWidget);
    expect(find.text('Samsung Smart TV'), findsNothing);
    expect(find.text('Chromecast'), findsNothing);

    // Hubungkan menggunakan Kode TV
    await tester.enterText(find.byType(TextField).last, 'TV-ROOM-99');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hubungkan'));
    await tester.pumpAndSettle();

    // Modal tertutup dan status berubah menjadi terhubung (Icons.cast_connected_rounded)
    expect(find.byIcon(Icons.cast_connected_rounded), findsOneWidget);

    // Buka modal lagi untuk memverifikasi opsi Putus
    await tester.tap(find.byIcon(Icons.cast_connected_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Putus'), findsOneWidget);
    await tester.tap(find.text('Putus'));
    await tester.pumpAndSettle();

    // Kembali ke status tidak terhubung
    expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
  });

  testWidgets('UserMainLayout applies initial category filter from landing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
          initialCategoryFilter: 2,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Hanya lagu dari kategori terpilih yang tampil
    expect(find.text('Rungkad'), findsOneWidget);
    expect(find.text('Separuh Nafas'), findsNothing);

    // Panel filter lama (Nomor Lagu/Kategori/Nada) sudah tidak ada di layar utama
    expect(find.text('Filter Lagu'), findsNothing);
    expect(find.text('Nomor Lagu'), findsNothing);
    expect(find.text('Nada'), findsNothing);
  });

  testWidgets('UserMainLayout mengurutkan lagu berdasarkan nomor lagu', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final songs = [
      SongModel(
        songid: 1,
        songtitle: 'Zebra',
        songsinger: '10',
        songurl: 'https://youtu.be/a',
        songcategory: 1,
      ),
      SongModel(
        songid: 2,
        songtitle: 'Alpha',
        songsinger: '2',
        songurl: 'https://youtu.be/b',
        songcategory: 1,
      ),
      SongModel(
        songid: 3,
        songtitle: 'Beta',
        songsinger: '1',
        songurl: 'https://youtu.be/c',
        songcategory: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(songs),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Urutan tampil harus mengikuti nomor lagu (1, 2, 10), bukan abjad judul.
    final betaY = tester.getTopLeft(find.text('Beta')).dy;
    final alphaY = tester.getTopLeft(find.text('Alpha')).dy;
    final zebraY = tester.getTopLeft(find.text('Zebra')).dy;

    expect(betaY, lessThan(alphaY));
    expect(alphaY, lessThan(zebraY));
  });

  testWidgets('Kartu playlist memiliki tinggi sama dengan kartu daftar lagu', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchCard = find.byKey(const ValueKey('search_song_card_1'));
    expect(searchCard, findsOneWidget);

    await tester.tap(find.byTooltip('Tambah ke Playlist').first);
    await tester.pumpAndSettle();

    final playlistCard = find.byKey(const ValueKey('playlist_song_card_1'));
    expect(playlistCard, findsOneWidget);

    expect(
      tester.getSize(playlistCard).height,
      tester.getSize(searchCard).height,
    );
  });

  testWidgets('LoginScreen category selector passes selection to UserMainLayout', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(categoryService: DummyCategoryService()),
      ),
    );
    await tester.pumpAndSettle();

    // Label dan dropdown kategori tampil di halaman landing
    expect(find.text('Pilih Jenis Musik'), findsOneWidget);
    expect(find.text('Semua Kategori'), findsNothing);
    // Default otomatis memilih kategori pertama (Pop Indonesia, id 1)
    expect(find.text('Pop Indonesia'), findsOneWidget);

    await tester.tap(find.text('Pop Indonesia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dangdut & Koplo').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Klik to play'));
    await tester.pumpAndSettle();

    final layout = tester.widget<UserMainLayout>(find.byType(UserMainLayout));
    expect(layout.initialCategoryFilter, 2);
  });

  testWidgets('UserMainLayout tablet mode: player on left, search top-right, playlist bottom-right', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi SongCatalogPlaylistSection menggunakan axis: Axis.vertical pada tablet
    final catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(catalogFinder, findsOneWidget);
    final catalogWidget = tester.widget<SongCatalogPlaylistSection>(catalogFinder);
    expect(catalogWidget.axis, Axis.vertical);

    // 2. Verifikasi Posisi Horizontal: Player berada di kiri, Search & Playlist di kanan
    final playerCenter = tester.getCenter(find.byType(PlayerDisplay));
    final searchCenter = tester.getCenter(find.text('daftar lagu'));
    final playlistCenter = tester.getCenter(find.text('playlist'));

    expect(playerCenter.dx, lessThan(searchCenter.dx));
    expect(playerCenter.dx, lessThan(playlistCenter.dx));

    // 3. Verifikasi Posisi Vertikal pada kolom kanan: Cari lagu di atas, Playlist di bawah
    expect(searchCenter.dy, lessThan(playlistCenter.dy));

    // 4. Verifikasi tombol navigasi playback pada PlayerControls tablet memuat tombol Next
    expect(find.byTooltip('Lagu Berikutnya'), findsOneWidget);

    // 5. Verifikasi tidak ada error overflow pada mode tablet (PlayerControls bebas overflow)
    expect(tester.takeException(), isNull);
  });

  testWidgets('UserMainLayout tablet and desktop resolutions overflow-free verification', (WidgetTester tester) async {
    const resolutions = [
      Size(800, 600),
      Size(1024, 768),
      Size(1280, 800),
      Size(1366, 768),
      Size(1920, 1080),
    ];

    for (final res in resolutions) {
      tester.view.physicalSize = res;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: UserMainLayout(
            songService: DummySongService(),
            categoryService: DummyCategoryService(),
            isTestMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayerControls), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
  });

  testWidgets('UserMainLayout smartphone mode: vertical stack with side-by-side search and playlist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi SongCatalogPlaylistSection menggunakan axis: Axis.horizontal pada smartphone
    final catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(catalogFinder, findsOneWidget);
    final catalogWidget = tester.widget<SongCatalogPlaylistSection>(catalogFinder);
    expect(catalogWidget.axis, Axis.horizontal);

    // 2. Verifikasi Posisi Vertikal: Player di bagian atas layar
    final playerCenter = tester.getCenter(find.byType(PlayerDisplay));
    final searchCenter = tester.getCenter(find.text('daftar lagu'));
    final playlistCenter = tester.getCenter(find.text('playlist'));

    expect(playerCenter.dy, lessThan(searchCenter.dy));
    expect(playerCenter.dy, lessThan(playlistCenter.dy));

    // 3. Verifikasi Posisi Horizontal pada bagian bawah: Cari lagu di kiri, Playlist di kanan
    expect(searchCenter.dx, lessThan(playlistCenter.dx));
  });

  testWidgets('UserMainLayout tablet in portrait mode falls back to smartphone layout', (WidgetTester tester) async {
    // iPad / Tablet ukuran lebar 768x1024 atau 800x1280 dalam posisi Portrait
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Pada tablet portrait, SongCatalogPlaylistSection harus menggunakan axis: Axis.horizontal (tampilan smartphone)
    final catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(catalogFinder, findsOneWidget);
    final catalogWidget = tester.widget<SongCatalogPlaylistSection>(catalogFinder);
    expect(catalogWidget.axis, Axis.horizontal);

    // 2. Verifikasi susunan vertikal: Player di atas, lalu Search & Playlist di bawahnya
    final playerCenter = tester.getCenter(find.byType(PlayerDisplay));
    final searchCenter = tester.getCenter(find.text('daftar lagu'));
    final playlistCenter = tester.getCenter(find.text('playlist'));

    expect(playerCenter.dy, lessThan(searchCenter.dy));
    expect(playerCenter.dy, lessThan(playlistCenter.dy));

    // 3. Verifikasi Search di kiri dan Playlist di kanan pada bagian bawah
    expect(searchCenter.dx, lessThan(playlistCenter.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('UserMainLayout transitions smoothly between tablet landscape and portrait', (WidgetTester tester) async {
    // 1. Mulai dalam mode Tablet Landscape (1024x768)
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    var catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(tester.widget<SongCatalogPlaylistSection>(catalogFinder).axis, Axis.vertical);

    // 2. Putar ke Tablet Portrait (768x1024)
    tester.view.physicalSize = const Size(768, 1024);
    await tester.pumpAndSettle();

    catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(tester.widget<SongCatalogPlaylistSection>(catalogFinder).axis, Axis.horizontal);

    // 3. Putar kembali ke Tablet Landscape (1024x768)
    tester.view.physicalSize = const Size(1024, 768);
    await tester.pumpAndSettle();

    catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(tester.widget<SongCatalogPlaylistSection>(catalogFinder).axis, Axis.vertical);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UserMainLayout smartphone landscape mode: overflow-free on various phone screen resolutions', (WidgetTester tester) async {
    const phoneLandscapeResolutions = [
      Size(740, 360), // Small smartphone landscape
      Size(800, 360), // Standard smartphone landscape
      Size(844, 390), // iPhone 12/13/14 landscape
      Size(915, 412), // Samsung Galaxy S20/S22/S24/S27 Ultra landscape
      Size(932, 430), // iPhone 14/15 Pro Max landscape
    ];

    for (final res in phoneLandscapeResolutions) {
      tester.view.physicalSize = res;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: UserMainLayout(
            key: ValueKey('user_layout_${res.width}_${res.height}'),
            songService: DummySongService(),
            categoryService: DummyCategoryService(),
            isTestMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi sub-widget utama ter-render
      expect(find.byType(PlayerDisplay), findsOneWidget);
      expect(find.byType(PlayerControls), findsOneWidget);
      expect(find.byType(SongCatalogPlaylistSection), findsOneWidget);

      // Verifikasi posisi Player di kiri dan Section Lagu di kanan
      final playerCenter = tester.getCenter(find.byType(PlayerDisplay));
      final catalogCenter = tester.getCenter(find.byType(SongCatalogPlaylistSection));
      expect(playerCenter.dx, lessThan(catalogCenter.dx));

      // Verifikasi tab switch pada smartphone landscape
      expect(find.text('Cari Lagu'), findsOneWidget);
      expect(find.text('Playlist'), findsOneWidget);

      // Verifikasi Tab 'Cari Lagu' aktif secara default
      expect(find.text('daftar lagu'), findsOneWidget);

      // Beralih ke Tab 'Playlist'
      await tester.tap(find.text('Playlist'));
      await tester.pumpAndSettle();

      // Verifikasi konten Playlist ditampilkan tanpa overflow
      expect(find.text('Playlist masih kosong'), findsOneWidget);

      // Beralih kembali ke Tab 'Cari Lagu'
      await tester.tap(find.text('Cari Lagu'));
      await tester.pumpAndSettle();

      // Tambahkan lagu ke antrean via tombol (+)
      final queueButtons = find.byTooltip('Tambah ke Playlist');
      expect(queueButtons, findsWidgets);
      await tester.tap(queueButtons.first);
      await tester.pumpAndSettle();

      // Beralih ke Tab Playlist dan verifikasi lagu telah bertambah
      await tester.tap(find.text('Playlist'));
      await tester.pumpAndSettle();
      expect(find.text('Playlist masih kosong'), findsNothing);

      // Verifikasi TIDAK ADA OVERFLOW sama sekali
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
  });

  testWidgets('UserMainLayout dynamic orientation rotation while playing music stays in responsive dual-column landscape layout', (WidgetTester tester) async {
    // 1. Mulai dalam orientasi Smartphone Portrait (360 x 740)
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Putar lagu di mode Portrait
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Putar Lagu'));
    await tester.pumpAndSettle();

    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);

    // 3. Ubah orientasi menjadi Landscape (740 x 360) saat lagu sedang diputar
    tester.view.physicalSize = const Size(740, 360);
    await tester.pumpAndSettle();

    // 4. Verifikasi bahwa layout tetap menampilkan dual-column responsif (bukan layar tertutup satu video tanpa tombol)
    final playerCenter = tester.getCenter(find.byType(PlayerDisplay));
    final catalogCenter = tester.getCenter(find.byType(SongCatalogPlaylistSection));

    // Player di kolom kiri, Katalog/Playlist di kolom kanan
    expect(playerCenter.dx, lessThan(catalogCenter.dx));
    expect(find.text('Cari Lagu'), findsOneWidget);
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);

    // 5. Tombol Fullscreen dapat diakses
    final fsBtn = find.byIcon(Icons.fullscreen_rounded);
    expect(fsBtn, findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets('YoutubeVideoPlayerWidget renders fullscreen controls overlay with exit button and song details', (WidgetTester tester) async {
    bool didExitFullScreen = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => YoutubeVideoPlayerWidget.buildFullscreenOverlay(
              context: context,
              songTitle: 'Lagu Karaoke Populer',
              songSinger: 'Penyanyi Bintang',
              onExitFullScreen: () {
                didExitFullScreen = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi informasi lagu ditampilkan pada overlay fullscreen
    expect(find.text('Lagu Karaoke Populer - Penyanyi Bintang'), findsOneWidget);

    // Verifikasi tombol keluar fullscreen ada dan dapat diklik
    final exitBtn = find.byIcon(Icons.fullscreen_exit_rounded);
    expect(exitBtn, findsOneWidget);

    await tester.tap(exitBtn);
    await tester.pump();

    expect(didExitFullScreen, isTrue);
  });

  testWidgets('UserMainLayout retains PlayerDisplay GlobalKey across portrait and landscape rotations without recreation', (WidgetTester tester) async {
    // 1. Mulai dalam orientasi Smartphone Portrait (360 x 740)
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Putar lagu
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Putar Lagu'));
    await tester.pumpAndSettle();

    // Dapatkan PlayerDisplay widget dan GlobalKey-nya pada mode portrait
    final playerFinderPortrait = find.byType(PlayerDisplay);
    expect(playerFinderPortrait, findsOneWidget);
    final portraitKey = tester.widget<PlayerDisplay>(playerFinderPortrait).key;
    expect(portraitKey, isA<GlobalKey>());

    // 2. Putar ke mode Landscape (740 x 360)
    tester.view.physicalSize = const Size(740, 360);
    await tester.pumpAndSettle();

    final playerFinderLandscape = find.byType(PlayerDisplay);
    expect(playerFinderLandscape, findsOneWidget);
    final landscapeKey = tester.widget<PlayerDisplay>(playerFinderLandscape).key;

    // Pastikan key yang sama persis (GlobalKey) dipertahankan pada landscape
    expect(landscapeKey, equals(portraitKey));
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);

    // 3. Putar ke mode Layar Kecil / Height-Constrained (360 x 500)
    tester.view.physicalSize = const Size(360, 500);
    await tester.pumpAndSettle();

    final playerFinderConstrained = find.byType(PlayerDisplay);
    expect(playerFinderConstrained, findsOneWidget);
    final constrainedKey = tester.widget<PlayerDisplay>(playerFinderConstrained).key;

    // Pastikan key tetap sama persis
    expect(constrainedKey, equals(portraitKey));
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);

    // 4. Putar kembali ke Portrait Normal (360 x 740)
    tester.view.physicalSize = const Size(360, 740);
    await tester.pumpAndSettle();

    final playerFinderFinal = find.byType(PlayerDisplay);
    expect(playerFinderFinal, findsOneWidget);
    final finalKey = tester.widget<PlayerDisplay>(playerFinderFinal).key;
    expect(finalKey, equals(portraitKey));
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);
  });
}



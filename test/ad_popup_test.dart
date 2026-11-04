import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/services/dummy_application_service.dart';
import 'package:karaoke_app/core/services/dummy_category_service.dart';
import 'package:karaoke_app/core/services/dummy_song_service.dart';
import 'package:karaoke_app/models/application_model.dart';
import 'package:karaoke_app/models/display_mode.dart';
import 'package:karaoke_app/screens/login_screen.dart';
import 'package:karaoke_app/screens/user/user_main_layout.dart';
import 'package:karaoke_app/widgets/ad_slot_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _homeAd = 'https://example.com/ads/home.jpg';
const _playerAd = 'https://example.com/ads/player.jpg';
const _lyricAd = 'https://example.com/ads/lyric.jpg';

ApplicationModel _config() => const ApplicationModel(
  applicationid: 1,
  applicationcompany: 'PT Uji',
  applicationname: 'Karaoke Uji',
  applicationads2: _playerAd,
  applicationadshome: _homeAd,
  applicationadslyric: _lyricAd,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen menampilkan popup iklan halaman utama', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(_config()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('ad_popup_dialog'));
    expect(dialog, findsOneWidget);

    final adSlot = tester.widget<AdSlotView>(
      find.descendant(of: dialog, matching: find.byType(AdSlotView)),
    );
    expect(adSlot.ad.image, _homeAd);
  });

  testWidgets('Mode lirik only menampilkan popup slot halaman lirik', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(_config()),
          isTestMode: true,
          initialDisplayMode: DisplayMode.textOnly,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('ad_popup_dialog'));
    expect(dialog, findsOneWidget);

    final adSlot = tester.widget<AdSlotView>(
      find.descendant(of: dialog, matching: find.byType(AdSlotView)),
    );
    expect(adSlot.ad.image, _lyricAd);
  });

  testWidgets('Mode player biasa tetap memakai iklan slot konten', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(_config()),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('ad_popup_dialog'));
    expect(dialog, findsOneWidget);

    final adSlot = tester.widget<AdSlotView>(
      find.descendant(of: dialog, matching: find.byType(AdSlotView)),
    );
    expect(adSlot.ad.image, _playerAd);
  });

  testWidgets('Slot halaman utama nonaktif tidak menampilkan popup', (
    WidgetTester tester,
  ) async {
    final config = ApplicationModel(
      applicationid: 1,
      applicationcompany: 'PT Uji',
      applicationname: 'Karaoke Uji',
      applicationadshome: _homeAd,
      applicationadshomeactive: 'N',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(config),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ad_popup_dialog')), findsNothing);
  });
}

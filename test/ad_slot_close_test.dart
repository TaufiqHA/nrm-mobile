import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/services/dummy_application_service.dart';
import 'package:karaoke_app/core/services/dummy_category_service.dart';
import 'package:karaoke_app/core/services/dummy_song_service.dart';
import 'package:karaoke_app/models/application_model.dart';
import 'package:karaoke_app/screens/user/user_main_layout.dart';
import 'package:karaoke_app/widgets/ad_slot_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _topAd = 'https://example.com/ads/top.jpg';
const _bottomAd = 'https://example.com/ads/bottom.jpg';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tombol close muncul dan memanggil callback', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 300,
          height: 100,
          child: AdSlotView(
            ad: const AdSlotConfig(image: _topAd),
            onClose: () => closed = true,
          ),
        ),
      ),
    );
    await tester.pump();

    final closeButton = find.byKey(const ValueKey('ad_slot_close'));
    expect(closeButton, findsOneWidget);
    expect(find.byTooltip('Tutup iklan'), findsOneWidget);

    await tester.tap(closeButton);
    expect(closed, isTrue);
  });

  testWidgets('Tanpa onClose tombol close tidak dirender', (tester) async {
    await tester.pumpWidget(
      _wrap(const AdSlotView(ad: AdSlotConfig(image: _topAd))),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ad_slot_close')), findsNothing);
  });

  testWidgets('Slot iklan atas dan bawah bisa ditutup terpisah', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(
            const ApplicationModel(
              applicationid: 1,
              applicationcompany: 'PT Uji',
              applicationname: 'Karaoke Uji',
              applicationads1: _topAd,
              applicationadsbottom: _bottomAd,
            ),
          ),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ad_slot_top')), findsOneWidget);
    expect(find.byKey(const ValueKey('ad_slot_bottom')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ad_slot_top')),
        matching: find.byKey(const ValueKey('ad_slot_close')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ad_slot_bottom')),
        matching: find.byKey(const ValueKey('ad_slot_close')),
      ),
      findsOneWidget,
    );

    tester
        .widget<AdSlotView>(find.byKey(const ValueKey('ad_slot_top')))
        .onClose!();
    await tester.pump();

    expect(find.byKey(const ValueKey('ad_slot_top')), findsNothing);
    expect(find.byKey(const ValueKey('ad_slot_bottom')), findsOneWidget);

    tester
        .widget<AdSlotView>(find.byKey(const ValueKey('ad_slot_bottom')))
        .onClose!();
    await tester.pump();

    expect(find.byKey(const ValueKey('ad_slot_bottom')), findsNothing);
  });
}

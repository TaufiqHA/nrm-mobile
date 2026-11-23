import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/services/dummy_application_service.dart';
import 'package:karaoke_app/core/services/dummy_category_service.dart';
import 'package:karaoke_app/models/application_model.dart';
import 'package:karaoke_app/screens/login_screen.dart';
import 'package:karaoke_app/widgets/ad_slot_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/ad_test_images.dart';

const _topAd = 'https://example.com/ads/home-top.jpg';
const _bottomAd = 'https://example.com/ads/home-bottom.jpg';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useTestAdImages();
  });

  tearDown(useTestAdImages);
  tearDownAll(resetTestAdImages);

  testWidgets('Halaman utama menampilkan banner atas dan bawah', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(
            const ApplicationModel(
              applicationid: 1,
              applicationcompany: 'PT Uji',
              applicationname: 'Karaoke Uji',
              applicationadshometop: _topAd,
              applicationadshomebottom: _bottomAd,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settleAdImages(tester);

    expect(find.byKey(const ValueKey('ad_slot_home_top')), findsOneWidget);
    expect(find.byKey(const ValueKey('ad_slot_home_bottom')), findsOneWidget);

    final AdSlotView top = tester.widget<AdSlotView>(
      find.byKey(const ValueKey('ad_slot_home_top')),
    );
    expect(top.ad.image, _topAd);
    expect(top.active, isTrue);

    final AdSlotView bottom = tester.widget<AdSlotView>(
      find.byKey(const ValueKey('ad_slot_home_bottom')),
    );
    expect(bottom.ad.image, _bottomAd);
    expect(bottom.active, isTrue);
  });

  testWidgets('Banner halaman utama nonaktif tidak ditampilkan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(
            const ApplicationModel(
              applicationid: 1,
              applicationcompany: 'PT Uji',
              applicationname: 'Karaoke Uji',
              applicationadshometop: _topAd,
              applicationadshometopactive: 'N',
              applicationadshomebottom: _bottomAd,
              applicationadshomebottomactive: 'N',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settleAdImages(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ad_slot_home_top')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ad_slot_home_bottom')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('Banner halaman utama bisa ditutup terpisah', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          categoryService: DummyCategoryService(),
          applicationService: DummyApplicationService(
            const ApplicationModel(
              applicationid: 1,
              applicationcompany: 'PT Uji',
              applicationname: 'Karaoke Uji',
              applicationadshometop: _topAd,
              applicationadshomebottom: _bottomAd,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settleAdImages(tester);

    tester
        .widget<AdSlotView>(find.byKey(const ValueKey('ad_slot_home_top')))
        .onClose!();
    await tester.pump();

    expect(find.byKey(const ValueKey('ad_slot_home_top')), findsNothing);
    expect(find.byKey(const ValueKey('ad_slot_home_bottom')), findsOneWidget);
  });
}

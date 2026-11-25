import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/services/dummy_application_service.dart';
import 'package:karaoke_app/core/services/dummy_category_service.dart';
import 'package:karaoke_app/core/services/dummy_song_service.dart';
import 'package:karaoke_app/models/application_model.dart';
import 'package:karaoke_app/models/category_ad_model.dart';
import 'package:karaoke_app/models/category_model.dart';
import 'package:karaoke_app/screens/user/user_main_layout.dart';
import 'package:karaoke_app/widgets/ad_slot_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/ad_test_images.dart';

const _globalTop = 'https://example.com/ads/global-top.jpg';
const _globalBottom = 'https://example.com/ads/global-bottom.jpg';
const _categoryTop = 'https://example.com/ads/category-top.jpg';
const _categoryBottom = 'https://example.com/ads/category-bottom.jpg';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useTestAdImages();
  });

  tearDown(useTestAdImages);
  tearDownAll(resetTestAdImages);

  group('CategoryModel ad slots', () {
    test('parses ad_slots from the API payload', () {
      final category = CategoryModel.fromJson({
        'songcategoryid': 7,
        'songcategoryname': 'Pop',
        'ad_slots': [
          {
            'slot': 'top',
            'image': 'banners/top.jpg',
            'type': 'image',
            'active': 'Y',
            'clickurl': 'https://example.com/promo',
          },
          {
            'slot': 'bottom',
            'type': 'admob_banner',
            'unit': 'ca-app-pub-1/2',
            'active': 'N',
          },
        ],
      });

      expect(category.adSlots, hasLength(2));

      final top = category.adSlot('top');
      expect(top, isNotNull);
      expect(top!.image, 'banners/top.jpg');
      expect(top.active, isTrue);
      expect(top.clickUrl, 'https://example.com/promo');

      final bottom = category.adSlot('bottom');
      expect(bottom, isNotNull);
      expect(bottom!.format, AdFormat.admobBanner);
      expect(bottom.unit, 'ca-app-pub-1/2');
      expect(bottom.active, isFalse);
    });

    test('defaults to an empty list when ad_slots is missing', () {
      final category = CategoryModel.fromJson({
        'songcategoryid': 1,
        'songcategoryname': 'Rock',
      });

      expect(category.adSlots, isEmpty);
      expect(category.adSlot('top'), isNull);
    });
  });

  testWidgets('slot iklan kategori dipakai saat kategori dipilih', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final category = CategoryModel(
      songcategoryid: 1,
      songcategoryname: 'Pop Indonesia',
      adSlots: const [
        CategoryAdSlot(slot: 'top', image: _categoryTop),
        CategoryAdSlot(slot: 'bottom', image: _categoryBottom),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService([category]),
          applicationService: DummyApplicationService(
            const ApplicationModel(
              applicationid: 1,
              applicationcompany: 'PT Uji',
              applicationname: 'Karaoke Uji',
              applicationads1: _globalTop,
              applicationadsbottom: _globalBottom,
            ),
          ),
          isTestMode: true,
          initialCategoryFilter: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settleAdImages(tester);

    final AdSlotView top = tester.widget<AdSlotView>(
      find.byKey(const ValueKey('ad_slot_top')),
    );
    final AdSlotView bottom = tester.widget<AdSlotView>(
      find.byKey(const ValueKey('ad_slot_bottom')),
    );

    expect(top.ad.image, _categoryTop);
    expect(top.active, isTrue);
    expect(bottom.ad.image, _categoryBottom);
    expect(bottom.active, isTrue);
  });

  testWidgets('slot global dipakai saat tidak ada kategori dipilih', (
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
              applicationads1: _globalTop,
              applicationadsbottom: _globalBottom,
            ),
          ),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settleAdImages(tester);

    final AdSlotView top = tester.widget<AdSlotView>(
      find.byKey(const ValueKey('ad_slot_top')),
    );
    final AdSlotView bottom = tester.widget<AdSlotView>(
      find.byKey(const ValueKey('ad_slot_bottom')),
    );

    expect(top.ad.image, _globalTop);
    expect(bottom.ad.image, _globalBottom);
  });
}

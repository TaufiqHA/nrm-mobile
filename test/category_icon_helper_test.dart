import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/config/api_config.dart';
import 'package:karaoke_app/core/utils/category_icon_helper.dart';
import 'package:karaoke_app/models/category_model.dart';

void main() {
  tearDown(() {
    ApiConfig.customBaseUrl = null;
  });

  group('CategoryModel icon fields', () {
    test('parses icon keys and resolves empty values to null', () {
      final category = CategoryModel.fromJson({
        'songcategoryid': 7,
        'songcategoryname': 'Piano',
        'icon': 'piano',
        'icon_image': '  ',
        'icon_url': '',
      });

      expect(category.icon, 'piano');
      expect(category.iconImage, isNull);
      expect(category.iconUrl, isNull);
    });

    test('parse icon images from API payload', () {
      final category = CategoryModel.fromJson({
        'songcategoryid': 8,
        'songcategoryname': 'Pop',
        'icon_image': 'category-icons/pop.png',
        'icon_url': 'https://example.com/storage/category-icons/pop.png',
      });

      expect(category.iconImage, 'category-icons/pop.png');
      expect(
        category.iconUrl,
        'https://example.com/storage/category-icons/pop.png',
      );
    });
  });

  group('categoryIconSpec', () {
    test('maps builtin icon keys and prioritizes them over name keywords', () {
      final category = CategoryModel(
        songcategoryid: 1,
        songcategoryname: 'Natal',
        icon: 'mic',
      );

      final spec = categoryIconSpec(category, 0);

      expect(spec.icon, Icons.mic_rounded);
      expect(spec.imageUrl, isNull);
    });

    test('falls back to keyword detection when no icon is configured', () {
      final category = CategoryModel(
        songcategoryid: 1,
        songcategoryname: 'Natal',
      );

      expect(categoryIconSpec(category, 0).icon, Icons.ac_unit_rounded);
    });

    test('builds image URL from the active API base url', () {
      ApiConfig.customBaseUrl = 'https://contoh.test/api';

      final category = CategoryModel(
        songcategoryid: 1,
        songcategoryname: 'Pop',
        icon: 'star',
        iconImage: 'category-icons/pop.png',
      );

      final spec = categoryIconSpec(category, 0);

      expect(
        spec.imageUrl,
        'https://contoh.test/storage/category-icons/pop.png',
      );
    });

    test('uses absolute icon url as a fallback', () {
      final category = CategoryModel(
        songcategoryid: 1,
        songcategoryname: 'Pop',
        iconUrl: 'https://cdn.test/icons/pop.png',
      );

      expect(
        categoryIconSpec(category, 0).imageUrl,
        'https://cdn.test/icons/pop.png',
      );
    });

    test('catalog covers the expected backend icon keys', () {
      expect(
        categoryIconCatalog.keys,
        containsAll([
          'music_note',
          'library_music',
          'mic',
          'piano',
          'child_care',
          'ac_unit',
          'wb_sunny',
          'favorite',
          'church',
        ]),
      );
    });
  });
}

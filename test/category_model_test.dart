import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/models/category_model.dart';

void main() {
  group('CategoryModel isActive', () {
    test('defaults to true when the field is missing', () {
      final category = CategoryModel.fromJson({
        'songcategoryid': 1,
        'songcategoryname': 'Pop',
      });

      expect(category.isActive, isTrue);
    });

    test('parses boolean is_active values', () {
      expect(
        CategoryModel.fromJson({
          'songcategoryid': 1,
          'songcategoryname': 'Pop',
          'is_active': false,
        }).isActive,
        isFalse,
      );
      expect(
        CategoryModel.fromJson({
          'songcategoryid': 2,
          'songcategoryname': 'Rock',
          'is_active': true,
        }).isActive,
        isTrue,
      );
    });

    test('parses numeric and string representations', () {
      expect(
        CategoryModel.fromJson({
          'songcategoryid': 1,
          'is_active': 0,
        }).isActive,
        isFalse,
      );
      expect(
        CategoryModel.fromJson({
          'songcategoryid': 2,
          'is_active': '0',
        }).isActive,
        isFalse,
      );
      expect(
        CategoryModel.fromJson({
          'songcategoryid': 3,
          'is_active': 'N',
        }).isActive,
        isFalse,
      );
      expect(
        CategoryModel.fromJson({
          'songcategoryid': 4,
          'is_active': '1',
        }).isActive,
        isTrue,
      );
    });

    test('copyWith and toJson preserve the active status', () {
      final category = CategoryModel(
        songcategoryid: 1,
        songcategoryname: 'Pop',
        isActive: false,
      );

      expect(category.toJson()['is_active'], isFalse);
      expect(category.copyWith(isActive: true).isActive, isTrue);
    });
  });
}

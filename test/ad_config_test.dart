import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/core/config/api_config.dart';
import 'package:karaoke_app/models/application_model.dart';
import 'package:karaoke_app/widgets/ad_slot_view.dart';

void main() {
  setUp(() => ApiConfig.customBaseUrl = null);
  tearDown(() => ApiConfig.customBaseUrl = null);

  group('AdFormat', () {
    test('parses known backend values', () {
      expect(AdFormat.fromRaw('image'), AdFormat.image);
      expect(AdFormat.fromRaw('admob'), AdFormat.admobNative);
      expect(AdFormat.fromRaw('admob_native'), AdFormat.admobNative);
      expect(AdFormat.fromRaw('admob_banner'), AdFormat.admobBanner);
      expect(
        AdFormat.fromRaw('admob_interstitial'),
        AdFormat.admobInterstitial,
      );
      expect(AdFormat.fromRaw('admob_app_open'), AdFormat.admobAppOpen);
      expect(AdFormat.fromRaw('admob_reward'), AdFormat.admobReward);
    });

    test('unknown / null values fall back to image', () {
      expect(AdFormat.fromRaw(null), AdFormat.image);
      expect(AdFormat.fromRaw(''), AdFormat.image);
      expect(AdFormat.fromRaw('something_else'), AdFormat.image);
    });

    test('raw round-trips to backend values', () {
      expect(AdFormat.image.raw, 'image');
      expect(AdFormat.admobNative.raw, 'admob_native');
      expect(AdFormat.admobReward.raw, 'admob_reward');
    });
  });

  group('ApplicationModel ad configuration', () {
    test('fromJson parses admob fields and exposes slot configs', () {
      final model = ApplicationModel.fromJson({
        'applicationid': 1,
        'applicationcompany': 'PT Uji',
        'applicationname': 'Karaoke Uji',
        'applicationads1': 'banners/top.jpg',
        'applicationads1type': 'admob_native',
        'applicationads1unit': 'ca-app-pub-1/1',
        'applicationads2type': 'image',
        'applicationads2': 'banners/mid.jpg',
        'applicationadsbottomtype': 'admob_interstitial',
        'applicationadsbottomunit': 'ca-app-pub-1/2',
      });

      final top = model.ads1Config;
      expect(top.isNative, isTrue);
      expect(top.isAdMob, isTrue);
      expect(top.unit, 'ca-app-pub-1/1');

      expect(model.ads2Config.isImage, isTrue);
      expect(model.ads2Config.image, 'banners/mid.jpg');

      final bottom = model.adsBottomConfig;
      expect(bottom.isInterstitial, isTrue);
      expect(bottom.isFullScreen, isTrue);
      expect(bottom.isInline, isFalse);
    });

    test('parses home and lyric-only page ad slots', () {
      final model = ApplicationModel.fromJson({
        'applicationid': 1,
        'applicationcompany': 'PT Uji',
        'applicationname': 'Karaoke Uji',
        'applicationadshome': 'banners/home.jpg',
        'applicationadshometype': 'image',
        'applicationadshomeactive': 'N',
        'applicationadslyric': null,
        'applicationadslyrictype': 'admob_native',
        'applicationadslyricunit': 'ca-app-pub-1/4',
        'applicationadslyricactive': 'Y',
        'applicationadslyrictop': 'banners/lyric-top.jpg',
        'applicationadslyrictoptype': 'image',
        'applicationadslyrictopactive': 'N',
        'applicationadslyricbottomtype': 'admob_banner',
        'applicationadslyricbottomunit': 'ca-app-pub-1/5',
        'applicationadslyricbottomactive': 'Y',
      });

      expect(model.isAdsHomeActive, isFalse);
      expect(model.adsHomeConfig.isImage, isTrue);
      expect(model.adsHomeConfig.image, 'banners/home.jpg');

      expect(model.isAdsLyricActive, isTrue);
      expect(model.adsLyricConfig.isNative, isTrue);
      expect(model.adsLyricConfig.unit, 'ca-app-pub-1/4');

      expect(model.isAdsLyricTopActive, isFalse);
      expect(model.adsLyricTopConfig.image, 'banners/lyric-top.jpg');
      expect(model.isAdsLyricBottomActive, isTrue);
      expect(model.adsLyricBottomConfig.isBanner, isTrue);
      expect(model.adsLyricBottomConfig.unit, 'ca-app-pub-1/5');
    });

    test('defaults to image type when fields are missing', () {
      final model = ApplicationModel.fromJson({
        'applicationid': 1,
        'applicationcompany': 'PT Uji',
        'applicationname': 'Karaoke Uji',
      });
      expect(model.ads1Config.isImage, isTrue);
      expect(model.ads1Config.isAdMob, isFalse);
      expect(model.adsHomeConfig.isImage, isTrue);
      expect(model.adsLyricConfig.isImage, isTrue);
      expect(model.adsLyricTopConfig.isImage, isTrue);
      expect(model.adsLyricBottomConfig.isImage, isTrue);
      expect(model.isAdsHomeActive, isTrue);
      expect(model.isAdsLyricActive, isTrue);
      expect(model.isAdsLyricTopActive, isTrue);
      expect(model.isAdsLyricBottomActive, isTrue);
      expect(model.isAds1Active, isTrue);
      expect(model.isAds2Active, isTrue);
    });

    test('parses per-slot active flags independently from aggregate', () {
      final model = ApplicationModel.fromJson({
        'applicationid': 1,
        'applicationcompany': 'PT Uji',
        'applicationname': 'Karaoke Uji',
        'applicationadsactive': 'Y',
        'applicationads1active': 'N',
        'applicationads2active': 'Y',
      });

      // Agregat tetap Y karena slot 2 masih aktif, tetapi slot 1 nonaktif.
      expect(model.isAdsActive, isTrue);
      expect(model.isAds1Active, isFalse);
      expect(model.isAds2Active, isTrue);
    });

    test('falls back to aggregate when per-slot flags are missing', () {
      final model = ApplicationModel.fromJson({
        'applicationid': 1,
        'applicationcompany': 'PT Uji',
        'applicationname': 'Karaoke Uji',
        'applicationadsactive': 'N',
      });

      expect(model.isAdsActive, isFalse);
      expect(model.isAds1Active, isFalse);
      expect(model.isAds2Active, isFalse);
    });

    test('toJson includes ad type and unit fields', () {
      const model = ApplicationModel(
        applicationid: 1,
        applicationcompany: 'PT Uji',
        applicationname: 'Karaoke Uji',
        applicationads1type: 'admob_banner',
        applicationads1unit: 'ca-app-pub-1/9',
        applicationads1active: 'N',
        applicationads2active: 'Y',
        applicationadshomeactive: 'N',
        applicationadslyrictype: 'admob_interstitial',
        applicationadslyricunit: 'ca-app-pub-1/10',
        applicationadslyrictoptype: 'admob_banner',
        applicationadslyrictopunit: 'ca-app-pub-1/11',
        applicationadslyricbottom: 'banners/lyric-bottom.jpg',
        applicationadslyricbottomactive: 'N',
      );
      final json = model.toJson();
      expect(json['applicationads1type'], 'admob_banner');
      expect(json['applicationads1unit'], 'ca-app-pub-1/9');
      expect(json['applicationads1active'], 'N');
      expect(json['applicationads2active'], 'Y');
      expect(json['applicationadshomeactive'], 'N');
      expect(json['applicationadslyrictype'], 'admob_interstitial');
      expect(json['applicationadslyricunit'], 'ca-app-pub-1/10');
      expect(json['applicationadslyrictoptype'], 'admob_banner');
      expect(json['applicationadslyrictopunit'], 'ca-app-pub-1/11');
      expect(json['applicationadslyricbottom'], 'banners/lyric-bottom.jpg');
      expect(json['applicationadslyricbottomactive'], 'N');
    });
  });

  group('resolveAdImageUrl', () {
    test('returns full URLs unchanged', () {
      expect(
        resolveAdImageUrl('https://cdn.example.com/a.jpg'),
        'https://cdn.example.com/a.jpg',
      );
    });

    test('maps storage-relative paths to the API origin', () {
      ApiConfig.customBaseUrl = 'https://example.com/api';
      expect(
        resolveAdImageUrl('banners/a.jpg'),
        'https://example.com/storage/banners/a.jpg',
      );
    });

    test('returns empty string for blank input', () {
      expect(resolveAdImageUrl('   '), '');
    });
  });
}

/// Jenis iklan yang didukung untuk setiap slot iklan.
///
/// Nilai string-nya harus sama dengan yang dikirim backend (kolom
/// `applicationads*type`) dan yang divalidasi di panel admin website.
enum AdFormat {
  image,
  admobNative,
  admobBanner,
  admobInterstitial,
  admobAppOpen,
  admobReward;

  /// Konversi dari nilai mentah backend. Nilai tak dikenal dianggap `image`.
  static AdFormat fromRaw(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'admob_native':
      case 'admob':
        return AdFormat.admobNative;
      case 'admob_banner':
        return AdFormat.admobBanner;
      case 'admob_interstitial':
        return AdFormat.admobInterstitial;
      case 'admob_app_open':
        return AdFormat.admobAppOpen;
      case 'admob_reward':
        return AdFormat.admobReward;
      case 'image':
      default:
        return AdFormat.image;
    }
  }

  /// Nilai string yang dipakai backend.
  String get raw {
    switch (this) {
      case AdFormat.image:
        return 'image';
      case AdFormat.admobNative:
        return 'admob_native';
      case AdFormat.admobBanner:
        return 'admob_banner';
      case AdFormat.admobInterstitial:
        return 'admob_interstitial';
      case AdFormat.admobAppOpen:
        return 'admob_app_open';
      case AdFormat.admobReward:
        return 'admob_reward';
    }
  }
}

/// Konfigurasi satu slot iklan: gambar (bila jenis gambar) ATAU Ad Unit AdMob.
class AdSlotConfig {
  /// Path/URL gambar banner (dipakai bila [format] = [AdFormat.image]).
  final String? image;

  final AdFormat format;

  /// Ad Unit ID AdMob (dipakai bila [format] adalah salah satu `admob*`).
  final String? unit;

  const AdSlotConfig({this.image, this.format = AdFormat.image, this.unit});

  bool get isImage => format == AdFormat.image;
  bool get isNative => format == AdFormat.admobNative;
  bool get isBanner => format == AdFormat.admobBanner;
  bool get isInterstitial => format == AdFormat.admobInterstitial;
  bool get isAppOpen => format == AdFormat.admobAppOpen;
  bool get isReward => format == AdFormat.admobReward;

  /// Iklan yang dirender langsung di dalam layout.
  bool get isInline => isImage || isNative || isBanner;

  /// Iklan layar penuh (dikelola [AdManager], tidak dirender di slot).
  bool get isFullScreen => isInterstitial || isAppOpen || isReward;

  bool get hasUnit => unit != null && unit!.trim().isNotEmpty;

  /// True bila iklan AdMob dan Ad Unit ID tersedia.
  bool get isAdMob => format != AdFormat.image && hasUnit;
}

class ApplicationModel {
  final int applicationid;
  final String applicationcompany;
  final String applicationname;
  final String? applicationads1;
  final String? applicationads2;
  final String applicationadsactive; // 'Y' or 'N' (agregat kompatibilitas)
  final String applicationads1active; // 'Y' or 'N' (status slot 1)
  final String applicationads2active; // 'Y' or 'N' (status slot 2)
  final String? applicationadsbottom;
  final String applicationadsbottomactive; // 'Y' or 'N'

  // Slot iklan khusus halaman utama dan halaman lirik only.
  final String? applicationadshome;
  final String applicationadshomeactive; // 'Y' or 'N'
  final String? applicationadslyric;
  final String applicationadslyricactive; // 'Y' or 'N'

  // Slot iklan atas & bawah khusus halaman lirik only. Terpisah dari slot
  // halaman musik agar admin bisa mengatur banner lirik secara independen.
  final String? applicationadslyrictop;
  final String applicationadslyrictopactive; // 'Y' or 'N'
  final String? applicationadslyricbottom;
  final String applicationadslyricbottomactive; // 'Y' or 'N'

  // Konfigurasi jenis iklan + Ad Unit per slot (dari panel admin website).
  final String applicationads1type;
  final String? applicationads1unit;
  final String applicationads2type;
  final String? applicationads2unit;
  final String applicationadshometype;
  final String? applicationadshomeunit;
  final String applicationadslyrictype;
  final String? applicationadslyricunit;
  final String applicationadslyrictoptype;
  final String? applicationadslyrictopunit;
  final String applicationadslyricbottomtype;
  final String? applicationadslyricbottomunit;
  final String applicationadsbottomtype;
  final String? applicationadsbottomunit;

  const ApplicationModel({
    required this.applicationid,
    required this.applicationcompany,
    required this.applicationname,
    this.applicationads1,
    this.applicationads2,
    this.applicationadsactive = 'Y',
    this.applicationads1active = 'Y',
    this.applicationads2active = 'Y',
    this.applicationadsbottom,
    this.applicationadsbottomactive = 'Y',
    this.applicationadshome,
    this.applicationadshomeactive = 'Y',
    this.applicationadslyric,
    this.applicationadslyricactive = 'Y',
    this.applicationadslyrictop,
    this.applicationadslyrictopactive = 'Y',
    this.applicationadslyricbottom,
    this.applicationadslyricbottomactive = 'Y',
    this.applicationads1type = 'image',
    this.applicationads1unit,
    this.applicationads2type = 'image',
    this.applicationads2unit,
    this.applicationadshometype = 'image',
    this.applicationadshomeunit,
    this.applicationadslyrictype = 'image',
    this.applicationadslyricunit,
    this.applicationadslyrictoptype = 'image',
    this.applicationadslyrictopunit,
    this.applicationadslyricbottomtype = 'image',
    this.applicationadslyricbottomunit,
    this.applicationadsbottomtype = 'image',
    this.applicationadsbottomunit,
  });

  bool get isAdsActive => applicationadsactive.toUpperCase() == 'Y';
  bool get isAds1Active => applicationads1active.toUpperCase() == 'Y';
  bool get isAds2Active => applicationads2active.toUpperCase() == 'Y';
  bool get isAdsBottomActive => applicationadsbottomactive.toUpperCase() == 'Y';
  bool get isAdsHomeActive => applicationadshomeactive.toUpperCase() == 'Y';
  bool get isAdsLyricActive => applicationadslyricactive.toUpperCase() == 'Y';
  bool get isAdsLyricTopActive =>
      applicationadslyrictopactive.toUpperCase() == 'Y';
  bool get isAdsLyricBottomActive =>
      applicationadslyricbottomactive.toUpperCase() == 'Y';

  /// Slot iklan 1 (Header / Atas).
  AdSlotConfig get ads1Config => AdSlotConfig(
    image: applicationads1,
    format: AdFormat.fromRaw(applicationads1type),
    unit: applicationads1unit,
  );

  /// Slot iklan 2 (Konten).
  AdSlotConfig get ads2Config => AdSlotConfig(
    image: applicationads2,
    format: AdFormat.fromRaw(applicationads2type),
    unit: applicationads2unit,
  );

  /// Slot iklan halaman utama (popup saat aplikasi dibuka).
  AdSlotConfig get adsHomeConfig => AdSlotConfig(
    image: applicationadshome,
    format: AdFormat.fromRaw(applicationadshometype),
    unit: applicationadshomeunit,
  );

  /// Slot iklan halaman lirik only (popup saat mode teks dibuka).
  AdSlotConfig get adsLyricConfig => AdSlotConfig(
    image: applicationadslyric,
    format: AdFormat.fromRaw(applicationadslyrictype),
    unit: applicationadslyricunit,
  );

  /// Slot iklan atas khusus halaman lirik only.
  AdSlotConfig get adsLyricTopConfig => AdSlotConfig(
    image: applicationadslyrictop,
    format: AdFormat.fromRaw(applicationadslyrictoptype),
    unit: applicationadslyrictopunit,
  );

  /// Slot iklan bawah khusus halaman lirik only.
  AdSlotConfig get adsLyricBottomConfig => AdSlotConfig(
    image: applicationadslyricbottom,
    format: AdFormat.fromRaw(applicationadslyricbottomtype),
    unit: applicationadslyricbottomunit,
  );

  /// Slot iklan bawah (Footer).
  AdSlotConfig get adsBottomConfig => AdSlotConfig(
    image: applicationadsbottom,
    format: AdFormat.fromRaw(applicationadsbottomtype),
    unit: applicationadsbottomunit,
  );

  ApplicationModel copyWith({
    int? applicationid,
    String? applicationcompany,
    String? applicationname,
    String? applicationads1,
    String? applicationads2,
    String? applicationadsactive,
    String? applicationads1active,
    String? applicationads2active,
    String? applicationadsbottom,
    String? applicationadsbottomactive,
    String? applicationadshome,
    String? applicationadshomeactive,
    String? applicationadslyric,
    String? applicationadslyricactive,
    String? applicationadslyrictop,
    String? applicationadslyrictopactive,
    String? applicationadslyricbottom,
    String? applicationadslyricbottomactive,
    String? applicationads1type,
    String? applicationads1unit,
    String? applicationads2type,
    String? applicationads2unit,
    String? applicationadshometype,
    String? applicationadshomeunit,
    String? applicationadslyrictype,
    String? applicationadslyricunit,
    String? applicationadslyrictoptype,
    String? applicationadslyrictopunit,
    String? applicationadslyricbottomtype,
    String? applicationadslyricbottomunit,
    String? applicationadsbottomtype,
    String? applicationadsbottomunit,
  }) {
    return ApplicationModel(
      applicationid: applicationid ?? this.applicationid,
      applicationcompany: applicationcompany ?? this.applicationcompany,
      applicationname: applicationname ?? this.applicationname,
      applicationads1: applicationads1 ?? this.applicationads1,
      applicationads2: applicationads2 ?? this.applicationads2,
      applicationadsactive: applicationadsactive ?? this.applicationadsactive,
      applicationads1active:
          applicationads1active ?? this.applicationads1active,
      applicationads2active:
          applicationads2active ?? this.applicationads2active,
      applicationadsbottom: applicationadsbottom ?? this.applicationadsbottom,
      applicationadsbottomactive:
          applicationadsbottomactive ?? this.applicationadsbottomactive,
      applicationadshome: applicationadshome ?? this.applicationadshome,
      applicationadshomeactive:
          applicationadshomeactive ?? this.applicationadshomeactive,
      applicationadslyric: applicationadslyric ?? this.applicationadslyric,
      applicationadslyricactive:
          applicationadslyricactive ?? this.applicationadslyricactive,
      applicationadslyrictop:
          applicationadslyrictop ?? this.applicationadslyrictop,
      applicationadslyrictopactive:
          applicationadslyrictopactive ?? this.applicationadslyrictopactive,
      applicationadslyricbottom:
          applicationadslyricbottom ?? this.applicationadslyricbottom,
      applicationadslyricbottomactive:
          applicationadslyricbottomactive ??
          this.applicationadslyricbottomactive,
      applicationads1type: applicationads1type ?? this.applicationads1type,
      applicationads1unit: applicationads1unit ?? this.applicationads1unit,
      applicationads2type: applicationads2type ?? this.applicationads2type,
      applicationads2unit: applicationads2unit ?? this.applicationads2unit,
      applicationadshometype:
          applicationadshometype ?? this.applicationadshometype,
      applicationadshomeunit:
          applicationadshomeunit ?? this.applicationadshomeunit,
      applicationadslyrictype:
          applicationadslyrictype ?? this.applicationadslyrictype,
      applicationadslyricunit:
          applicationadslyricunit ?? this.applicationadslyricunit,
      applicationadslyrictoptype:
          applicationadslyrictoptype ?? this.applicationadslyrictoptype,
      applicationadslyrictopunit:
          applicationadslyrictopunit ?? this.applicationadslyrictopunit,
      applicationadslyricbottomtype:
          applicationadslyricbottomtype ?? this.applicationadslyricbottomtype,
      applicationadslyricbottomunit:
          applicationadslyricbottomunit ?? this.applicationadslyricbottomunit,
      applicationadsbottomtype:
          applicationadsbottomtype ?? this.applicationadsbottomtype,
      applicationadsbottomunit:
          applicationadsbottomunit ?? this.applicationadsbottomunit,
    );
  }

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      applicationid: json['applicationid'] is int
          ? json['applicationid'] as int
          : int.tryParse(json['applicationid']?.toString() ?? '1') ?? 1,
      applicationcompany: json['applicationcompany'] as String? ?? '',
      applicationname: json['applicationname'] as String? ?? '',
      applicationads1: json['applicationads1'] as String?,
      applicationads2: json['applicationads2'] as String?,
      applicationadsactive: json['applicationadsactive'] as String? ?? 'Y',
      applicationads1active:
          json['applicationads1active'] as String? ??
          json['applicationadsactive'] as String? ??
          'Y',
      applicationads2active:
          json['applicationads2active'] as String? ??
          json['applicationadsactive'] as String? ??
          'Y',
      applicationadsbottom: json['applicationadsbottom'] as String?,
      applicationadsbottomactive:
          json['applicationadsbottomactive'] as String? ?? 'Y',
      applicationadshome: json['applicationadshome'] as String?,
      applicationadshomeactive:
          json['applicationadshomeactive'] as String? ?? 'Y',
      applicationadslyric: json['applicationadslyric'] as String?,
      applicationadslyricactive:
          json['applicationadslyricactive'] as String? ?? 'Y',
      applicationadslyrictop: json['applicationadslyrictop'] as String?,
      applicationadslyrictopactive:
          json['applicationadslyrictopactive'] as String? ?? 'Y',
      applicationadslyricbottom: json['applicationadslyricbottom'] as String?,
      applicationadslyricbottomactive:
          json['applicationadslyricbottomactive'] as String? ?? 'Y',
      applicationads1type: json['applicationads1type'] as String? ?? 'image',
      applicationads1unit: json['applicationads1unit'] as String?,
      applicationads2type: json['applicationads2type'] as String? ?? 'image',
      applicationads2unit: json['applicationads2unit'] as String?,
      applicationadshometype:
          json['applicationadshometype'] as String? ?? 'image',
      applicationadshomeunit: json['applicationadshomeunit'] as String?,
      applicationadslyrictype:
          json['applicationadslyrictype'] as String? ?? 'image',
      applicationadslyricunit: json['applicationadslyricunit'] as String?,
      applicationadslyrictoptype:
          json['applicationadslyrictoptype'] as String? ?? 'image',
      applicationadslyrictopunit: json['applicationadslyrictopunit'] as String?,
      applicationadslyricbottomtype:
          json['applicationadslyricbottomtype'] as String? ?? 'image',
      applicationadslyricbottomunit:
          json['applicationadslyricbottomunit'] as String?,
      applicationadsbottomtype:
          json['applicationadsbottomtype'] as String? ?? 'image',
      applicationadsbottomunit: json['applicationadsbottomunit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationid': applicationid,
      'applicationcompany': applicationcompany,
      'applicationname': applicationname,
      'applicationads1': applicationads1,
      'applicationads2': applicationads2,
      'applicationadsactive': applicationadsactive,
      'applicationads1active': applicationads1active,
      'applicationads2active': applicationads2active,
      'applicationadsbottom': applicationadsbottom,
      'applicationadsbottomactive': applicationadsbottomactive,
      'applicationadshome': applicationadshome,
      'applicationadshomeactive': applicationadshomeactive,
      'applicationadslyric': applicationadslyric,
      'applicationadslyricactive': applicationadslyricactive,
      'applicationadslyrictop': applicationadslyrictop,
      'applicationadslyrictopactive': applicationadslyrictopactive,
      'applicationadslyricbottom': applicationadslyricbottom,
      'applicationadslyricbottomactive': applicationadslyricbottomactive,
      'applicationads1type': applicationads1type,
      'applicationads1unit': applicationads1unit,
      'applicationads2type': applicationads2type,
      'applicationads2unit': applicationads2unit,
      'applicationadshometype': applicationadshometype,
      'applicationadshomeunit': applicationadshomeunit,
      'applicationadslyrictype': applicationadslyrictype,
      'applicationadslyricunit': applicationadslyricunit,
      'applicationadslyrictoptype': applicationadslyrictoptype,
      'applicationadslyrictopunit': applicationadslyrictopunit,
      'applicationadslyricbottomtype': applicationadslyricbottomtype,
      'applicationadslyricbottomunit': applicationadslyricbottomunit,
      'applicationadsbottomtype': applicationadsbottomtype,
      'applicationadsbottomunit': applicationadsbottomunit,
    };
  }
}

class CategoryModel {
  final int songcategoryid;
  final String songcategoryname;

  /// Key ikon bawaan dari website admin (lihat `categoryIconCatalog`).
  final String? icon;

  /// Path gambar ikon hasil upload (relatif terhadap `/storage`, atau URL penuh).
  final String? iconImage;

  /// URL absolut gambar ikon yang disediakan API (cadangan bila `iconImage` kosong).
  final String? iconUrl;

  /// Status kategori di backend. Kategori nonaktif tidak ditampilkan ke user.
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Backward-compatible getters
  String get id => songcategoryid.toString();
  String get name => songcategoryname;

  CategoryModel({
    dynamic id,
    int? songcategoryid,
    dynamic name,
    String? songcategoryname,
    String? icon,
    String? iconImage,
    String? iconUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  }) : songcategoryid =
           songcategoryid ??
           (id is int ? id : (int.tryParse(id?.toString() ?? '0') ?? 0)),
       songcategoryname = (songcategoryname ?? name ?? '').toString(),
       icon = _nonEmpty(icon),
       iconImage = _nonEmpty(iconImage),
       iconUrl = _nonEmpty(iconUrl);

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Backend mengirim `is_active` sebagai boolean, tetapi tetap dukung
  /// representasi lain (`1`/`0`, `"Y"`/`"N"`) untuk kompatibilitas.
  static bool _parseIsActive(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return !(normalized == '0' ||
        normalized == 'false' ||
        normalized == 'n' ||
        normalized == 'no');
  }

  CategoryModel copyWith({
    int? songcategoryid,
    String? songcategoryname,
    dynamic id,
    dynamic name,
    String? icon,
    String? iconImage,
    String? iconUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      songcategoryid:
          songcategoryid ??
          (id != null
              ? (id is int
                    ? id
                    : (int.tryParse(id.toString()) ?? this.songcategoryid))
              : this.songcategoryid),
      songcategoryname:
          songcategoryname ?? (name?.toString() ?? this.songcategoryname),
      icon: icon ?? this.icon,
      iconImage: iconImage ?? this.iconImage,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['songcategoryid'] != null) {
      parsedId = json['songcategoryid'] is int
          ? json['songcategoryid'] as int
          : (int.tryParse(json['songcategoryid'].toString()) ?? 0);
    } else if (json['id'] != null) {
      parsedId = json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id'].toString()) ?? 0);
    }

    final parsedName = (json['songcategoryname'] ?? json['name'] ?? '')
        .toString();

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    } else if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString());
    }

    DateTime? parsedUpdatedAt;
    if (json['updated_at'] != null) {
      parsedUpdatedAt = DateTime.tryParse(json['updated_at'].toString());
    } else if (json['updatedAt'] != null) {
      parsedUpdatedAt = DateTime.tryParse(json['updatedAt'].toString());
    }

    return CategoryModel(
      songcategoryid: parsedId,
      songcategoryname: parsedName,
      icon: (json['icon'] ?? json['iconKey'])?.toString(),
      iconImage: (json['icon_image'] ?? json['iconImage'])?.toString(),
      iconUrl: (json['icon_url'] ?? json['iconUrl'])?.toString(),
      isActive: _parseIsActive(json['is_active'] ?? json['isActive']),
      createdAt: parsedCreatedAt ?? DateTime.now(),
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songcategoryid': songcategoryid,
      'songcategoryname': songcategoryname,
      'icon': icon,
      'icon_image': iconImage,
      'icon_url': iconUrl,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Backward-compatible properties
      'id': id,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          songcategoryid == other.songcategoryid &&
          songcategoryname == other.songcategoryname;

  @override
  int get hashCode => songcategoryid.hashCode ^ songcategoryname.hashCode;
}

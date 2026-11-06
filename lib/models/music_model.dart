class MusicModel {
  final int musicid;
  final String musictitle;
  final String? musicartist;
  final String musicfileid;
  final String? musicfilename;
  final int? musicduration;
  final String? coverUrl;
  final String? streamUrl;
  final bool isActive;
  final int sortOrder;

  const MusicModel({
    required this.musicid,
    required this.musictitle,
    this.musicartist,
    this.musicfileid = '',
    this.musicfilename,
    this.musicduration,
    this.coverUrl,
    this.streamUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory MusicModel.fromJson(Map<String, dynamic> json) {
    return MusicModel(
      musicid: _toInt(json['musicid'] ?? json['id']),
      musictitle: (json['musictitle'] ?? json['title'] ?? '').toString(),
      musicartist: _nonEmpty(json['musicartist'] ?? json['artist']),
      musicfileid: (json['musicfileid'] ?? '').toString(),
      musicfilename: _nonEmpty(json['musicfilename'] ?? json['filename']),
      musicduration: _toNullableInt(json['musicduration']),
      coverUrl: _nonEmpty(json['cover_url'] ?? json['coverUrl']),
      streamUrl: _nonEmpty(json['stream_url'] ?? json['streamUrl']),
      isActive: _parseBool(json['is_active'] ?? json['isActive']),
      sortOrder: _toInt(json['sort_order'] ?? json['sortOrder']),
    );
  }

  /// Durasi dalam format mm:ss (atau h:mm:ss untuk lagu panjang).
  String get formattedDuration {
    final seconds = musicduration ?? 0;
    if (seconds <= 0) return '--:--';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remaining = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${remaining.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static bool _parseBool(dynamic value) {
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
}

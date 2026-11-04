import '../config/api_config.dart';

/// Utilitas untuk menormalkan URL media yang berasal dari backend.
///
/// Backend dapat mengirim URL absolut (hasil `Storage::url`) maupun path
/// relatif. Saat `APP_URL` backend masih menunjuk ke `localhost`, URL absolut
/// akan diarahkan ulang ke origin API yang sedang dipakai aplikasi.
class MediaUrlHelper {
  /// Origin API tanpa akhiran `/api` (mis. `https://domain.com`).
  static String get apiOrigin {
    var base = ApiConfig.baseUrl.trim();
    final apiIndex = base.indexOf('/api');
    if (apiIndex >= 0) {
      base = base.substring(0, apiIndex);
    }
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  /// Mengembalikan URL absolut yang siap dipakai pemutar, atau `null`.
  static String? resolve(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri == null) return value;

      // URL absolut dari `APP_URL=localhost` tidak bisa diakses perangkat.
      final isLocalHost =
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '0.0.0.0';
      if (isLocalHost) {
        final origin = Uri.tryParse(apiOrigin);
        if (origin != null &&
            origin.host.isNotEmpty &&
            origin.host != uri.host) {
          final path = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
          return '$apiOrigin$path';
        }
      }
      return value;
    }

    if (value.startsWith('/storage/')) {
      return '$apiOrigin$value';
    }
    if (value.startsWith('storage/')) {
      return '$apiOrigin/$value';
    }
    return '$apiOrigin/storage/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  /// Apakah nilai berupa tautan YouTube.
  static bool isYoutube(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return false;
    return value.contains('youtube.com') || value.contains('youtu.be');
  }

  /// Apakah ekstensi menandakan video yang dapat diputar langsung.
  static bool isDirectVideo(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return false;
    final path = Uri.tryParse(value)?.path ?? value;
    return path.endsWith('.mp4') ||
        path.endsWith('.m4v') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
  }

  /// Apakah ekstensi menandakan audio yang dapat diputar langsung.
  static bool isDirectAudio(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return false;
    final path = Uri.tryParse(value)?.path ?? value;
    return path.endsWith('.mp3') ||
        path.endsWith('.m4a') ||
        path.endsWith('.aac') ||
        path.endsWith('.wav') ||
        path.endsWith('.ogg') ||
        path.endsWith('.flac');
  }
}

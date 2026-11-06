import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../models/music_model.dart';
import 'music_service.dart';
import 'storage_service.dart';

class ApiMusicService implements MusicService {
  final http.Client _client;
  final StorageService? storageService;
  final String? _customBaseUrl;

  ApiMusicService({http.Client? client, this.storageService, String? baseUrl})
    : _client = client ?? http.Client(),
      _customBaseUrl = baseUrl;

  String get baseUrl {
    final custom = _customBaseUrl;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return ApiConfig.baseUrl;
  }

  Future<String?> _getToken() async {
    final storage = storageService ?? await StorageService.getInstance();
    return storage.getToken();
  }

  @override
  Future<List<MusicModel>> getMusic({String? search}) async {
    final query = search?.trim();
    final queryString = (query != null && query.isNotEmpty)
        ? '?search=${Uri.encodeComponent(query)}'
        : '';
    final url = Uri.parse('$baseUrl/music$queryString');

    try {
      final token = await _getToken();
      final headers = {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await _client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final rawList = decoded['data'];
          if (rawList is List) {
            return rawList
                .whereType<Map<String, dynamic>>()
                .map(MusicModel.fromJson)
                .toList();
          }
        }
        return [];
      }

      throw Exception('Gagal memuat daftar musik (${response.statusCode}).');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis saat memuat musik.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghubungi server.');
    }
  }
}

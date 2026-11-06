import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karaoke_app/core/services/api_music_service.dart';
import 'package:karaoke_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.getInstance();
  });

  test('getMusic returns active music from API', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, '/api/music');
      expect(request.method, 'GET');

      return http.Response(
        jsonEncode({
          'data': [
            {
              'musicid': 1,
              'musictitle': 'Nyanyian Pagi',
              'musicartist': 'NRM',
              'musicduration': 225,
              'cover_url': 'https://example.com/cover.jpg',
              'stream_url': 'https://example.com/api/music/1/stream',
              'is_active': true,
            },
            {
              'musicid': 2,
              'musictitle': 'Nyanyian Sore',
              'musicartist': 'NRM',
              'musicduration': 198,
              'stream_url': 'https://example.com/api/music/2/stream',
              'is_active': true,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = ApiMusicService(
      client: mockClient,
      storageService: storageService,
      baseUrl: 'http://127.0.0.1:8000/api',
    );

    final result = await service.getMusic();

    expect(result, hasLength(2));
    expect(result.first.musictitle, 'Nyanyian Pagi');
    expect(result.first.streamUrl, 'https://example.com/api/music/1/stream');
  });

  test('getMusic sends search query', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.queryParameters['search'], 'pagi');
      return http.Response(jsonEncode({'data': []}), 200);
    });

    final service = ApiMusicService(
      client: mockClient,
      storageService: storageService,
      baseUrl: 'http://127.0.0.1:8000/api',
    );

    expect(await service.getMusic(search: 'pagi'), isEmpty);
  });

  test('getMusic throws on server error', () async {
    final mockClient = MockClient((request) async {
      return http.Response('Server error', 500);
    });

    final service = ApiMusicService(
      client: mockClient,
      storageService: storageService,
      baseUrl: 'http://127.0.0.1:8000/api',
    );

    expect(() => service.getMusic(), throwsA(isA<Exception>()));
  });
}

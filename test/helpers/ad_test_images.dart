import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaoke_app/widgets/ad_slot_view.dart';

/// PNG 1×1 transparan untuk menggantikan gambar iklan jaringan di test.
final Uint8List kTestAdImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

final ImageProvider kTestAdImageProvider = MemoryImage(kTestAdImageBytes);

/// Arahkan semua gambar iklan ke gambar lokal agar test tidak butuh jaringan.
void useTestAdImages() {
  AdSlotView.debugImageProviderBuilder = (_) => kTestAdImageProvider;
}

/// Kembalikan perilaku gambar iklan ke `NetworkImage`.
void resetTestAdImages() {
  AdSlotView.debugImageProviderBuilder = null;
}

/// Biarkan decoding gambar iklan selesai, lalu pump.
///
/// Gambar di widget test tidak selesai di fake async, sehingga perlu
/// [WidgetTester.runAsync] sebelum slot iklan bisa tampil.
Future<void> settleAdImages(WidgetTester tester) async {
  final Finder app = find.byType(MaterialApp);
  if (app.evaluate().isNotEmpty) {
    await tester.runAsync(
      () => precacheImage(kTestAdImageProvider, tester.element(app.first)),
    );
  } else {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  }
  await tester.pumpAndSettle();
}

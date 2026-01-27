import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:sehatlocker/services/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'com.sehatlocker/apple_vision_ocr';
  const channel = MethodChannel(channelName);

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'extractText') return null;
      final args = call.arguments as Map?;
      final imagePath = args?['imagePath'] as String?;
      if (imagePath == null) throw PlatformException(code: 'bad_args');
      return 'Patient: John Doe\nHemoglobin 13.5 g/dL';
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('extractTextFromImage uses Apple Vision channel on macOS', () async {
    final dir = await Directory.systemTemp.createTemp('ocr_service_test_');
    final file = File(p.join(dir.path, 'sample.jpg'));

    final image = img.Image(width: 256, height: 128);
    img.fill(image, color: img.ColorUint8.rgb(255, 255, 255));
    await file.writeAsBytes(img.encodeJpg(image, quality: 90), flush: true);

    final extracted = await OCRService.extractTextFromImage(file);
    expect(extracted, contains('Hemoglobin'));

    await dir.delete(recursive: true);
  });
}


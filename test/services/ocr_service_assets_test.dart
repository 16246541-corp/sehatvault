import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sehatlocker/services/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tesseract tessdata_config asset is present and valid', () async {
    final raw = await rootBundle.loadString('assets/tessdata_config.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final files = (decoded['files'] as List).cast<String>();
    expect(files, contains('eng.traineddata'));
    expect(files, contains('osd.traineddata'));

    for (final file in files) {
      final data = await rootBundle.load('assets/tessdata/$file');
      expect(data.lengthInBytes, greaterThan(0));
    }
  });

  test('extractTextFromFile reads .txt files without OCR', () async {
    final dir = await Directory.systemTemp.createTemp('ocr_txt_test_');
    final file = File('${dir.path}/report.txt');
    await file.writeAsString('Hemoglobin: 13.8 g/dL\n', flush: true);

    final text = await OCRService.extractTextFromFile(file);
    expect(text, contains('Hemoglobin'));
  });

  test('extractTextFromImageBytes writes a readable temp file', () async {
    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    final original = OCRService.tesseractExtractTextOverride;
    try {
      final dir = await Directory.systemTemp.createTemp('ocr_tmp_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (call) async {
        if (call.method == 'getTemporaryDirectory') return dir.path;
        if (call.method == 'getApplicationDocumentsDirectory') return dir.path;
        return null;
      });

      OCRService.tesseractExtractTextOverride =
          (String imagePath, {String? language, Map? args}) async {
        final f = File(imagePath);
        expect(await f.exists(), isTrue);
        expect(await f.length(), greaterThan(0));
        return 'mock ocr';
      };

      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      final bytes = Uint8List.fromList(img.encodePng(image));
      final text = await OCRService.extractTextFromImageBytes(bytes);
      expect(text, contains('mock ocr'));
    } finally {
      OCRService.tesseractExtractTextOverride = original;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
    }
  });
}

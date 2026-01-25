import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  /// Compresses an image to approximately 2 megapixels.
  /// 2MP is roughly 1,997,568 pixels (1632x1224).
  /// This method uses flutter_image_compress to downscale the image while
  /// maintaining aspect ratio and respecting EXIF rotation.
  static Future<String> compressImage(File file) async {
    if (!await file.exists()) {
      throw Exception("Input file does not exist");
    }

    final tempDir = await getTemporaryDirectory();
    final targetPath =
        p.join(tempDir.path, 'compressed_${const Uuid().v4()}.jpg');

    // flutter_image_compress will resize such that it fits within minWidth/minHeight
    // while maintaining aspect ratio. 1632x1224 targets ~2MP for 4:3 images.
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 1632,
      minHeight: 1224,
      rotate: 0, // 0 means auto-rotation based on EXIF
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception("Compression failed");
    }

    return result.path;
  }
}

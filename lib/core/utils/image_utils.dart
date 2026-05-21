import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  /// Compress an image file to reduce size before upload
  /// 
  /// Parameters:
  /// - [file]: The original image file
  /// - [maxWidth]: Maximum width in pixels (default: 1920)
  /// - [maxHeight]: Maximum height in pixels (default: 1080)
  /// - [quality]: JPEG quality 0-100 (default: 85)
  /// 
  /// Returns compressed file or null if compression fails
  static Future<File?> compressImage(
    File file, {
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    try {
      // Get temporary directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        return null;
      }

      return File(result.path);
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return null;
    }
  }

  /// Compress multiple images in parallel
  /// 
  /// Returns list of compressed files, null entries indicate compression failures
  static Future<List<File?>> compressImages(
    List<File> files, {
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    return Future.wait(
      files.map((file) => compressImage(
            file,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
          )),
    );
  }

  /// Get the size of a file in bytes
  static Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Format file size to human-readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validate image file size
  /// Returns true if file is within the size limit
  static Future<bool> validateFileSize(File file, int maxSizeInBytes) async {
    final size = await getFileSize(file);
    return size <= maxSizeInBytes;
  }
}

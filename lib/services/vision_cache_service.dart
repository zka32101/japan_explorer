import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Cache for "What is This" and "Menu Translator" analyses
class VisionCacheService {
  static const _visionCacheBox = 'vision_cache';
  static const _cacheDir = 'vision_cache_images';

  late Box<VisionCacheEntry> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<VisionCacheEntry>(_visionCacheBox);
  }

  /// Save analysis result with cached image
  Future<void> cacheAnalysis({
    required String imageHash,
    required String analysisType, // 'what_is_this' or 'menu_translator'
    required String resultJson,
    required File imageFile,
  }) async {
    try {
      // Save image locally
      final cacheDir = await _getCacheDir();
      final imagePath = '${cacheDir.path}/$imageHash.jpg';
      await imageFile.copy(imagePath);

      // Save analysis result
      final entry = VisionCacheEntry(
        imageHash: imageHash,
        analysisType: analysisType,
        resultJson: resultJson,
        imagePath: imagePath,
        cachedAt: DateTime.now(),
      );

      await _box.put(imageHash, entry);
    } catch (e) {
      print('Error caching analysis: $e');
    }
  }

  /// Retrieve cached analysis
  VisionCacheEntry? getAnalysis(String imageHash) {
    return _box.get(imageHash);
  }

  /// List all cached analyses of a type
  List<VisionCacheEntry> getAnalysesByType(String analysisType) {
    return _box.values
        .where((entry) => entry.analysisType == analysisType)
        .toList();
  }

  /// Clear old cache (older than 7 days)
  Future<void> clearOldCache({int daysOld = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final keysToDelete = <String>[];

    for (var entry in _box.values) {
      if (entry.cachedAt.isBefore(cutoffDate)) {
        keysToDelete.add(entry.imageHash);
        try {
          if (File(entry.imagePath).existsSync()) {
            await File(entry.imagePath).delete();
          }
        } catch (e) {
          print('Error deleting cached image: $e');
        }
      }
    }

    for (var key in keysToDelete) {
      await _box.delete(key);
    }
  }

  /// Get cache size in MB
  Future<double> getCacheSizeMB() async {
    double totalSize = 0;
    final cacheDir = await _getCacheDir();

    if (!cacheDir.existsSync()) return 0;

    final files = cacheDir.listSync();
    for (var file in files) {
      if (file is File) {
        totalSize += file.lengthSync();
      }
    }

    return totalSize / (1024 * 1024); // Convert to MB
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      final cacheDir = await _getCacheDir();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      await _box.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<Directory> _getCacheDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${docDir.path}/$_cacheDir');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    return cacheDir;
  }
}

// Hive model for cache entry
class VisionCacheEntry {
  final String imageHash;
  final String analysisType; // 'what_is_this' or 'menu_translator'
  final String resultJson;
  final String imagePath;
  final DateTime cachedAt;

  VisionCacheEntry({
    required this.imageHash,
    required this.analysisType,
    required this.resultJson,
    required this.imagePath,
    required this.cachedAt,
  });
}

// Hive adapter (register in main.dart)
class VisionCacheEntryAdapter extends TypeAdapter<VisionCacheEntry> {
  @override
  final typeId = 20; // Unique ID for this adapter

  @override
  VisionCacheEntry read(BinaryReader reader) {
    return VisionCacheEntry(
      imageHash: reader.readString(),
      analysisType: reader.readString(),
      resultJson: reader.readString(),
      imagePath: reader.readString(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, VisionCacheEntry obj) {
    writer.writeString(obj.imageHash);
    writer.writeString(obj.analysisType);
    writer.writeString(obj.resultJson);
    writer.writeString(obj.imagePath);
    writer.writeInt(obj.cachedAt.millisecondsSinceEpoch);
  }
}

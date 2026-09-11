import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  /// Upload a post image to Firebase Storage, returns download URL.
  Future<String> uploadPostImage(String userId, File file) async {
    final compressed = await _compressImage(file);
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref('posts/$userId/$fileName');
    final snapshot = await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload avatar image, returns download URL.
  Future<String> uploadAvatar(String userId, File file) async {
    final compressed = await _compressImage(file, maxDimension: 400);
    final ref = _storage.ref('avatars/$userId/avatar.jpg');
    final snapshot = await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await snapshot.ref.getDownloadURL();
  }

  Future<Uint8List> _compressImage(File file, {int maxDimension = 1024}) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    img.Image resized = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : -1,
        height: decoded.height > decoded.width ? maxDimension : -1,
      );
    }

    var quality = 85;
    var encoded = img.encodeJpg(resized, quality: quality);
    while (encoded.length > AppConstants.imageMaxSizeBytes && quality > 40) {
      quality -= 10;
      encoded = img.encodeJpg(resized, quality: quality);
    }
    return Uint8List.fromList(encoded);
  }
}

final uploadServiceProvider = Provider<UploadService>((_) => UploadService());

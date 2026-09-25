import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Picks media from the device and uploads it to Cloud Storage, returning a
/// public download URL. Upload paths mirror the Storage security rules:
/// everything is scoped under the uploader's uid.
class StorageService {
  StorageService({FirebaseStorage? storage, ImagePicker? picker})
      : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _picker;

  /// Opens the gallery (or camera) and returns the local file path, or null if
  /// the user cancelled. Images are downscaled to keep uploads light.
  Future<String?> pickImage({bool fromCamera = false}) async {
    final x = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 82,
    );
    return x?.path;
  }

  /// Uploads a local image file to [storagePath] and returns its download URL.
  Future<String> uploadImage(String localPath, String storagePath) async {
    final ref = _storage.ref(storagePath);
    await ref.putFile(File(localPath), SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Uploads any local file (e.g. a CSV) to [storagePath] and returns its URL.
  Future<String> uploadFile(String localPath, String storagePath, {String? contentType}) async {
    final ref = _storage.ref(storagePath);
    await ref.putFile(
      File(localPath),
      contentType != null ? SettableMetadata(contentType: contentType) : null,
    );
    return ref.getDownloadURL();
  }

  // ── Typed helpers (paths must match storage.rules) ──────────────
  Future<String> uploadUserPhoto(String uid, String localPath) =>
      uploadImage(localPath, 'user_photos/$uid/avatar.jpg');

  Future<String> uploadMemberPhoto(String uid, String memberId, String localPath) =>
      uploadImage(localPath, 'member_photos/$uid/$memberId.jpg');

  Future<String> uploadAttachment(String uid, String name, String localPath, {String? contentType}) =>
      uploadFile(localPath, 'attachments/$uid/$name', contentType: contentType);

  Future<String> uploadImport(String uid, String name, String localPath) =>
      uploadFile(localPath, 'imports/$uid/$name', contentType: 'text/csv');
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

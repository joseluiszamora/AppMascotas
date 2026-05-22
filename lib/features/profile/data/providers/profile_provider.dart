import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/profile_entity.dart';
import '../models/profile_model.dart';

class ProfileProvider {
  const ProfileProvider({required this.supabase});

  final SupabaseClient supabase;
  static const _storageBucket = 'profile-avatars';
  static const _supportedMimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'gif': 'image/gif',
  };

  Future<ProfileEntity> getProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  Future<ProfileEntity> updateProfile(
    ProfileEntity profile, {
    File? avatarFile,
    bool removeAvatar = false,
  }) async {
    String? nextAvatarUrl = profile.avatarUrl;
    String? uploadedPath;

    try {
      if (avatarFile != null) {
        final result = await _uploadAvatar(profile.id, avatarFile);
        uploadedPath = result.path;
        nextAvatarUrl = result.publicUrl;
      } else if (removeAvatar) {
        nextAvatarUrl = null;
      }

      final data = await supabase
          .from('profiles')
          .update(ProfileModel.toUpdateJson(profile, avatarUrl: nextAvatarUrl))
          .eq('id', profile.id)
          .select()
          .single();

      if (avatarFile != null && profile.avatarUrl != null) {
        await _removeAvatarByUrl(profile.avatarUrl!);
      } else if (removeAvatar && profile.avatarUrl != null) {
        await _removeAvatarByUrl(profile.avatarUrl!);
      }

      return ProfileModel.fromJson(data);
    } catch (error) {
      if (uploadedPath != null) {
        try {
          await supabase.storage.from(_storageBucket).remove([uploadedPath]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  String _mimeTypeForExtension(String ext) {
    final normalizedExt = ext.toLowerCase();
    final mimeType = _supportedMimeTypes[normalizedExt];
    if (mimeType == null) {
      throw const StorageException(
        'Formato de imagen no soportado. Usa JPG, PNG, WEBP, GIF o HEIC.',
        statusCode: '415',
      );
    }
    return mimeType;
  }

  String _resolveExtension(String path, Uint8List bytes) {
    final rawExt = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    if (_supportedMimeTypes.containsKey(rawExt)) {
      return rawExt;
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }

    if (bytes.length >= 6) {
      final header = String.fromCharCodes(bytes.sublist(0, 6));
      if (header == 'GIF87a' || header == 'GIF89a') {
        return 'gif';
      }
    }

    if (bytes.length >= 12) {
      final boxType = String.fromCharCodes(bytes.sublist(4, 8));
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (boxType == 'ftyp') {
        if (brand.startsWith('hei')) return 'heic';
        if (brand.startsWith('mif') || brand.startsWith('msf')) return 'heif';
      }
    }

    throw const StorageException(
      'Formato de imagen no soportado. Usa JPG, PNG, WEBP, GIF o HEIC.',
      statusCode: '415',
    );
  }

  Future<({String path, String publicUrl})> _uploadAvatar(
    String userId,
    File file,
  ) async {
    final bytes = await file.readAsBytes();
    final ext = _resolveExtension(file.path, bytes);
    final mimeType = _mimeTypeForExtension(ext);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await supabase.storage
        .from(_storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    return (
      path: path,
      publicUrl: supabase.storage.from(_storageBucket).getPublicUrl(path),
    );
  }

  Future<void> _removeAvatarByUrl(String avatarUrl) async {
    try {
      final uri = Uri.parse(avatarUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_storageBucket);
      if (bucketIndex >= 0 && bucketIndex < segments.length - 1) {
        final storagePath = segments.sublist(bucketIndex + 1).join('/');
        await supabase.storage.from(_storageBucket).remove([storagePath]);
      }
    } catch (_) {}
  }
}

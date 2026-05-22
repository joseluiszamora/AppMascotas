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
        .limit(1)
        .maybeSingle();

    if (data == null) {
      final seededProfile = await _seedProfileFromAuth(userId);
      return _hydrateMissingAuthFields(seededProfile);
    }

    final profile = ProfileModel.fromJson(data);
    return _hydrateMissingAuthFields(profile);
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

      final payload = {
        'id': profile.id,
        ...ProfileModel.toUpdateJson(profile, avatarUrl: nextAvatarUrl),
      };

      await supabase.from('profiles').upsert(payload, onConflict: 'id');

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', profile.id)
          .single();

      if (avatarFile != null && profile.avatarUrl != null) {
        await _removeAvatarByUrl(profile.avatarUrl!);
      } else if (removeAvatar && profile.avatarUrl != null) {
        await _removeAvatarByUrl(profile.avatarUrl!);
      }

      return _hydrateMissingAuthFields(ProfileModel.fromJson(data));
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

  Future<ProfileEntity> _seedProfileFromAuth(String userId) async {
    final authDefaults = _authDefaultsForCurrentUser(userId);
    final payload = {
      'id': userId,
      'first_name': authDefaults.firstName,
      'last_name': authDefaults.lastName,
      'avatar_url': authDefaults.avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await supabase.from('profiles').upsert(payload, onConflict: 'id');

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  Future<ProfileEntity> _hydrateMissingAuthFields(ProfileEntity profile) async {
    final authDefaults = _authDefaultsForCurrentUser(profile.id);
    final nextFirstName = _hasText(profile.firstName)
        ? profile.firstName
        : authDefaults.firstName;
    final nextLastName = _hasText(profile.lastName)
        ? profile.lastName
        : authDefaults.lastName;
    final nextAvatarUrl = _hasText(profile.avatarUrl)
        ? profile.avatarUrl
        : authDefaults.avatarUrl;

    if (nextFirstName == profile.firstName &&
        nextLastName == profile.lastName &&
        nextAvatarUrl == profile.avatarUrl) {
      return profile;
    }

    final updatedProfile = profile.copyWith(
      firstName: nextFirstName,
      lastName: nextLastName,
      avatarUrl: nextAvatarUrl,
    );

    final payload = {
      'id': profile.id,
      ...ProfileModel.toUpdateJson(updatedProfile, avatarUrl: nextAvatarUrl),
    };

    await supabase.from('profiles').upsert(payload, onConflict: 'id');
    return updatedProfile;
  }

  ({String? firstName, String? lastName, String? avatarUrl})
  _authDefaultsForCurrentUser(String userId) {
    final authUser = supabase.auth.currentUser;
    if (authUser == null || authUser.id != userId) {
      return (firstName: null, lastName: null, avatarUrl: null);
    }

    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    final fullName =
        _cleanString(metadata['full_name']) ?? _cleanString(metadata['name']);
    final givenName = _cleanString(metadata['given_name']);
    final familyName = _cleanString(metadata['family_name']);
    final parsedName = _splitFullName(fullName);

    return (
      firstName: givenName ?? parsedName.$1,
      lastName: familyName ?? parsedName.$2,
      avatarUrl:
          _cleanString(metadata['avatar_url']) ??
          _cleanString(metadata['picture']),
    );
  }

  (String?, String?) _splitFullName(String? fullName) {
    final normalized = _cleanString(fullName);
    if (normalized == null) return (null, null);

    final parts = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (null, null);
    if (parts.length == 1) return (parts.first, null);
    return (parts.first, parts.sublist(1).join(' '));
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String? _cleanString(dynamic value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

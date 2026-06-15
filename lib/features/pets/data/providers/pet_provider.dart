import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/pet_entity.dart';
import '../models/pet_model.dart';

class PetProvider {
  PetProvider({required this.supabase});

  final SupabaseClient supabase;

  static const _storageBucket = 'pet-photos';
  static const _supportedMimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'gif': 'image/gif',
  };

  String _mimeTypeForExtension(String ext) {
    final normalizedExt = ext.toLowerCase();
    final mimeType = _supportedMimeTypes[normalizedExt];
    if (mimeType == null) {
      throw StorageException(
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

    throw StorageException(
      'Formato de imagen no soportado. Usa JPG, PNG, WEBP, GIF o HEIC.',
      statusCode: '415',
    );
  }

  // ── Mascotas ─────────────────────────────────────────────────────────────

  Future<List<PetEntity>> getMyPets(String ownerId) async {
    final data = await supabase
        .from('pets')
        .select('*, pet_photos(*)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => PetModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<PetEntity> createPet(PetEntity pet) async {
    final data = await supabase
        .from('pets')
        .insert(PetModel.toJson(pet))
        .select('*, pet_photos(*)')
        .single();
    return PetModel.fromJson(data);
  }

  Future<PetEntity> updatePet(PetEntity pet) async {
    final data = await supabase
        .from('pets')
        .update(PetModel.toUpdateJson(pet))
        .eq('id', pet.id)
        .select('*, pet_photos(*)')
        .single();
    return PetModel.fromJson(data);
  }

  Future<void> deletePet(String petId) async {
    await supabase.from('pets').delete().eq('id', petId);
  }

  // ── Fotos ────────────────────────────────────────────────────────────────

  Future<PetPhotoEntity> uploadPhoto({
    required String petId,
    required File file,
    bool isPrimary = false,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final bytes = await file.readAsBytes();
    final ext = _resolveExtension(file.path, bytes);
    final mimeType = _mimeTypeForExtension(ext);
    final path = '$userId/$petId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await supabase.storage
        .from(_storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final url = supabase.storage.from(_storageBucket).getPublicUrl(path);

    final data = await supabase
        .from('pet_photos')
        .insert({'pet_id': petId, 'url': url, 'is_primary': isPrimary})
        .select()
        .single();

    return PetPhotoModel.fromJson(data);
  }

  Future<PetPhotoEntity> uploadPhotoBytes({
    required String petId,
    required Uint8List bytes,
    required String ext,
    bool isPrimary = false,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final normalizedExt = _resolveExtension('file.$ext', bytes);
    final mimeType = _mimeTypeForExtension(normalizedExt);
    final path =
        '$userId/$petId/${DateTime.now().millisecondsSinceEpoch}.$normalizedExt';

    await supabase.storage
        .from(_storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final url = supabase.storage.from(_storageBucket).getPublicUrl(path);

    final data = await supabase
        .from('pet_photos')
        .insert({'pet_id': petId, 'url': url, 'is_primary': isPrimary})
        .select()
        .single();

    return PetPhotoModel.fromJson(data);
  }

  Future<void> deletePhoto(String photoId, String storageUrl) async {
    // Eliminar registro de la tabla
    await supabase.from('pet_photos').delete().eq('id', photoId);

    // Intentar eliminar del storage (ignorar errores si ya no existe)
    try {
      final uri = Uri.parse(storageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_storageBucket);
      if (bucketIndex >= 0 && bucketIndex < segments.length - 1) {
        final storagePath = segments.sublist(bucketIndex + 1).join('/');
        await supabase.storage.from(_storageBucket).remove([storagePath]);
      }
    } catch (_) {
      // ignorar errores de limpieza de storage
    }
  }
}

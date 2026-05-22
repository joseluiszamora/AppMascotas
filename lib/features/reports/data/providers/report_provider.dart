import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/report_entity.dart';
import '../models/report_model.dart';

class ReportProvider {
  const ReportProvider({required this.supabase});

  final SupabaseClient supabase;
  static const _storageBucket = 'report-photos';
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

  Future<String> _uploadReportPhoto({
    required String reportId,
    required File file,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final bytes = await file.readAsBytes();
    final ext = _resolveExtension(file.path, bytes);
    final mimeType = _mimeTypeForExtension(ext);
    final path = '$userId/$reportId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await supabase.storage.from(_storageBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );

    return path;
  }

  Future<List<ReportEntity>> getRecentReports({int limit = 5}) async {
    final data = await supabase
        .from('reports')
        .select('*, report_photos(*), pets(name, breed, type, dominant_color, size)')
        .inFilter('status', ['active', 'under_review'])
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List<dynamic>)
        .map((row) => ReportModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReportEntity>> getMapReports() async {
    final data = await supabase
        .from('reports')
        .select('*, report_photos(*), pets(name, breed, type, dominant_color, size)')
        .inFilter('status', ['active', 'under_review'])
        .order('occurred_at', ascending: false)
        .limit(250);

    return (data as List<dynamic>)
        .map((row) => ReportModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ReportEntity> getReportById(String reportId) async {
    final data = await supabase
        .from('reports')
        .select('*, report_photos(*), pets(name, breed, type, dominant_color, size)')
        .eq('id', reportId)
        .single();

    return ReportModel.fromJson(data);
  }

  Future<ReportEntity> createFoundReport({
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
    required ReportPetType foundPetType,
    String? foundPetColor,
    ReportPetSize? foundPetSize,
    String? foundPetDescription,
    required List<File> photos,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final inserted = await supabase
        .from('reports')
        .insert({
          'reporter_id': userId,
          'type': 'found',
          'latitude': latitude,
          'longitude': longitude,
          'location_description': locationDescription,
          'occurred_at': occurredAt.toIso8601String(),
          'description': description,
          'show_contact': showContact,
          'found_pet_type': _petTypeToString(foundPetType),
          'found_pet_color': foundPetColor,
          'found_pet_size': _petSizeToString(foundPetSize),
          'found_pet_description': foundPetDescription,
        })
        .select()
        .single();

    final reportId = inserted['id'] as String;
    final uploadedPaths = <String>[];

    try {
      for (final photo in photos) {
        final storagePath = await _uploadReportPhoto(
          reportId: reportId,
          file: photo,
        );
        uploadedPaths.add(storagePath);
        final url = supabase.storage.from(_storageBucket).getPublicUrl(storagePath);

        await supabase.from('report_photos').insert({
          'report_id': reportId,
          'url': url,
        });
      }
    } catch (_) {
      await supabase.from('reports').delete().eq('id', reportId);
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage.from(_storageBucket).remove(uploadedPaths);
        } catch (_) {}
      }
      rethrow;
    }

    final data = await supabase
        .from('reports')
      .select('*, report_photos(*), pets(name, breed, type, dominant_color, size)')
        .eq('id', reportId)
        .single();

    return ReportModel.fromJson(data);
  }

  Future<ReportEntity> createLostReport({
    required String petId,
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
  }) async {
    final reportId = await supabase.rpc(
      'create_lost_report',
      params: {
        'p_pet_id': petId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_location_description': locationDescription,
        'p_occurred_at': occurredAt.toIso8601String(),
        'p_description': description,
        'p_show_contact': showContact,
      },
    ) as String;

    final data = await supabase
        .from('reports')
      .select('*, report_photos(*), pets(name, breed, type, dominant_color, size)')
        .eq('id', reportId)
        .single();

    return ReportModel.fromJson(data);
  }

  String _petTypeToString(ReportPetType type) => switch (type) {
    ReportPetType.dog => 'dog',
    ReportPetType.cat => 'cat',
    ReportPetType.other => 'other',
  };

  String? _petSizeToString(ReportPetSize? size) => switch (size) {
    ReportPetSize.small => 'small',
    ReportPetSize.medium => 'medium',
    ReportPetSize.large => 'large',
    ReportPetSize.extraLarge => 'extra_large',
    null => null,
  };
}
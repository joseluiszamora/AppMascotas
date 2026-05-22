import 'dart:io';

import '../entities/report_entity.dart';

abstract class ReportRepository {
  Future<List<ReportEntity>> getRecentReports({int limit = 5});

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
  });

  Future<ReportEntity> createLostReport({
    required String petId,
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
  });
}
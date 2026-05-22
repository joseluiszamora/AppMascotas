import 'dart:io';

import '../entities/report_entity.dart';
import '../entities/report_map_query.dart';

abstract class ReportRepository {
  Future<ReportEntity> getReportById(String reportId);

  Future<List<ReportEntity>> getMapReports(ReportMapQuery query);

  Future<List<ReportEntity>> getRecentReports({int limit = 5});

  Future<List<ReportEntity>> getMyReports({int limit = 100});

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
    List<File> photos = const [],
  });
}

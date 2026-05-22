import '../entities/report_entity.dart';

abstract class ReportRepository {
  Future<List<ReportEntity>> getRecentReports({int limit = 5});

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
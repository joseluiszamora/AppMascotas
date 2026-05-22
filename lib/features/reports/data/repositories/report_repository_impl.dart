import 'dart:io';

import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../providers/report_provider.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._provider);

  final ReportProvider _provider;

  @override
  Future<ReportEntity> getReportById(String reportId) {
    return _provider.getReportById(reportId);
  }

  @override
  Future<List<ReportEntity>> getMapReports() {
    return _provider.getMapReports();
  }

  @override
  Future<List<ReportEntity>> getRecentReports({int limit = 5}) {
    return _provider.getRecentReports(limit: limit);
  }

  @override
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
  }) {
    return _provider.createFoundReport(
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      occurredAt: occurredAt,
      description: description,
      showContact: showContact,
      foundPetType: foundPetType,
      foundPetColor: foundPetColor,
      foundPetSize: foundPetSize,
      foundPetDescription: foundPetDescription,
      photos: photos,
    );
  }

  @override
  Future<ReportEntity> createLostReport({
    required String petId,
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
  }) {
    return _provider.createLostReport(
      petId: petId,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      occurredAt: occurredAt,
      description: description,
      showContact: showContact,
    );
  }
}
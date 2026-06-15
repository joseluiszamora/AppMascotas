import 'dart:io';

import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class CreateLostReport {
  CreateLostReport(this._repository);

  final ReportRepository _repository;

  Future<ReportEntity> call({
    required String petId,
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
    List<File> photos = const [],
  }) {
    return _repository.createLostReport(
      petId: petId,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      occurredAt: occurredAt,
      description: description,
      showContact: showContact,
      photos: photos,
    );
  }
}

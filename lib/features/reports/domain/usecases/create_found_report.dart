import 'dart:io';

import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class CreateFoundReport {
  const CreateFoundReport(this._repository);

  final ReportRepository _repository;

  Future<ReportEntity> call({
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
    return _repository.createFoundReport(
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
}

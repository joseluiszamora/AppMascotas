import 'package:equatable/equatable.dart';

enum ReportType { lost, found }

enum ReportStatus { active, underReview, resolved, closed, reported }

enum ReportPetType { dog, cat, other }

enum ReportPetSize { small, medium, large, extraLarge }

class ReportPhotoEntity extends Equatable {
  const ReportPhotoEntity({
    required this.id,
    required this.reportId,
    required this.url,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String url;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, reportId, url, createdAt];
}

class ReportEntity extends Equatable {
  const ReportEntity({
    required this.id,
    required this.reporterId,
    this.petId,
    this.petName,
    this.petBreed,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.locationDescription,
    required this.occurredAt,
    this.description,
    this.status = ReportStatus.active,
    this.showContact = false,
    this.foundPetType,
    this.foundPetColor,
    this.foundPetSize,
    this.foundPetDescription,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reporterId;
  final String? petId;
  final String? petName;
  final String? petBreed;
  final ReportType type;
  final double latitude;
  final double longitude;
  final String? locationDescription;
  final DateTime occurredAt;
  final String? description;
  final ReportStatus status;
  final bool showContact;
  final ReportPetType? foundPetType;
  final String? foundPetColor;
  final ReportPetSize? foundPetSize;
  final String? foundPetDescription;
  final List<ReportPhotoEntity> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get primaryPhotoUrl => photos.isEmpty ? null : photos.first.url;

  @override
  List<Object?> get props => [
    id,
    reporterId,
    petId,
    petName,
    petBreed,
    type,
    latitude,
    longitude,
    locationDescription,
    occurredAt,
    description,
    status,
    showContact,
    foundPetType,
    foundPetColor,
    foundPetSize,
    foundPetDescription,
    photos,
    createdAt,
    updatedAt,
  ];
}
import '../../domain/entities/report_entity.dart';

class ReportPhotoModel {
  static ReportPhotoEntity fromJson(Map<String, dynamic> json) {
    return ReportPhotoEntity(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReportModel {
  static ReportEntity fromJson(Map<String, dynamic> json) {
    final photosRaw = json['report_photos'] as List<dynamic>? ?? [];
    final petRaw = json['pets'] as Map<String, dynamic>?;

    return ReportEntity(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      petId: json['pet_id'] as String?,
      petName: petRaw?['name'] as String?,
      petBreed: petRaw?['breed'] as String?,
      petType: _parsePetType(petRaw?['type'] as String?),
      petColor: petRaw?['dominant_color'] as String?,
      petSize: _parsePetSize(petRaw?['size'] as String?),
      type: _parseType(json['type'] as String),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      locationDescription: json['location_description'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'active'),
      showContact: json['show_contact'] as bool? ?? false,
      foundPetType: _parsePetType(json['found_pet_type'] as String?),
      foundPetColor: json['found_pet_color'] as String?,
      foundPetSize: _parsePetSize(json['found_pet_size'] as String?),
      foundPetDescription: json['found_pet_description'] as String?,
      photos: photosRaw
          .map((photo) => ReportPhotoModel.fromJson(photo as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('No se pudo parsear el valor decimal: $value');
  }

  static ReportType _parseType(String value) => switch (value) {
    'found' => ReportType.found,
    _ => ReportType.lost,
  };

  static ReportStatus _parseStatus(String value) => switch (value) {
    'under_review' => ReportStatus.underReview,
    'resolved' => ReportStatus.resolved,
    'closed' => ReportStatus.closed,
    'reported' => ReportStatus.reported,
    _ => ReportStatus.active,
  };

  static ReportPetType? _parsePetType(String? value) => switch (value) {
    'dog' => ReportPetType.dog,
    'cat' => ReportPetType.cat,
    'other' => ReportPetType.other,
    _ => null,
  };

  static ReportPetSize? _parsePetSize(String? value) => switch (value) {
    'small' => ReportPetSize.small,
    'medium' => ReportPetSize.medium,
    'large' => ReportPetSize.large,
    'extra_large' => ReportPetSize.extraLarge,
    _ => null,
  };
}
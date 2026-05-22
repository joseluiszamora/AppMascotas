import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum PetType { dog, cat, other }

enum PetSex { male, female, unknown }

enum PetSize { small, medium, large, extraLarge }

enum PetStatus { normal, lost, found }

// ─────────────────────────────────────────────
// PetPhotoEntity
// ─────────────────────────────────────────────

class PetPhotoEntity extends Equatable {
  const PetPhotoEntity({
    required this.id,
    required this.petId,
    required this.url,
    this.isPrimary = false,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final String url;
  final bool isPrimary;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, petId, url, isPrimary, createdAt];
}

// ─────────────────────────────────────────────
// PetEntity
// ─────────────────────────────────────────────

class PetEntity extends Equatable {
  const PetEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.breed,
    this.sex = PetSex.unknown,
    this.ageYears,
    this.ageMonths,
    this.dominantColor,
    this.size = PetSize.medium,
    this.distinctiveFeatures,
    this.isVaccinated = false,
    this.isSterilized = false,
    this.chipNumber,
    this.status = PetStatus.normal,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final PetType type;
  final String? breed;
  final PetSex sex;
  final int? ageYears;
  final int? ageMonths;
  final String? dominantColor;
  final PetSize size;
  final String? distinctiveFeatures;
  final bool isVaccinated;
  final bool isSterilized;
  final String? chipNumber;
  final PetStatus status;
  final List<PetPhotoEntity> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// URL de la foto principal, o null si no tiene fotos.
  String? get primaryPhotoUrl {
    if (photos.isEmpty) return null;
    final primary = photos.where((p) => p.isPrimary).firstOrNull;
    return primary?.url ?? photos.first.url;
  }

  PetEntity copyWith({
    String? name,
    PetType? type,
    String? breed,
    PetSex? sex,
    int? ageYears,
    int? ageMonths,
    String? dominantColor,
    PetSize? size,
    String? distinctiveFeatures,
    bool? isVaccinated,
    bool? isSterilized,
    String? chipNumber,
    PetStatus? status,
    List<PetPhotoEntity>? photos,
  }) {
    return PetEntity(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      ageYears: ageYears ?? this.ageYears,
      ageMonths: ageMonths ?? this.ageMonths,
      dominantColor: dominantColor ?? this.dominantColor,
      size: size ?? this.size,
      distinctiveFeatures: distinctiveFeatures ?? this.distinctiveFeatures,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isSterilized: isSterilized ?? this.isSterilized,
      chipNumber: chipNumber ?? this.chipNumber,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    type,
    breed,
    sex,
    ageYears,
    ageMonths,
    dominantColor,
    size,
    distinctiveFeatures,
    isVaccinated,
    isSterilized,
    chipNumber,
    status,
    photos,
    createdAt,
    updatedAt,
  ];
}

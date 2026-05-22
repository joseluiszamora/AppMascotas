import '../../domain/entities/pet_entity.dart';

// ─────────────────────────────────────────────
// PetPhotoModel
// ─────────────────────────────────────────────

class PetPhotoModel {
  static PetPhotoEntity fromJson(Map<String, dynamic> json) {
    return PetPhotoEntity(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      url: json['url'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─────────────────────────────────────────────
// PetModel
// ─────────────────────────────────────────────

class PetModel {
  static PetEntity fromJson(Map<String, dynamic> json) {
    final photosRaw = json['pet_photos'] as List<dynamic>? ?? [];
    final photos = photosRaw
        .map((p) => PetPhotoModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return PetEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      type: _parseType(json['type'] as String),
      breed: json['breed'] as String?,
      sex: _parseSex(json['sex'] as String? ?? 'unknown'),
      ageYears: json['age_years'] as int?,
      ageMonths: json['age_months'] as int?,
      dominantColor: json['dominant_color'] as String?,
      size: _parseSize(json['size'] as String? ?? 'medium'),
      distinctiveFeatures: json['distinctive_features'] as String?,
      isVaccinated: json['is_vaccinated'] as bool? ?? false,
      isSterilized: json['is_sterilized'] as bool? ?? false,
      chipNumber: json['chip_number'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'normal'),
      photos: photos,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Serializa solo los campos editables para INSERT/UPDATE.
  static Map<String, dynamic> toJson(PetEntity pet) {
    return {
      'owner_id': pet.ownerId,
      'name': pet.name,
      'type': _typeToString(pet.type),
      'breed': pet.breed,
      'sex': _sexToString(pet.sex),
      'age_years': pet.ageYears,
      'age_months': pet.ageMonths,
      'dominant_color': pet.dominantColor,
      'size': _sizeToString(pet.size),
      'distinctive_features': pet.distinctiveFeatures,
      'is_vaccinated': pet.isVaccinated,
      'is_sterilized': pet.isSterilized,
      'chip_number': pet.chipNumber,
      'status': _statusToString(pet.status),
    };
  }

  /// Solo los campos editables (sin owner_id) para UPDATE.
  static Map<String, dynamic> toUpdateJson(PetEntity pet) {
    return {
      'name': pet.name,
      'type': _typeToString(pet.type),
      'breed': pet.breed,
      'sex': _sexToString(pet.sex),
      'age_years': pet.ageYears,
      'age_months': pet.ageMonths,
      'dominant_color': pet.dominantColor,
      'size': _sizeToString(pet.size),
      'distinctive_features': pet.distinctiveFeatures,
      'is_vaccinated': pet.isVaccinated,
      'is_sterilized': pet.isSterilized,
      'chip_number': pet.chipNumber,
      'status': _statusToString(pet.status),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // ── Parsers ──────────────────────────────────

  static PetType _parseType(String v) => switch (v) {
    'dog' => PetType.dog,
    'cat' => PetType.cat,
    _ => PetType.other,
  };

  static String _typeToString(PetType t) => switch (t) {
    PetType.dog => 'dog',
    PetType.cat => 'cat',
    PetType.other => 'other',
  };

  static PetSex _parseSex(String v) => switch (v) {
    'male' => PetSex.male,
    'female' => PetSex.female,
    _ => PetSex.unknown,
  };

  static String _sexToString(PetSex s) => switch (s) {
    PetSex.male => 'male',
    PetSex.female => 'female',
    PetSex.unknown => 'unknown',
  };

  static PetSize _parseSize(String v) => switch (v) {
    'small' => PetSize.small,
    'large' => PetSize.large,
    'extra_large' => PetSize.extraLarge,
    _ => PetSize.medium,
  };

  static String _sizeToString(PetSize s) => switch (s) {
    PetSize.small => 'small',
    PetSize.medium => 'medium',
    PetSize.large => 'large',
    PetSize.extraLarge => 'extra_large',
  };

  static PetStatus _parseStatus(String v) => switch (v) {
    'lost' => PetStatus.lost,
    'found' => PetStatus.found,
    _ => PetStatus.normal,
  };

  static String _statusToString(PetStatus s) => switch (s) {
    PetStatus.normal => 'normal',
    PetStatus.lost => 'lost',
    PetStatus.found => 'found',
  };
}

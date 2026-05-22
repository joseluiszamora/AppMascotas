import 'dart:io';

import '../../domain/entities/pet_entity.dart';
import '../../domain/repositories/pet_repository.dart';
import '../providers/pet_provider.dart';

class PetRepositoryImpl implements PetRepository {
  const PetRepositoryImpl(this._provider);
  final PetProvider _provider;

  @override
  Future<List<PetEntity>> getMyPets(String ownerId) =>
      _provider.getMyPets(ownerId);

  @override
  Future<PetEntity> createPet(PetEntity pet) => _provider.createPet(pet);

  @override
  Future<PetEntity> updatePet(PetEntity pet) => _provider.updatePet(pet);

  @override
  Future<void> deletePet(String petId) => _provider.deletePet(petId);

  @override
  Future<PetPhotoEntity> uploadPhoto({
    required String petId,
    required File file,
    bool isPrimary = false,
  }) => _provider.uploadPhoto(petId: petId, file: file, isPrimary: isPrimary);

  @override
  Future<void> deletePhoto(String photoId, String storageUrl) =>
      _provider.deletePhoto(photoId, storageUrl);
}

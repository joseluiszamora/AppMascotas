import 'dart:io';

import '../entities/pet_entity.dart';

abstract class PetRepository {
  /// Devuelve todas las mascotas del usuario autenticado.
  Future<List<PetEntity>> getMyPets(String ownerId);

  /// Crea una nueva mascota y devuelve la entidad con id asignado.
  Future<PetEntity> createPet(PetEntity pet);

  /// Actualiza una mascota existente.
  Future<PetEntity> updatePet(PetEntity pet);

  /// Elimina una mascota por id.
  Future<void> deletePet(String petId);

  /// Sube una foto al storage y la registra en pet_photos.
  Future<PetPhotoEntity> uploadPhoto({
    required String petId,
    required File file,
    bool isPrimary = false,
  });

  /// Elimina una foto por id.
  Future<void> deletePhoto(String photoId, String storageUrl);
}

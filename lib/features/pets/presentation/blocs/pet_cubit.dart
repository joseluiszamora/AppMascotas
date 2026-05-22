import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/pet_entity.dart';
import '../../domain/usecases/create_pet.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/get_my_pets.dart';
import '../../domain/usecases/update_pet.dart';
import '../../../pets/domain/repositories/pet_repository.dart';
import 'pet_state.dart';

class PetCubit extends Cubit<PetState> {
  PetCubit({
    required GetMyPets getMyPets,
    required CreatePet createPet,
    required UpdatePet updatePet,
    required DeletePet deletePet,
    required PetRepository repository,
  }) : _getMyPets = getMyPets,
       _createPet = createPet,
       _updatePet = updatePet,
       _deletePet = deletePet,
       _repository = repository,
       super(const PetInitial());

  final GetMyPets _getMyPets;
  final CreatePet _createPet;
  final UpdatePet _updatePet;
  final DeletePet _deletePet;
  final PetRepository _repository;

  List<PetEntity> get _currentPets {
    return switch (state) {
      PetLoaded(:final pets) => pets,
      PetOperationInProgress(:final pets) => pets,
      PetOperationSuccess(:final pets) => pets,
      PetError(:final pets) => pets,
      _ => const [],
    };
  }

  Future<void> loadPets(String ownerId) async {
    emit(const PetLoading());
    try {
      final pets = await _getMyPets(ownerId);
      emit(PetLoaded(pets));
    } catch (e) {
      emit(PetError(message: _mapError(e)));
    }
  }

  Future<PetEntity?> createPet(PetEntity pet) async {
    emit(PetOperationInProgress(_currentPets));
    try {
      final created = await _createPet(pet);
      final updated = [created, ..._currentPets];
      emit(PetOperationSuccess(pets: updated, message: '¡Mascota registrada!'));
      return created;
    } catch (e) {
      emit(PetError(message: _mapError(e), pets: _currentPets));
      return null;
    }
  }

  Future<void> updatePet(PetEntity pet) async {
    final prev = _currentPets;
    emit(PetOperationInProgress(prev));
    try {
      final updated = await _updatePet(pet);
      final newList = prev
          .map((p) => p.id == updated.id ? updated : p)
          .toList();
      emit(PetOperationSuccess(pets: newList, message: 'Mascota actualizada.'));
    } catch (e) {
      emit(PetError(message: _mapError(e), pets: prev));
    }
  }

  Future<void> deletePet(String petId) async {
    final prev = _currentPets;
    emit(PetOperationInProgress(prev));
    try {
      await _deletePet(petId);
      final newList = prev.where((p) => p.id != petId).toList();
      emit(PetOperationSuccess(pets: newList, message: 'Mascota eliminada.'));
    } catch (e) {
      emit(PetError(message: _mapError(e), pets: prev));
    }
  }

  Future<PetPhotoEntity?> uploadPhoto({
    required String petId,
    required File file,
    bool isPrimary = false,
  }) async {
    try {
      final photo = await _repository.uploadPhoto(
        petId: petId,
        file: file,
        isPrimary: isPrimary,
      );
      // Actualizar la foto en la lista local
      final newList = _currentPets.map((p) {
        if (p.id != petId) return p;
        return p.copyWith(photos: [...p.photos, photo]);
      }).toList();
      emit(PetLoaded(newList));
      return photo;
    } catch (e) {
      emit(PetError(message: _mapError(e), pets: _currentPets));
      return null;
    }
  }

  Future<void> deletePhoto(
    String photoId,
    String storageUrl,
    String petId,
  ) async {
    try {
      await _repository.deletePhoto(photoId, storageUrl);
      final newList = _currentPets.map((p) {
        if (p.id != petId) return p;
        return p.copyWith(
          photos: p.photos.where((ph) => ph.id != photoId).toList(),
        );
      }).toList();
      emit(PetLoaded(newList));
    } catch (e) {
      emit(PetError(message: _mapError(e), pets: _currentPets));
    }
  }

  String _mapError(Object e) {
    if (e is StorageException) {
      final message = e.message.toLowerCase();
      if (message.contains('formato de imagen no soportado')) {
        return 'Formato de imagen no soportado. Usa JPG, PNG, WEBP, GIF o HEIC.';
      }
      if (message.contains('mime type') || message.contains('invalid')) {
        return 'La imagen seleccionada no es compatible con el storage configurado.';
      }
      return 'Error al subir la imagen. ${e.message}';
    }

    final msg = e.toString().toLowerCase();
    if (msg.contains('formato de imagen no soportado')) {
      return 'Formato de imagen no soportado. Usa JPG, PNG, WEBP, GIF o HEIC.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    if (msg.contains('storage') || msg.contains('bucket')) {
      return 'Error al subir la imagen. Intenta de nuevo.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}

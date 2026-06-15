import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class CreatePet {
  CreatePet(this._repository);
  final PetRepository _repository;

  Future<PetEntity> call(PetEntity pet) => _repository.createPet(pet);
}

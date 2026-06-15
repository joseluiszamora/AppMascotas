import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class UpdatePet {
  UpdatePet(this._repository);
  final PetRepository _repository;

  Future<PetEntity> call(PetEntity pet) => _repository.updatePet(pet);
}

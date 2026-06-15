import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class GetMyPets {
  GetMyPets(this._repository);
  final PetRepository _repository;

  Future<List<PetEntity>> call(String ownerId) =>
      _repository.getMyPets(ownerId);
}

import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call(String userId) => _repository.getProfile(userId);
}

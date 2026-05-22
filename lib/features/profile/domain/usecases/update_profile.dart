import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call(ProfileEntity profile) =>
      _repository.updateProfile(profile);
}

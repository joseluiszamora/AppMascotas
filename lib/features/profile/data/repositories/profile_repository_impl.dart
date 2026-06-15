import 'dart:io';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._provider);

  final ProfileProvider _provider;

  @override
  Future<ProfileEntity> getProfile(String userId) =>
      _provider.getProfile(userId);

  @override
  Future<ProfileEntity> updateProfile(
    ProfileEntity profile, {
    File? avatarFile,
    bool removeAvatar = false,
  }) => _provider.updateProfile(
    profile,
    avatarFile: avatarFile,
    removeAvatar: removeAvatar,
  );
}

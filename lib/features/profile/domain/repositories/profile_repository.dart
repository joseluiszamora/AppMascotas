import 'dart:io';

import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile(String userId);
  Future<ProfileEntity> updateProfile(
    ProfileEntity profile, {
    File? avatarFile,
    bool removeAvatar = false,
  });
}

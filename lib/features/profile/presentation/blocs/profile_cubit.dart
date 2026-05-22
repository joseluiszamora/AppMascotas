import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetProfile getProfile,
    required UpdateProfile updateProfile,
  }) : _getProfile = getProfile,
       _updateProfile = updateProfile,
       super(const ProfileInitial());

  final GetProfile _getProfile;
  final UpdateProfile _updateProfile;

  Future<void> loadProfile(String userId) async {
    emit(const ProfileLoading());
    try {
      final profile = await _getProfile(userId);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(_mapError(e)));
    }
  }

  Future<void> updateProfile(ProfileEntity profile) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : profile;
    emit(ProfileUpdating(current));
    try {
      final updated = await _updateProfile(profile);
      emit(ProfileUpdateSuccess(updated));
    } catch (e) {
      emit(ProfileError(_mapError(e)));
    }
  }

  /// Reinicia el estado del perfil al cerrar sesión.
  void resetProfile() => emit(const ProfileInitial());

  String _mapError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'Ocurrió un error al actualizar el perfil. Intenta de nuevo.';
  }
}

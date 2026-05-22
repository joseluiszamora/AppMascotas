import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> updateProfile(
    ProfileEntity profile, {
    File? avatarFile,
    bool removeAvatar = false,
  }) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : profile;
    emit(ProfileUpdating(current));
    try {
      final updated = await _updateProfile(
        profile,
        avatarFile: avatarFile,
        removeAvatar: removeAvatar,
      );
      emit(ProfileUpdateSuccess(updated));
    } catch (e) {
      emit(ProfileError(_mapError(e)));
    }
  }

  /// Reinicia el estado del perfil al cerrar sesión.
  void resetProfile() => emit(const ProfileInitial());

  String _mapError(Object e) {
    if (e is StorageException) {
      final message = e.message.toLowerCase();
      if (message.contains('formato de imagen no soportado')) {
        return 'Formato de imagen no soportado. Usa JPG, PNG, WEBP, GIF o HEIC.';
      }
      if (message.contains('mime type') || message.contains('invalid')) {
        return 'La imagen seleccionada no es compatible con el storage configurado.';
      }
      return 'No pudimos subir la foto de perfil. Intenta de nuevo.';
    }

    if (e is PostgrestException) {
      final message = e.message.toLowerCase();
      if (message.contains('row-level security')) {
        return 'No tienes permisos para actualizar este perfil.';
      }
      if (message.contains('notification_radius_km')) {
        return 'El radio de notificaciones debe estar entre 1 y 200 km.';
      }
      if (e.message.trim().isNotEmpty) {
        return 'No pudimos actualizar el perfil. ${e.message}';
      }
      return 'No pudimos actualizar el perfil. Intenta de nuevo.';
    }

    if (e is AuthException) {
      return 'Tu sesión ya no es válida. Inicia sesión de nuevo e inténtalo otra vez.';
    }

    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'Ocurrió un error al actualizar el perfil. Intenta de nuevo.';
  }
}

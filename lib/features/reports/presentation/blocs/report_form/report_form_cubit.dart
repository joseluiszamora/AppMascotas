import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../pets/domain/entities/pet_entity.dart';
import '../../../../pets/domain/usecases/get_my_pets.dart';
import '../../../domain/entities/report_entity.dart';
import '../../../domain/usecases/create_found_report.dart';
import '../../../domain/usecases/create_lost_report.dart';
import 'report_form_state.dart';

class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit({
    required GetMyPets getMyPets,
    required CreateLostReport createLostReport,
    required CreateFoundReport createFoundReport,
  }) : _getMyPets = getMyPets,
       _createLostReport = createLostReport,
       _createFoundReport = createFoundReport,
       super(const ReportFormState());

  final GetMyPets _getMyPets;
  final CreateLostReport _createLostReport;
  final CreateFoundReport _createFoundReport;

  Future<void> loadPets(String ownerId) async {
    emit(
      state.copyWith(
        isLoadingPets: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearCreatedReport: true,
      ),
    );
    try {
      final pets = await _getMyPets(ownerId);
      emit(
        state.copyWith(
          pets: pets,
          isLoadingPets: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingPets: false,
          errorMessage: _mapError(e),
          clearSuccessMessage: true,
          clearCreatedReport: true,
        ),
      );
    }
  }

  Future<void> submitLostReport({
    required String petId,
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
  }) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearCreatedReport: true,
      ),
    );

    try {
      final report = await _createLostReport(
        petId: petId,
        latitude: latitude,
        longitude: longitude,
        locationDescription: locationDescription,
        occurredAt: occurredAt,
        description: description,
        showContact: showContact,
      );

      final updatedPets = state.pets.map((pet) {
        if (pet.id != petId) return pet;
        return pet.copyWith(status: PetStatus.lost);
      }).toList();

      emit(
        state.copyWith(
          pets: updatedPets,
          isSubmitting: false,
          successMessage: 'Reporte publicado correctamente.',
          createdReport: report,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _mapError(e),
          clearSuccessMessage: true,
          clearCreatedReport: true,
        ),
      );
    }
  }

  Future<void> submitFoundReport({
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
    required ReportPetType foundPetType,
    String? foundPetColor,
    ReportPetSize? foundPetSize,
    String? foundPetDescription,
    required List<File> photos,
  }) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearCreatedReport: true,
      ),
    );

    try {
      final report = await _createFoundReport(
        latitude: latitude,
        longitude: longitude,
        locationDescription: locationDescription,
        occurredAt: occurredAt,
        description: description,
        showContact: showContact,
        foundPetType: foundPetType,
        foundPetColor: foundPetColor,
        foundPetSize: foundPetSize,
        foundPetDescription: foundPetDescription,
        photos: photos,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'Reporte de mascota encontrada publicado.',
          createdReport: report,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _mapError(e),
          clearSuccessMessage: true,
          clearCreatedReport: true,
        ),
      );
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearCreatedReport: true,
      ),
    );
  }

  String _mapError(Object error) {
    if (error is StorageException) {
      final message = error.message.toLowerCase();
      if (message.contains('formato de imagen no soportado')) {
        return 'Formato de imagen no soportado. Usa JPG, PNG, WEBP, GIF o HEIC.';
      }
      return 'No pudimos subir las fotos del reporte. ${error.message}';
    }

    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('no pertenece')) {
        return 'Solo puedes reportar mascotas registradas en tu cuenta.';
      }
      if (message.contains('row-level security')) {
        return 'No tienes permisos para crear este reporte.';
      }
      return 'No pudimos publicar el reporte. ${error.message}';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('socket') || message.contains('network')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'No pudimos publicar el reporte. Intenta de nuevo.';
  }
}

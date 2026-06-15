import 'package:equatable/equatable.dart';

import '../../../../pets/domain/entities/pet_entity.dart';
import '../../../domain/entities/report_entity.dart';

class ReportFormState extends Equatable {
  const ReportFormState({
    this.pets = const [],
    this.isLoadingPets = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.createdReport,
  });

  final List<PetEntity> pets;
  final bool isLoadingPets;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final ReportEntity? createdReport;

  ReportFormState copyWith({
    List<PetEntity>? pets,
    bool? isLoadingPets,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    ReportEntity? createdReport,
    bool clearCreatedReport = false,
  }) {
    return ReportFormState(
      pets: pets ?? this.pets,
      isLoadingPets: isLoadingPets ?? this.isLoadingPets,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
      createdReport: clearCreatedReport
          ? null
          : createdReport ?? this.createdReport,
    );
  }

  @override
  List<Object?> get props => [
    pets,
    isLoadingPets,
    isSubmitting,
    errorMessage,
    successMessage,
    createdReport,
  ];
}

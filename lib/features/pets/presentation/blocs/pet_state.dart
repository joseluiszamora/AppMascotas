import 'package:equatable/equatable.dart';

import '../../domain/entities/pet_entity.dart';

sealed class PetState extends Equatable {
  const PetState();
  @override
  List<Object?> get props => [];
}

class PetInitial extends PetState {
  const PetInitial();
}

class PetLoading extends PetState {
  const PetLoading();
}

/// Lista de mascotas cargada exitosamente.
class PetLoaded extends PetState {
  const PetLoaded(this.pets);
  final List<PetEntity> pets;

  @override
  List<Object?> get props => [pets];
}

/// Operación en curso (crear/actualizar/eliminar).
class PetOperationInProgress extends PetState {
  const PetOperationInProgress(this.pets);
  final List<PetEntity> pets;

  @override
  List<Object?> get props => [pets];
}

/// Operación completada con éxito.
class PetOperationSuccess extends PetState {
  const PetOperationSuccess({required this.pets, required this.message});
  final List<PetEntity> pets;
  final String message;

  @override
  List<Object?> get props => [pets, message];
}

class PetError extends PetState {
  const PetError({required this.message, this.pets = const []});
  final String message;
  final List<PetEntity> pets;

  @override
  List<Object?> get props => [message, pets];
}

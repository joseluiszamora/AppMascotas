import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);

  final ProfileEntity profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating(this.profile);

  final ProfileEntity profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdateSuccess extends ProfileState {
  const ProfileUpdateSuccess(this.profile);

  final ProfileEntity profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

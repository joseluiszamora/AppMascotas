import 'package:equatable/equatable.dart';

enum PetPreference { dogs, cats, both, others }

class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.phoneVisible = false,
    this.avatarUrl,
    this.petPreferences = PetPreference.both,
    this.notificationsEnabled = true,
    this.notificationRadiusKm = 10,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final bool phoneVisible;
  final String? avatarUrl;
  final PetPreference petPreferences;
  final bool notificationsEnabled;
  final int notificationRadiusKm;

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.join(' ');
  }

  bool get isComplete => firstName != null && firstName!.isNotEmpty;

  ProfileEntity copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    bool? phoneVisible,
    String? avatarUrl,
    PetPreference? petPreferences,
    bool? notificationsEnabled,
    int? notificationRadiusKm,
  }) {
    return ProfileEntity(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      phoneVisible: phoneVisible ?? this.phoneVisible,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      petPreferences: petPreferences ?? this.petPreferences,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationRadiusKm: notificationRadiusKm ?? this.notificationRadiusKm,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    phone,
    phoneVisible,
    avatarUrl,
    petPreferences,
    notificationsEnabled,
    notificationRadiusKm,
  ];
}

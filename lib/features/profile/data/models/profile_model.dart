import '../../domain/entities/profile_entity.dart';

class ProfileModel {
  ProfileModel._();

  static ProfileEntity fromJson(Map<String, dynamic> json) {
    return ProfileEntity(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      phoneVisible: (json['phone_visible'] as bool?) ?? false,
      avatarUrl: json['avatar_url'] as String?,
      petPreferences: _parsePetPreference(json['pet_preferences'] as String?),
      notificationsEnabled: (json['notifications_enabled'] as bool?) ?? true,
      notificationRadiusKm: (json['notification_radius_km'] as int?) ?? 10,
    );
  }

  static Map<String, dynamic> toUpdateJson(ProfileEntity profile) {
    return {
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'phone': profile.phone,
      'phone_visible': profile.phoneVisible,
      'avatar_url': profile.avatarUrl,
      'pet_preferences': profile.petPreferences.name,
      'notifications_enabled': profile.notificationsEnabled,
      'notification_radius_km': profile.notificationRadiusKm,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static PetPreference _parsePetPreference(String? value) {
    return switch (value) {
      'dogs' => PetPreference.dogs,
      'cats' => PetPreference.cats,
      'others' => PetPreference.others,
      _ => PetPreference.both,
    };
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.avatarUrl,
  });

  factory UserModel.fromSupabaseUser(User user) {
    return UserModel.fromAuthData(user: user);
  }

  factory UserModel.fromAuthData({
    required User user,
    String? fallbackEmail,
    String? fallbackName,
    String? fallbackAvatarUrl,
  }) {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final fullName = _cleanString(metadata['full_name']);
    final resolvedName =
        fullName ??
        _cleanString(metadata['name']) ??
        _joinNameParts(
          _cleanString(metadata['given_name']),
          _cleanString(metadata['family_name']),
        ) ??
        _cleanString(fallbackName);
    final resolvedAvatarUrl =
        _cleanString(metadata['avatar_url']) ??
        _cleanString(metadata['picture']) ??
        _cleanString(fallbackAvatarUrl);

    return UserModel(
      id: user.id,
      email: _cleanString(user.email) ?? _cleanString(fallbackEmail) ?? '',
      name: resolvedName,
      avatarUrl: resolvedAvatarUrl,
    );
  }

  static String? _cleanString(dynamic value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String? _joinNameParts(String? firstName, String? lastName) {
    final parts = [firstName, lastName].whereType<String>().toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
}

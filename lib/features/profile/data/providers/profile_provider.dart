import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/profile_entity.dart';
import '../models/profile_model.dart';

class ProfileProvider {
  const ProfileProvider({required this.supabase});

  final SupabaseClient supabase;

  Future<ProfileEntity> getProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    final data = await supabase
        .from('profiles')
        .update(ProfileModel.toUpdateJson(profile))
        .eq('id', profile.id)
        .select()
        .single();
    return ProfileModel.fromJson(data);
  }
}

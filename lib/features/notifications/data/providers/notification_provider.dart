import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_notification_entity.dart';
import '../models/app_notification_model.dart';

class NotificationProvider {
  const NotificationProvider({required this.supabase});

  final SupabaseClient supabase;

  Future<List<AppNotificationEntity>> getMyNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    return (data as List<dynamic>)
        .map((row) => AppNotificationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .isFilter('read_at', null);

    return (data as List<dynamic>).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId)
        .isFilter('read_at', null);
  }
}
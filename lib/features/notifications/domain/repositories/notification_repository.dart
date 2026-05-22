import '../entities/app_notification_entity.dart';

abstract class NotificationRepository {
  Future<List<AppNotificationEntity>> getMyNotifications();

  Future<int> getUnreadCount();

  Future<void> markAsRead(String notificationId);
}
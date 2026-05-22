import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../providers/notification_provider.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._provider);

  final NotificationProvider _provider;

  @override
  Future<List<AppNotificationEntity>> getMyNotifications() {
    return _provider.getMyNotifications();
  }

  @override
  Future<int> getUnreadCount() {
    return _provider.getUnreadCount();
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _provider.markAsRead(notificationId);
  }
}
import '../repositories/notification_repository.dart';

class MarkNotificationAsRead {
  MarkNotificationAsRead(this._repository);

  final NotificationRepository _repository;

  Future<void> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}

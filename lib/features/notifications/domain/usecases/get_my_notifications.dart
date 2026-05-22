import '../entities/app_notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetMyNotifications {
  const GetMyNotifications(this._repository);

  final NotificationRepository _repository;

  Future<List<AppNotificationEntity>> call() {
    return _repository.getMyNotifications();
  }
}
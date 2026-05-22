import '../repositories/notification_repository.dart';

class GetUnreadNotificationsCount {
  const GetUnreadNotificationsCount(this._repository);

  final NotificationRepository _repository;

  Future<int> call() {
    return _repository.getUnreadCount();
  }
}
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification_entity.dart';
import '../../domain/usecases/get_my_notifications.dart';
import '../../domain/usecases/mark_notification_as_read.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required GetMyNotifications getMyNotifications,
    required MarkNotificationAsRead markNotificationAsRead,
  }) : _getMyNotifications = getMyNotifications,
       _markNotificationAsRead = markNotificationAsRead,
       super(const NotificationState());

  final GetMyNotifications _getMyNotifications;
  final MarkNotificationAsRead _markNotificationAsRead;

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final notifications = await _getMyNotifications();
      emit(
        state.copyWith(
          notifications: notifications,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _mapError(e),
        ),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _markNotificationAsRead(notificationId);
      final now = DateTime.now();
      final updated = state.notifications.map((notification) {
        if (notification.id != notificationId || notification.isRead) {
          return notification;
        }
        return AppNotificationEntity(
          id: notification.id,
          userId: notification.userId,
          reportId: notification.reportId,
          actorId: notification.actorId,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          readAt: now,
          createdAt: notification.createdAt,
        );
      }).toList();
      emit(state.copyWith(notifications: updated, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: _mapError(e)));
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  String _mapError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socket') || message.contains('network')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'No pudimos cargar tus notificaciones. Intenta de nuevo.';
  }
}
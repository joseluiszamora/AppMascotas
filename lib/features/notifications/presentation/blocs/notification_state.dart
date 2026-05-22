import 'package:equatable/equatable.dart';

import '../../domain/entities/app_notification_entity.dart';

class NotificationState extends Equatable {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<AppNotificationEntity> notifications;
  final bool isLoading;
  final String? errorMessage;

  NotificationState copyWith({
    List<AppNotificationEntity>? notifications,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [notifications, isLoading, errorMessage];
}

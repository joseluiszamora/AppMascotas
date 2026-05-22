import 'package:equatable/equatable.dart';

enum AppNotificationType { nearbyLostReport, nearbyFoundReport }

class AppNotificationEntity extends Equatable {
  const AppNotificationEntity({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.actorId,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String reportId;
  final String actorId;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [
    id,
    userId,
    reportId,
    actorId,
    type,
    title,
    body,
    readAt,
    createdAt,
  ];
}

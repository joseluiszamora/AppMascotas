import '../../domain/entities/app_notification_entity.dart';

class AppNotificationModel {
  static AppNotificationEntity fromJson(Map<String, dynamic> json) {
    return AppNotificationEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reportId: json['report_id'] as String,
      actorId: json['actor_id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static AppNotificationType _parseType(String value) => switch (value) {
    'nearby_found_report' => AppNotificationType.nearbyFoundReport,
    _ => AppNotificationType.nearbyLostReport,
  };
}
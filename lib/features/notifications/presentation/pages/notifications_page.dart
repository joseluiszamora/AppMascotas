import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../blocs/notification_cubit.dart';
import '../blocs/notification_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCubit>().loadNotifications();
    });
  }

  Future<void> _openNotification(AppNotificationEntity notification) async {
    if (!notification.isRead) {
      await context.read<NotificationCubit>().markAsRead(notification.id);
    }
    if (!mounted) return;
    await context.push(AppRoutes.reportDetail(notification.reportId));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationCubit, NotificationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: context.appColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<NotificationCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.notifications.isEmpty
                ? _EmptyNotifications(
                    onRefresh: () =>
                        context.read<NotificationCubit>().loadNotifications(),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        context.read<NotificationCubit>().loadNotifications(),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: state.notifications.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return _NotificationCard(
                          notification: notification,
                          onTap: () => _openNotification(notification),
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLost = notification.type == AppNotificationType.nearbyLostReport;
    final badgeColor = isLost
        ? context.appColors.lostPet
        : context.appColors.foundPet;
    final badgeBg = isLost
        ? context.appColors.pastelPink
        : context.appColors.pastelGreen;
    final dateLabel = DateFormat(
      'd MMM, HH:mm',
      'es',
    ).format(notification.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? context.appColors.surface
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: notification.isRead
                  ? context.appColors.border
                  : badgeColor.withAlpha(90),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isLost ? Icons.search_off_rounded : Icons.favorite_rounded,
                  color: badgeColor,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: context.appColors.textHint,
              ),
              SizedBox(height: 12),
              Text(
                'Sin notificaciones por ahora',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cuando haya nuevos reportes compatibles con tus preferencias aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

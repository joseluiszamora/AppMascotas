import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_report_by_id.dart';
import '../utils/report_actions.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<ReportEntity> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<GetReportById>()(widget.reportId);
  }

  void _retry() {
    setState(() {
      _future = sl<GetReportById>()(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Detalle del reporte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          FutureBuilder<ReportEntity>(
            future: _future,
            builder: (context, snapshot) {
              final report = snapshot.data;
              return IconButton(
                onPressed: report == null
                    ? null
                    : () => shareReport(context, report),
                tooltip: 'Compartir reporte',
                icon: Icon(Icons.share_rounded),
                color: context.appColors.textPrimary,
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<ReportEntity>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _ReportDetailFeedback(
              icon: Icons.wifi_tethering_error_rounded,
              title: 'No pudimos cargar el reporte',
              message: 'Intenta nuevamente para ver la información completa.',
              actionLabel: 'Reintentar',
              onAction: _retry,
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return _ReportDetailFeedback(
              icon: Icons.search_off_rounded,
              title: 'Reporte no disponible',
              message: 'Este reporte ya no está disponible o fue removido.',
              actionLabel: 'Volver',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          final isLost = report.type == ReportType.lost;
          final badgeColor = isLost
              ? context.appColors.lostPet
              : context.appColors.foundPet;
          final badgeBg = isLost
              ? context.appColors.pastelPink
              : context.appColors.pastelGreen;
          final title = reportTitle(report);
          final dateLabel = DateFormat(
            'd MMM y, HH:mm',
            'es',
          ).format(report.occurredAt);

          return SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 240,
                    child: report.primaryPhotoUrl != null
                        ? Image.network(
                            report.primaryPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _ReportDetailHeroPlaceholder(),
                          )
                        : _ReportDetailHeroPlaceholder(),
                  ),
                ),
                SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: isLost ? 'Perdida' : 'Encontrada',
                      bgColor: badgeBg,
                      textColor: badgeColor,
                    ),
                    _Badge(
                      label: reportStatusLabel(report.status),
                      bgColor: context.appColors.surface,
                      textColor: context.appColors.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                if (report.petBreed != null &&
                    report.petBreed!.trim().isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(
                    report.petBreed!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => openReportNavigation(context, report),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: Icon(Icons.navigation_rounded),
                        label: Text(
                          'Navegar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => shareReport(context, report),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.appColors.textPrimary,
                          side: BorderSide(color: context.appColors.border),
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: context.appColors.surface,
                        ),
                        icon: Icon(Icons.share_rounded),
                        label: Text(
                          'Compartir',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación aproximada',
                      value: reportLocationLabel(report),
                    ),
                    _InfoRow(
                      icon: Icons.pin_drop_outlined,
                      label: 'Punto aproximado',
                      value: reportApproximateCoordinatesLabel(report),
                    ),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Fecha',
                      value: dateLabel,
                    ),
                    if (report.effectivePetType != null)
                      _InfoRow(
                        icon: Icons.pets_rounded,
                        label: 'Tipo',
                        value: _petTypeLabel(report.effectivePetType!),
                      ),
                    if (report.effectivePetColor != null &&
                        report.effectivePetColor!.trim().isNotEmpty)
                      _InfoRow(
                        icon: Icons.palette_outlined,
                        label: 'Color',
                        value: report.effectivePetColor!,
                      ),
                    if (report.effectivePetSize != null)
                      _InfoRow(
                        icon: Icons.straighten_rounded,
                        label: 'Tamaño',
                        value: _petSizeLabel(report.effectivePetSize!),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                _InfoCard(
                  title: 'Descripción',
                  children: [
                    Text(
                      reportDescriptionText(report),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportDetailFeedback extends StatelessWidget {
  const _ReportDetailFeedback({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: context.appColors.textHint),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDetailHeroPlaceholder extends StatelessWidget {
  const _ReportDetailHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.pastelYellow,
      alignment: Alignment.center,
      child: Icon(Icons.pets_rounded, size: 54, color: AppColors.primary),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.appColors.textHint),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textSecondary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _petTypeLabel(ReportPetType type) => switch (type) {
  ReportPetType.cat => 'Gato',
  ReportPetType.other => 'Otro',
  ReportPetType.dog => 'Perro',
};

String _petSizeLabel(ReportPetSize size) => switch (size) {
  ReportPetSize.small => 'Pequeño',
  ReportPetSize.medium => 'Mediano',
  ReportPetSize.large => 'Grande',
  ReportPetSize.extraLarge => 'Extra grande',
};

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_report_by_id.dart';

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

  Future<void> _shareReport(ReportEntity report) async {
    try {
      final title = report.type == ReportType.lost
          ? (report.petName ?? 'Mascota perdida')
          : _foundTitle(report);
      final dateLabel = DateFormat('d MMM y, HH:mm', 'es').format(report.occurredAt);
      final location = report.locationDescription ?? 'Ubicación aproximada registrada';
      final description = _descriptionText(report);
      final shareText = StringBuffer()
        ..writeln('Reporte de ${AppConstants.appName}')
        ..writeln()
        ..writeln(title)
        ..writeln('Tipo: ${report.type == ReportType.lost ? 'Mascota perdida' : 'Mascota encontrada'}')
        ..writeln('Estado: ${_statusLabel(report.status)}')
        ..writeln('Ubicación aproximada: $location')
        ..writeln('Fecha: $dateLabel')
        ..writeln()
        ..writeln(description)
        ..writeln()
        ..writeln('ID del reporte: ${report.id}');

      await Share.share(
        shareText.toString(),
        subject: title,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir las opciones para compartir.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Detalle del reporte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          FutureBuilder<ReportEntity>(
            future: _future,
            builder: (context, snapshot) {
              final report = snapshot.data;
              return IconButton(
                onPressed: report == null ? null : () => _shareReport(report),
                tooltip: 'Compartir reporte',
                icon: const Icon(Icons.share_rounded),
                color: AppColors.textPrimary,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<ReportEntity>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
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
          final badgeColor = isLost ? AppColors.lostPet : AppColors.foundPet;
          final badgeBg = isLost ? AppColors.pastelPink : AppColors.pastelGreen;
          final title = isLost
              ? (report.petName ?? 'Mascota perdida')
              : _foundTitle(report);
          final dateLabel = DateFormat('d MMM y, HH:mm', 'es').format(report.occurredAt);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                                const _ReportDetailHeroPlaceholder(),
                          )
                        : const _ReportDetailHeroPlaceholder(),
                  ),
                ),
                const SizedBox(height: 18),
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
                      label: _statusLabel(report.status),
                      bgColor: AppColors.surface,
                      textColor: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                if (report.petBreed != null && report.petBreed!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    report.petBreed!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _shareReport(report),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: AppColors.surface,
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text(
                    'Compartir reporte',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 20),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación',
                      value: report.locationDescription ?? 'Ubicación aproximada registrada',
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
                    if (report.effectivePetColor != null && report.effectivePetColor!.trim().isNotEmpty)
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
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Descripción',
                  children: [
                    Text(
                      _descriptionText(report),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textPrimary,
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
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
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
      color: AppColors.pastelYellow,
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        size: 54,
        color: AppColors.primary,
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
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

String _statusLabel(ReportStatus status) => switch (status) {
  ReportStatus.underReview => 'En revisión',
  ReportStatus.resolved => 'Resuelto',
  ReportStatus.closed => 'Cerrado',
  ReportStatus.reported => 'Reportado',
  ReportStatus.active => 'Activo',
};

String _descriptionText(ReportEntity report) {
  final primary = report.description?.trim();
  if (primary != null && primary.isNotEmpty) {
    return primary;
  }

  final fallback = report.foundPetDescription?.trim();
  if (fallback != null && fallback.isNotEmpty) {
    return fallback;
  }

  return 'Sin descripción adicional por ahora.';
}

String _foundTitle(ReportEntity report) {
  final typeLabel = switch (report.foundPetType) {
    ReportPetType.cat => 'Gato encontrado',
    ReportPetType.other => 'Mascota encontrada',
    _ => 'Perro encontrado',
  };

  if (report.foundPetColor != null && report.foundPetColor!.trim().isNotEmpty) {
    return '$typeLabel · ${report.foundPetColor!}';
  }

  return typeLabel;
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';

String reportTitle(ReportEntity report) {
  if (report.type == ReportType.lost) {
    return report.petName ?? 'Mascota perdida';
  }

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

String reportTypeLabel(ReportEntity report) {
  return report.type == ReportType.lost ? 'Mascota perdida' : 'Mascota encontrada';
}

String reportStatusLabel(ReportStatus status) => switch (status) {
  ReportStatus.underReview => 'En revisión',
  ReportStatus.resolved => 'Resuelto',
  ReportStatus.closed => 'Cerrado',
  ReportStatus.reported => 'Reportado',
  ReportStatus.active => 'Activo',
};

String reportDescriptionText(ReportEntity report) {
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

String reportLocationLabel(ReportEntity report) {
  final location = report.locationDescription?.trim();
  if (location != null && location.isNotEmpty) {
    return location;
  }
  return 'Ubicación aproximada registrada';
}

String reportApproximateCoordinatesLabel(ReportEntity report) {
  return '${report.approximateLatitude.toStringAsFixed(3)}, ${report.approximateLongitude.toStringAsFixed(3)}';
}

Future<void> shareReport(BuildContext context, ReportEntity report) async {
  try {
    final title = reportTitle(report);
    final dateLabel = DateFormat('d MMM y, HH:mm', 'es').format(report.occurredAt);
    final shareText = StringBuffer()
      ..writeln('Reporte de ${AppConstants.appName}')
      ..writeln()
      ..writeln(title)
      ..writeln('Tipo: ${reportTypeLabel(report)}')
      ..writeln('Estado: ${reportStatusLabel(report.status)}')
      ..writeln('Ubicación aproximada: ${reportLocationLabel(report)}')
      ..writeln('Coordenadas aproximadas: ${reportApproximateCoordinatesLabel(report)}')
      ..writeln('Fecha: $dateLabel')
      ..writeln()
      ..writeln(reportDescriptionText(report))
      ..writeln()
      ..writeln('ID del reporte: ${report.id}');

    await Share.share(
      shareText.toString(),
      subject: title,
    );
  } catch (_) {
    if (!context.mounted) return;
    _showReportMessage(
      context,
      'No pudimos abrir las opciones para compartir.',
    );
  }
}

Future<void> openReportNavigation(BuildContext context, ReportEntity report) async {
  final uri = Uri.https(
    'www.google.com',
    '/maps/search/',
    {
      'api': '1',
      'query': '${report.approximateLatitude},${report.approximateLongitude}',
    },
  );

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showReportMessage(
        context,
        'No pudimos abrir la app de mapas.',
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    _showReportMessage(
      context,
      'No pudimos abrir la app de mapas.',
    );
  }
}

void _showReportMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';
import '../utils/report_actions.dart';

enum ReportListSortOrder { newest, oldest, proximity }

class ReportListBadgeData {
  ReportListBadgeData({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;
}

class ReportListFiltersResult {
  ReportListFiltersResult({
    required this.includeLost,
    required this.includeFound,
    required this.petType,
    required this.status,
    required this.query,
    this.sortOrder,
  });

  final bool includeLost;
  final bool includeFound;
  final ReportPetType? petType;
  final ReportStatus? status;
  final String query;
  final ReportListSortOrder? sortOrder;
}

class ReportListFiltersSheet extends StatefulWidget {
  const ReportListFiltersSheet({
    super.key,
    required this.title,
    required this.includeLost,
    required this.includeFound,
    required this.petType,
    required this.status,
    required this.query,
    this.sortOrder,
    this.showSortField = false,
  });

  final String title;
  final bool includeLost;
  final bool includeFound;
  final ReportPetType? petType;
  final ReportStatus? status;
  final String query;
  final ReportListSortOrder? sortOrder;
  final bool showSortField;

  @override
  State<ReportListFiltersSheet> createState() => _ReportListFiltersSheetState();
}

class _ReportListFiltersSheetState extends State<ReportListFiltersSheet> {
  late bool _includeLost = widget.includeLost;
  late bool _includeFound = widget.includeFound;
  late ReportPetType? _petType = widget.petType;
  late ReportStatus? _status = widget.status;
  late ReportListSortOrder _sortOrder =
      widget.sortOrder ?? ReportListSortOrder.newest;
  late final TextEditingController _queryCtrl = TextEditingController(
    text: widget.query,
  );

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text('Perdidas'),
                        selected: _includeLost,
                        onSelected: (value) =>
                            setState(() => _includeLost = value),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: Text('Encontradas'),
                        selected: _includeFound,
                        onSelected: (value) =>
                            setState(() => _includeFound = value),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ReportListLabeledField(
                  label: 'Buscar',
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: reportListSheetInput(
                      context,
                      'Nombre, ubicación, color...',
                    ),
                  ),
                ),
                if (widget.showSortField) ...[
                  SizedBox(height: 12),
                  ReportListLabeledField(
                    label: 'Ordenar por',
                    child: DropdownButtonFormField<ReportListSortOrder>(
                      initialValue: _sortOrder,
                      items: [
                        DropdownMenuItem(
                          value: ReportListSortOrder.newest,
                          child: Text('Fecha más reciente'),
                        ),
                        DropdownMenuItem(
                          value: ReportListSortOrder.oldest,
                          child: Text('Fecha más antigua'),
                        ),
                        DropdownMenuItem(
                          value: ReportListSortOrder.proximity,
                          child: Text('Proximidad'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _sortOrder = value);
                      },
                      decoration: reportListSheetInput(context, 'Selecciona'),
                    ),
                  ),
                ],
                SizedBox(height: 12),
                ReportListLabeledField(
                  label: 'Tipo de mascota',
                  child: DropdownButtonFormField<ReportPetType?>(
                    initialValue: _petType,
                    items: [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(
                        value: ReportPetType.dog,
                        child: Text('Perro'),
                      ),
                      DropdownMenuItem(
                        value: ReportPetType.cat,
                        child: Text('Gato'),
                      ),
                      DropdownMenuItem(
                        value: ReportPetType.other,
                        child: Text('Otro'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _petType = value),
                    decoration: reportListSheetInput(context, 'Selecciona'),
                  ),
                ),
                SizedBox(height: 12),
                ReportListLabeledField(
                  label: 'Estado',
                  child: DropdownButtonFormField<ReportStatus?>(
                    initialValue: _status,
                    items: [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(
                        value: ReportStatus.active,
                        child: Text('Activo'),
                      ),
                      DropdownMenuItem(
                        value: ReportStatus.underReview,
                        child: Text('En revisión'),
                      ),
                      DropdownMenuItem(
                        value: ReportStatus.resolved,
                        child: Text('Resuelto'),
                      ),
                      DropdownMenuItem(
                        value: ReportStatus.closed,
                        child: Text('Cerrado'),
                      ),
                      DropdownMenuItem(
                        value: ReportStatus.reported,
                        child: Text('Reportado'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                    decoration: reportListSheetInput(context, 'Selecciona'),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _includeLost = true;
                            _includeFound = true;
                            _petType = null;
                            _status = null;
                            _sortOrder = ReportListSortOrder.newest;
                            _queryCtrl.clear();
                          });
                        },
                        child: Text('Limpiar'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            ReportListFiltersResult(
                              includeLost: _includeLost,
                              includeFound: _includeFound,
                              petType: _petType,
                              status: _status,
                              query: _queryCtrl.text.trim(),
                              sortOrder: widget.showSortField
                                  ? _sortOrder
                                  : null,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportListFeedbackState extends StatelessWidget {
  const ReportListFeedbackState({
    super.key,
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

class ReportListCard extends StatelessWidget {
  const ReportListCard({
    super.key,
    required this.report,
    this.isMine = false,
    this.extraBadges = const [],
    this.secondaryInfo,
    this.secondaryInfoIcon = Icons.near_me_rounded,
  });

  final ReportEntity report;
  final bool isMine;
  final List<ReportListBadgeData> extraBadges;
  final String? secondaryInfo;
  final IconData secondaryInfoIcon;

  @override
  Widget build(BuildContext context) {
    final dateLabel = reportRelativeTimeLabel(report.occurredAt);
    final freshness = reportFreshnessData(context, report);
    final detailLine = reportListDetailLine(report);
    final needsConfirmation = reportNeedsOwnerConfirmation(report);
    final statusColors = reportListStatusColors(context, report.status);
    return InkWell(
      onTap: () => context.push(AppRoutes.reportDetail(report.id)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appColors.border),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 84,
                height: 84,
                child: report.primaryPhotoUrl != null
                    ? Image.network(
                        report.primaryPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ReportListPlaceholder(type: report.type),
                      )
                    : ReportListPlaceholder(type: report.type),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ReportListBadge(
                        label: freshness.label,
                        color: freshness.foreground,
                        background: freshness.background,
                      ),
                      ReportListBadge(
                        label: reportStatusLabel(report.status),
                        color: statusColors.foreground,
                        background: statusColors.background,
                      ),
                      ...extraBadges.map(
                        (badge) => ReportListBadge(
                          label: badge.label,
                          color: badge.color,
                          background: badge.background,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    reportTitle(report),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    detailLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    reportLocationLabel(report),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        secondaryInfo != null
                            ? secondaryInfoIcon
                            : Icons.schedule_rounded,
                        size: 14,
                        color: context.appColors.textHint,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          secondaryInfo == null
                              ? dateLabel
                              : '$secondaryInfo · $dateLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.appColors.textHint,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ReportCardActionButton(
                        label: 'La vi',
                        icon: Icons.visibility_rounded,
                        onTap: () =>
                            context.push(AppRoutes.reportDetail(report.id)),
                      ),
                      _ReportCardActionButton(
                        label: 'Compartir',
                        icon: Icons.ios_share_rounded,
                        onTap: () => shareReport(context, report),
                      ),
                    ],
                  ),
                  if (isMine && needsConfirmation) ...[
                    SizedBox(height: 10),
                    _OwnerConfirmationPrompt(report: report),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCardActionButton extends StatelessWidget {
  const _ReportCardActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: context.appColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.appColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: context.appColors.primary),
              SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerConfirmationPrompt extends StatelessWidget {
  const _OwnerConfirmationPrompt({required this.report});

  final ReportEntity report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.pastelYellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿${reportTitle(report)} sigue perdida?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _ReportCardActionButton(
              label: 'Sí, mantener activo',
              icon: Icons.check_circle_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gracias. Pronto guardaremos esta confirmación en tu aviso.',
                    ),
                    backgroundColor: context.appColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReportListPlaceholder extends StatelessWidget {
  const ReportListPlaceholder({super.key, required this.type});

  final ReportType type;

  @override
  Widget build(BuildContext context) {
    final bg = type == ReportType.lost
        ? context.appColors.pastelPink
        : context.appColors.pastelGreen;
    final fg = type == ReportType.lost
        ? context.appColors.lostPet
        : context.appColors.foundPet;

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Icon(
        type == ReportType.lost
            ? Icons.search_off_rounded
            : Icons.favorite_rounded,
        color: fg,
        size: 34,
      ),
    );
  }
}

class ReportListBadge extends StatelessWidget {
  const ReportListBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class ReportListSummaryChip extends StatelessWidget {
  const ReportListSummaryChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.appColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

class ReportListLabeledField extends StatelessWidget {
  const ReportListLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        child,
      ],
    );
  }
}

InputDecoration reportListSheetInput(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: context.appColors.surface,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.appColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.appColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

String reportListPetTypeLabel(ReportPetType type) => switch (type) {
  ReportPetType.cat => 'Gato',
  ReportPetType.other => 'Otro',
  ReportPetType.dog => 'Perro',
};

String reportListPetSizeLabel(ReportPetSize size) => switch (size) {
  ReportPetSize.small => 'Pequeño',
  ReportPetSize.medium => 'Mediano',
  ReportPetSize.large => 'Grande',
  ReportPetSize.extraLarge => 'Muy grande',
};

String reportListDetailLine(ReportEntity report) {
  final parts = <String>[
    report.type == ReportType.lost ? 'Perdida' : 'Encontrada',
  ];

  final petType = report.effectivePetType;
  if (petType != null) {
    parts.add(reportListPetTypeLabel(petType));
  }

  final color = report.effectivePetColor?.trim();
  if (color != null && color.isNotEmpty) {
    parts.add(color);
  }

  final size = report.effectivePetSize;
  if (size != null) {
    parts.add(reportListPetSizeLabel(size));
  }

  return parts.join(' · ');
}

String reportListSortLabel(ReportListSortOrder sortOrder) =>
    switch (sortOrder) {
      ReportListSortOrder.newest => 'Fecha reciente',
      ReportListSortOrder.oldest => 'Fecha antigua',
      ReportListSortOrder.proximity => 'Proximidad',
    };

StatusPalette reportListStatusColors(
  BuildContext context,
  ReportStatus status,
) => switch (status) {
  ReportStatus.active => StatusPalette(
    foreground: AppColors.primary,
    background: context.appColors.pastelBlue,
  ),
  ReportStatus.underReview => StatusPalette(
    foreground: context.appColors.warning,
    background: context.appColors.pastelYellow,
  ),
  ReportStatus.resolved => StatusPalette(
    foreground: context.appColors.foundPet,
    background: context.appColors.pastelGreen,
  ),
  ReportStatus.closed => StatusPalette(
    foreground: context.appColors.textSecondary,
    background: context.appColors.border,
  ),
  ReportStatus.reported => StatusPalette(
    foreground: context.appColors.error,
    background: context.appColors.pastelPink,
  ),
};

class StatusPalette {
  StatusPalette({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

class ReportFreshnessData {
  ReportFreshnessData({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

ReportFreshnessData reportFreshnessData(
  BuildContext context,
  ReportEntity report, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final createdAge = currentTime.difference(report.createdAt);
  final updatedAge = currentTime.difference(report.updatedAt);

  if (createdAge.inHours < 24) {
    return ReportFreshnessData(
      label: 'Nuevo',
      foreground: AppColors.primary,
      background: context.appColors.pastelBlue,
    );
  }

  if (_isSameDay(report.updatedAt, currentTime)) {
    return ReportFreshnessData(
      label: 'Actualizado hoy',
      foreground: context.appColors.foundPet,
      background: context.appColors.pastelGreen,
    );
  }

  if (updatedAge.inDays < 2) {
    return ReportFreshnessData(
      label: reportRelativeTimeLabel(report.updatedAt, now: currentTime),
      foreground: context.appColors.warning,
      background: context.appColors.pastelYellow,
    );
  }

  return ReportFreshnessData(
    label:
        'Sin actualizar ${reportRelativeTimeLabel(report.updatedAt, now: currentTime).toLowerCase()}',
    foreground: context.appColors.textSecondary,
    background: context.appColors.border,
  );
}

bool reportNeedsOwnerConfirmation(ReportEntity report, {DateTime? now}) {
  if (report.type != ReportType.lost) return false;
  if (report.status != ReportStatus.active &&
      report.status != ReportStatus.underReview) {
    return false;
  }

  final currentTime = now ?? DateTime.now();
  return currentTime.difference(report.updatedAt).inDays >= 14;
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String reportRelativeTimeLabel(DateTime dateTime, {DateTime? now}) {
  final currentTime = now ?? DateTime.now();
  final difference = currentTime.difference(dateTime);

  if (difference.inSeconds < 0) {
    return 'Hace un momento';
  }

  if (difference.inMinutes < 1) {
    return 'Hace un momento';
  }

  if (difference.inHours < 1) {
    final minutes = difference.inMinutes;
    return minutes == 1 ? 'Hace 1 minuto' : 'Hace $minutes minutos';
  }

  if (difference.inDays < 1) {
    final hours = difference.inHours;
    return hours == 1 ? 'Hace 1 hora' : 'Hace $hours horas';
  }

  if (difference.inDays < 7) {
    final days = difference.inDays;
    return days == 1 ? 'Hace 1 día' : 'Hace $days días';
  }

  if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return weeks == 1 ? 'Hace 1 semana' : 'Hace $weeks semanas';
  }

  if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return months <= 1 ? 'Hace 1 mes' : 'Hace $months meses';
  }

  final years = (difference.inDays / 365).floor();
  return years == 1 ? 'Hace 1 año' : 'Hace $years años';
}

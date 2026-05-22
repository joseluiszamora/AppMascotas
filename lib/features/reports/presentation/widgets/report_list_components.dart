import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';
import '../utils/report_actions.dart';

enum ReportListSortOrder { newest, oldest, proximity }

class ReportListBadgeData {
  const ReportListBadgeData({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;
}

class ReportListFiltersResult {
  const ReportListFiltersResult({
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
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('Perdidas'),
                        selected: _includeLost,
                        onSelected: (value) =>
                            setState(() => _includeLost = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Encontradas'),
                        selected: _includeFound,
                        onSelected: (value) =>
                            setState(() => _includeFound = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ReportListLabeledField(
                  label: 'Buscar',
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: reportListSheetInput(
                      'Nombre, ubicación, color...',
                    ),
                  ),
                ),
                if (widget.showSortField) ...[
                  const SizedBox(height: 12),
                  ReportListLabeledField(
                    label: 'Ordenar por',
                    child: DropdownButtonFormField<ReportListSortOrder>(
                      initialValue: _sortOrder,
                      items: const [
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
                      decoration: reportListSheetInput('Selecciona'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ReportListLabeledField(
                  label: 'Tipo de mascota',
                  child: DropdownButtonFormField<ReportPetType?>(
                    initialValue: _petType,
                    items: const [
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
                    decoration: reportListSheetInput('Selecciona'),
                  ),
                ),
                const SizedBox(height: 12),
                ReportListLabeledField(
                  label: 'Estado',
                  child: DropdownButtonFormField<ReportStatus?>(
                    initialValue: _status,
                    items: const [
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
                    decoration: reportListSheetInput('Selecciona'),
                  ),
                ),
                const SizedBox(height: 20),
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
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        child: const Text('Aplicar'),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
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

class ReportListCard extends StatelessWidget {
  const ReportListCard({
    super.key,
    required this.report,
    this.extraBadges = const [],
    this.secondaryInfo,
    this.secondaryInfoIcon = Icons.near_me_rounded,
  });

  final ReportEntity report;
  final List<ReportListBadgeData> extraBadges;
  final String? secondaryInfo;
  final IconData secondaryInfoIcon;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      'd MMM y, HH:mm',
      'es',
    ).format(report.occurredAt);
    final typeColor = report.type == ReportType.lost
        ? AppColors.lostPet
        : AppColors.foundPet;
    final typeBg = report.type == ReportType.lost
        ? AppColors.pastelPink
        : AppColors.pastelGreen;
    final statusColors = reportListStatusColors(report.status);

    return InkWell(
      onTap: () => context.push(AppRoutes.reportDetail(report.id)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 14,
              offset: const Offset(0, 4),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ReportListBadge(
                        label: report.type == ReportType.lost
                            ? 'Perdida'
                            : 'Encontrada',
                        color: typeColor,
                        background: typeBg,
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
                  const SizedBox(height: 10),
                  Text(
                    reportTitle(report),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (report.petBreed?.trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        report.petBreed!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    reportLocationLabel(report),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  if (secondaryInfo != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          secondaryInfoIcon,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            secondaryInfo!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        ? AppColors.pastelPink
        : AppColors.pastelGreen;
    final fg = type == ReportType.lost ? AppColors.lostPet : AppColors.foundPet;

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

InputDecoration reportListSheetInput(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

String reportListPetTypeLabel(ReportPetType type) => switch (type) {
  ReportPetType.cat => 'Gato',
  ReportPetType.other => 'Otro',
  ReportPetType.dog => 'Perro',
};

String reportListSortLabel(ReportListSortOrder sortOrder) =>
    switch (sortOrder) {
      ReportListSortOrder.newest => 'Fecha reciente',
      ReportListSortOrder.oldest => 'Fecha antigua',
      ReportListSortOrder.proximity => 'Proximidad',
    };

StatusPalette reportListStatusColors(ReportStatus status) => switch (status) {
  ReportStatus.active => const StatusPalette(
    foreground: AppColors.primary,
    background: AppColors.pastelBlue,
  ),
  ReportStatus.underReview => const StatusPalette(
    foreground: AppColors.warning,
    background: AppColors.pastelYellow,
  ),
  ReportStatus.resolved => const StatusPalette(
    foreground: AppColors.foundPet,
    background: AppColors.pastelGreen,
  ),
  ReportStatus.closed => const StatusPalette(
    foreground: AppColors.textSecondary,
    background: AppColors.border,
  ),
  ReportStatus.reported => const StatusPalette(
    foreground: AppColors.error,
    background: AppColors.pastelPink,
  ),
};

class StatusPalette {
  const StatusPalette({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

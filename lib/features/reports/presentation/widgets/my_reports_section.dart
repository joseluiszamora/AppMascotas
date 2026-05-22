import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_my_reports.dart';
import '../utils/report_actions.dart';

class MyReportsSection extends StatefulWidget {
  const MyReportsSection({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<MyReportsSection> createState() => _MyReportsSectionState();
}

class _MyReportsSectionState extends State<MyReportsSection> {
  late Future<List<ReportEntity>> _future;

  bool _includeLost = true;
  bool _includeFound = true;
  ReportPetType? _petType;
  ReportStatus? _status;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _loadReports();
  }

  @override
  void didUpdateWidget(covariant MyReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _reload();
    }
  }

  Future<List<ReportEntity>> _loadReports() {
    return sl<GetMyReports>()();
  }

  void _reload() {
    setState(() {
      _future = _loadReports();
    });
  }

  int _activeFilterCount() {
    var total = 0;
    if (!(_includeLost && _includeFound)) total++;
    if (_petType != null) total++;
    if (_status != null) total++;
    if (_query.trim().isNotEmpty) total++;
    return total;
  }

  List<ReportEntity> _applyFilters(List<ReportEntity> reports) {
    final query = _query.trim().toLowerCase();

    return reports.where((report) {
      if (!_includeLost && report.type == ReportType.lost) {
        return false;
      }

      if (!_includeFound && report.type == ReportType.found) {
        return false;
      }

      if (_petType != null && report.effectivePetType != _petType) {
        return false;
      }

      if (_status != null && report.status != _status) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        reportTitle(report),
        reportLocationLabel(report),
        report.petBreed,
        report.effectivePetColor,
        report.description,
        report.foundPetDescription,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_MyReportsFiltersResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MyReportsFiltersSheet(
        includeLost: _includeLost,
        includeFound: _includeFound,
        petType: _petType,
        status: _status,
        query: _query,
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _includeLost = result.includeLost;
      _includeFound = result.includeFound;
      _petType = result.petType;
      _status = result.status;
      _query = result.query;
    });
  }

  void _resetFilters() {
    setState(() {
      _includeLost = true;
      _includeFound = true;
      _petType = null;
      _status = null;
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus reportes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta el historial de reportes publicados por tu cuenta.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeFilterCount() > 0)
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Limpiar'),
                ),
              IconButton.filledTonal(
                onPressed: _openFilters,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterSummaryChip(
                label: _includeLost && _includeFound
                    ? 'Perdidas y encontradas'
                    : _includeLost
                    ? 'Solo perdidas'
                    : _includeFound
                    ? 'Solo encontradas'
                    : 'Sin tipos',
              ),
              if (_petType != null)
                _FilterSummaryChip(label: _petTypeLabel(_petType!)),
              if (_status != null)
                _FilterSummaryChip(label: reportStatusLabel(_status!)),
              _FilterSummaryChip(
                label: _activeFilterCount() == 0
                    ? 'Sin filtros extra'
                    : '${_activeFilterCount()} filtros',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<ReportEntity>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return _MyReportsFeedbackState(
                  icon: Icons.wifi_off_rounded,
                  title: 'No pudimos cargar tus reportes',
                  message: 'Intenta de nuevo para actualizar tu historial.',
                  actionLabel: 'Reintentar',
                  onAction: _reload,
                );
              }

              final reports = snapshot.data ?? const <ReportEntity>[];
              if (reports.isEmpty) {
                return _MyReportsFeedbackState(
                  icon: Icons.assignment_outlined,
                  title: 'Aún no has publicado reportes',
                  message:
                      'Cuando crees reportes perdidos o encontrados aparecerán aquí.',
                  actionLabel: 'Actualizar',
                  onAction: _reload,
                );
              }

              final filteredReports = _applyFilters(reports);
              if (filteredReports.isEmpty) {
                return _MyReportsFeedbackState(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'Sin coincidencias con estos filtros',
                  message:
                      'Prueba con otro estado, tipo de mascota o cambia la búsqueda.',
                  actionLabel: 'Limpiar filtros',
                  onAction: _resetFilters,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: filteredReports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _MyReportCard(report: filteredReports[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({required this.report});

  final ReportEntity report;

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
    final statusColors = _statusColors(report.status);

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
                            _ReportPlaceholder(type: report.type),
                      )
                    : _ReportPlaceholder(type: report.type),
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
                      _Badge(
                        label: report.type == ReportType.lost
                            ? 'Perdida'
                            : 'Encontrada',
                        color: typeColor,
                        background: typeBg,
                      ),
                      _Badge(
                        label: reportStatusLabel(report.status),
                        color: statusColors.foreground,
                        background: statusColors.background,
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

class _MyReportsFiltersResult {
  const _MyReportsFiltersResult({
    required this.includeLost,
    required this.includeFound,
    required this.petType,
    required this.status,
    required this.query,
  });

  final bool includeLost;
  final bool includeFound;
  final ReportPetType? petType;
  final ReportStatus? status;
  final String query;
}

class _MyReportsFiltersSheet extends StatefulWidget {
  const _MyReportsFiltersSheet({
    required this.includeLost,
    required this.includeFound,
    required this.petType,
    required this.status,
    required this.query,
  });

  final bool includeLost;
  final bool includeFound;
  final ReportPetType? petType;
  final ReportStatus? status;
  final String query;

  @override
  State<_MyReportsFiltersSheet> createState() => _MyReportsFiltersSheetState();
}

class _MyReportsFiltersSheetState extends State<_MyReportsFiltersSheet> {
  late bool _includeLost = widget.includeLost;
  late bool _includeFound = widget.includeFound;
  late ReportPetType? _petType = widget.petType;
  late ReportStatus? _status = widget.status;
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
                const Text(
                  'Filtros de tus reportes',
                  style: TextStyle(
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
                _LabeledField(
                  label: 'Buscar',
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: _sheetInput('Nombre, ubicación, color...'),
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
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
                    decoration: _sheetInput('Selecciona'),
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
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
                    decoration: _sheetInput('Selecciona'),
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
                            _MyReportsFiltersResult(
                              includeLost: _includeLost,
                              includeFound: _includeFound,
                              petType: _petType,
                              status: _status,
                              query: _queryCtrl.text.trim(),
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

class _MyReportsFeedbackState extends StatelessWidget {
  const _MyReportsFeedbackState({
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

class _ReportPlaceholder extends StatelessWidget {
  const _ReportPlaceholder({required this.type});

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

class _Badge extends StatelessWidget {
  const _Badge({
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

class _FilterSummaryChip extends StatelessWidget {
  const _FilterSummaryChip({required this.label});

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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

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

InputDecoration _sheetInput(String hint) {
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

String _petTypeLabel(ReportPetType type) => switch (type) {
  ReportPetType.cat => 'Gato',
  ReportPetType.other => 'Otro',
  ReportPetType.dog => 'Perro',
};

_StatusPalette _statusColors(ReportStatus status) => switch (status) {
  ReportStatus.active => const _StatusPalette(
    foreground: AppColors.primary,
    background: AppColors.pastelBlue,
  ),
  ReportStatus.underReview => const _StatusPalette(
    foreground: AppColors.warning,
    background: AppColors.pastelYellow,
  ),
  ReportStatus.resolved => const _StatusPalette(
    foreground: AppColors.foundPet,
    background: AppColors.pastelGreen,
  ),
  ReportStatus.closed => const _StatusPalette(
    foreground: AppColors.textSecondary,
    background: AppColors.border,
  ),
  ReportStatus.reported => const _StatusPalette(
    foreground: AppColors.error,
    background: AppColors.pastelPink,
  ),
};

class _StatusPalette {
  const _StatusPalette({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

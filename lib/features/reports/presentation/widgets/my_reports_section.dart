import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_my_reports.dart';
import 'report_list_components.dart';
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
    _future = _isAuthenticated()
        ? _loadReports()
        : Future.value(<ReportEntity>[]);
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

  bool _isAuthenticated() {
    return sl<SupabaseClient>().auth.currentUser != null;
  }

  void _reload() {
    if (!_isAuthenticated()) {
      setState(() {
        _future = Future.value(<ReportEntity>[]);
      });
      return;
    }

    setState(() {
      _future = _loadReports();
    });
  }

  void _openLogin() {
    context.push(AppRoutes.loginWithRedirect(AppRoutes.home));
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
    final result = await showModalBottomSheet<ReportListFiltersResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportListFiltersSheet(
        title: 'Filtros de tus reportes',
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
    if (!_isAuthenticated()) {
      return ReportListFeedbackState(
        icon: Icons.lock_outline_rounded,
        title: 'Inicia sesión para ver tus reportes',
        message:
            'Tu historial personal se carga cuando entras con tu cuenta de Google.',
        actionLabel: 'Iniciar sesión',
        onAction: _openLogin,
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus reportes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta el historial de reportes publicados por tu cuenta.',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeFilterCount() > 0)
                TextButton(onPressed: _resetFilters, child: Text('Limpiar')),
              IconButton.filledTonal(
                onPressed: _openFilters,
                style: IconButton.styleFrom(
                  backgroundColor: context.appColors.surface,
                  foregroundColor: context.appColors.textPrimary,
                ),
                icon: Icon(Icons.tune_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ReportListSummaryChip(label: 'Solo tuyos'),
              ReportListSummaryChip(
                label: _includeLost && _includeFound
                    ? 'Perdidas y encontradas'
                    : _includeLost
                    ? 'Solo perdidas'
                    : _includeFound
                    ? 'Solo encontradas'
                    : 'Sin tipos',
              ),
              if (_petType != null)
                ReportListSummaryChip(label: reportListPetTypeLabel(_petType!)),
              if (_status != null)
                ReportListSummaryChip(label: reportStatusLabel(_status!)),
              ReportListSummaryChip(
                label: _activeFilterCount() == 0
                    ? 'Sin filtros extra'
                    : '${_activeFilterCount()} filtros',
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<ReportEntity>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return ReportListFeedbackState(
                  icon: Icons.wifi_off_rounded,
                  title: 'No pudimos cargar tus reportes',
                  message: 'Intenta de nuevo para actualizar tu historial.',
                  actionLabel: 'Reintentar',
                  onAction: _reload,
                );
              }

              final reports = snapshot.data ?? <ReportEntity>[];
              if (reports.isEmpty) {
                return ReportListFeedbackState(
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
                return ReportListFeedbackState(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'Sin coincidencias con estos filtros',
                  message:
                      'Prueba con otro estado, tipo de mascota o cambia la búsqueda.',
                  actionLabel: 'Limpiar filtros',
                  onAction: _resetFilters,
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: filteredReports.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) => ReportListCard(
                  report: filteredReports[index],
                  extraBadges: [
                    ReportListBadgeData(
                      label: 'Tuyo',
                      color: AppColors.primary,
                      background: context.appColors.pastelBlue,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

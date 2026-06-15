import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_all_reports.dart';
import 'report_list_components.dart';
import '../utils/report_actions.dart';

class AllReportsSection extends StatefulWidget {
  const AllReportsSection({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<AllReportsSection> createState() => _AllReportsSectionState();
}

class _AllReportsSectionState extends State<AllReportsSection> {
  late Future<List<ReportEntity>> _future;

  bool _includeLost = true;
  bool _includeFound = true;
  ReportPetType? _petType;
  ReportStatus? _status;
  ReportListSortOrder _sortOrder = ReportListSortOrder.newest;
  String _query = '';
  double? _userLatitude;
  double? _userLongitude;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _future = _loadReports();
    _currentUserId = sl<SupabaseClient>().auth.currentUser?.id;
  }

  @override
  void didUpdateWidget(covariant AllReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _reload();
    }
  }

  Future<List<ReportEntity>> _loadReports() {
    return sl<GetAllReports>()();
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
    if (_sortOrder != ReportListSortOrder.newest) total++;
    return total;
  }

  List<ReportEntity> _applyFilters(List<ReportEntity> reports) {
    final query = _query.trim().toLowerCase();

    final filtered = reports.where((report) {
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

    if (_sortOrder == ReportListSortOrder.newest) {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortOrder == ReportListSortOrder.oldest) {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_userLatitude != null && _userLongitude != null) {
      filtered.sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
    } else {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  double _distanceKm(ReportEntity report) {
    if (_userLatitude == null || _userLongitude == null) {
      return double.infinity;
    }

    final distanceMeters = Geolocator.distanceBetween(
      _userLatitude!,
      _userLongitude!,
      report.approximateLatitude,
      report.approximateLongitude,
    );

    return distanceMeters / 1000;
  }

  String _distanceLabel(ReportEntity report) {
    final distance = _distanceKm(report);
    if (distance == double.infinity) {
      return 'Sin ubicación actual';
    }
    if (distance < 1) {
      return '${(distance * 1000).round()} m de ti';
    }
    return '${distance.toStringAsFixed(1)} km de ti';
  }

  Future<bool> _ensureSortLocation() async {
    if (_userLatitude != null && _userLongitude != null) {
      return true;
    }

    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        _showMessage('Activa la ubicación para ordenar por proximidad.');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(
          'No pudimos acceder a tu ubicación para ordenar por proximidad.',
        );
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.medium),
      );

      _userLatitude = position.latitude;
      _userLongitude = position.longitude;
      return true;
    } catch (_) {
      _showMessage(
        'No pudimos obtener tu ubicación para ordenar por proximidad.',
      );
      return false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ReportListFiltersResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportListFiltersSheet(
        title: 'Filtros del listado principal',
        includeLost: _includeLost,
        includeFound: _includeFound,
        petType: _petType,
        status: _status,
        query: _query,
        sortOrder: _sortOrder,
        showSortField: true,
      ),
    );

    if (result == null || !mounted) return;
    final nextSortOrder = result.sortOrder ?? ReportListSortOrder.newest;
    if (nextSortOrder == ReportListSortOrder.proximity) {
      final hasLocation = await _ensureSortLocation();
      if (!hasLocation) {
        setState(() {
          _sortOrder = ReportListSortOrder.newest;
        });
        return;
      }
    }
    setState(() {
      _includeLost = result.includeLost;
      _includeFound = result.includeFound;
      _petType = result.petType;
      _status = result.status;
      _query = result.query;
      _sortOrder = nextSortOrder;
    });
  }

  void _resetFilters() {
    setState(() {
      _includeLost = true;
      _includeFound = true;
      _petType = null;
      _status = null;
      _sortOrder = ReportListSortOrder.newest;
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      'Todos los reportes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta reportes tuyos y de la comunidad en un solo lugar.',
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
              ReportListSummaryChip(label: reportListSortLabel(_sortOrder)),
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
                  title: 'No pudimos cargar los reportes',
                  message:
                      'Intenta de nuevo para actualizar el listado general.',
                  actionLabel: 'Reintentar',
                  onAction: _reload,
                );
              }

              final reports = snapshot.data ?? <ReportEntity>[];
              if (reports.isEmpty) {
                return ReportListFeedbackState(
                  icon: Icons.assignment_outlined,
                  title: 'Aún no hay reportes disponibles',
                  message:
                      'Cuando la comunidad publique reportes aparecerán aquí.',
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
                itemBuilder: (context, index) {
                  final report = filteredReports[index];
                  final isMine = report.reporterId == _currentUserId;
                  return ReportListCard(
                    report: report,
                    secondaryInfo: _sortOrder == ReportListSortOrder.proximity
                        ? _distanceLabel(report)
                        : null,
                    extraBadges: [
                      ReportListBadgeData(
                        label: isMine ? 'Tuyo' : 'Comunidad',
                        color: isMine
                            ? AppColors.primary
                            : context.appColors.textSecondary,
                        background: isMine
                            ? context.appColors.pastelBlue
                            : context.appColors.border,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

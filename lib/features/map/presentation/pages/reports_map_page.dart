import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/domain/usecases/get_map_reports.dart';

class ReportsMapPage extends StatefulWidget {
  const ReportsMapPage({super.key});

  @override
  State<ReportsMapPage> createState() => _ReportsMapPageState();
}

class _ReportsMapPageState extends State<ReportsMapPage> {
  static const _defaultCenter = LatLng(4.7110, -74.0721);

  final MapController _mapController = MapController();

  late Future<List<ReportEntity>> _future;
  LatLng _mapCenter = _defaultCenter;
  LatLng? _userLocation;
  bool _isLocating = false;

  bool _includeLost = true;
  bool _includeFound = true;
  String _zone = '';
  String _neighborhood = '';
  String _city = '';
  double _radiusKm = 10;
  ReportPetType? _petType;
  String _breed = '';
  String _color = '';
  ReportPetSize? _size;
  ReportStatus? _status;

  @override
  void initState() {
    super.initState();
    _future = _loadReports();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnCurrentLocation());
  }

  Future<List<ReportEntity>> _loadReports() {
    return sl<GetMapReports>()();
  }

  Future<void> _reloadReports() async {
    setState(() {
      _future = _loadReports();
    });
  }

  Future<void> _centerOnCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;

      final nextCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = nextCenter;
        _mapCenter = nextCenter;
      });
      _mapController.move(nextCenter, 13);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  List<ReportEntity> _applyFilters(List<ReportEntity> reports) {
    return reports.where((report) {
      if (!_includeLost && report.type == ReportType.lost) return false;
      if (!_includeFound && report.type == ReportType.found) return false;
      if (_status != null && report.status != _status) return false;
      if (_petType != null && report.effectivePetType != _petType) return false;
      if (_size != null && report.effectivePetSize != _size) return false;

      final location = (report.locationDescription ?? '').toLowerCase();
      if (_zone.trim().isNotEmpty && !location.contains(_zone.trim().toLowerCase())) {
        return false;
      }
      if (_neighborhood.trim().isNotEmpty && !location.contains(_neighborhood.trim().toLowerCase())) {
        return false;
      }
      if (_city.trim().isNotEmpty && !location.contains(_city.trim().toLowerCase())) {
        return false;
      }

      if (_breed.trim().isNotEmpty) {
        final breed = (report.petBreed ?? '').toLowerCase();
        if (!breed.contains(_breed.trim().toLowerCase())) return false;
      }

      if (_color.trim().isNotEmpty) {
        final color = (report.effectivePetColor ?? '').toLowerCase();
        if (!color.contains(_color.trim().toLowerCase())) return false;
      }

      final center = _userLocation ?? _mapCenter;
      final distanceKm = _distanceKm(
        center.latitude,
        center.longitude,
        report.latitude,
        report.longitude,
      );
      if (distanceKm > _radiusKm) return false;

      return true;
    }).toList();
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  void _openReportDetail(ReportEntity report) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailSheet(report: report),
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_MapFiltersResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapFiltersSheet(
        includeLost: _includeLost,
        includeFound: _includeFound,
        zone: _zone,
        neighborhood: _neighborhood,
        city: _city,
        radiusKm: _radiusKm,
        petType: _petType,
        breed: _breed,
        color: _color,
        size: _size,
        status: _status,
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _includeLost = result.includeLost;
      _includeFound = result.includeFound;
      _zone = result.zone;
      _neighborhood = result.neighborhood;
      _city = result.city;
      _radiusKm = result.radiusKm;
      _petType = result.petType;
      _breed = result.breed;
      _color = result.color;
      _size = result.size;
      _status = result.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mapa de reportes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'OSM · reportes activos cercanos',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
              child: Row(
                children: [
                  _FilterSummaryChip(
                    label: _includeLost && _includeFound
                        ? 'Todos'
                        : _includeLost
                        ? 'Perdidas'
                        : _includeFound
                        ? 'Encontradas'
                        : 'Sin tipos',
                  ),
                  const SizedBox(width: 8),
                  _FilterSummaryChip(label: 'Radio ${_radiusKm.toStringAsFixed(0)} km'),
                  if (_petType != null) ...[
                    const SizedBox(width: 8),
                    _FilterSummaryChip(label: _petTypeLabel(_petType!)),
                  ],
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
                    return _MapFeedbackState(
                      icon: Icons.wifi_off_rounded,
                      title: 'No pudimos cargar el mapa',
                      message: 'Intenta de nuevo para actualizar los reportes activos.',
                      actionLabel: 'Reintentar',
                      onAction: _reloadReports,
                    );
                  }

                  final reports = _applyFilters(snapshot.data ?? const <ReportEntity>[]);
                  if (reports.isEmpty) {
                    return _MapFeedbackState(
                      icon: Icons.location_searching_rounded,
                      title: 'Sin resultados con estos filtros',
                      message: 'Ajusta el radio o los filtros para ver más reportes.',
                      actionLabel: 'Limpiar filtros',
                      onAction: () {
                        setState(() {
                          _includeLost = true;
                          _includeFound = true;
                          _zone = '';
                          _neighborhood = '';
                          _city = '';
                          _radiusKm = 10;
                          _petType = null;
                          _breed = '';
                          _color = '';
                          _size = null;
                          _status = null;
                        });
                      },
                    );
                  }

                  final markers = reports
                      .map(
                        (report) => Marker(
                          point: LatLng(report.latitude, report.longitude),
                          width: 54,
                          height: 54,
                          child: GestureDetector(
                            onTap: () => _openReportDetail(report),
                            child: _ReportMarker(report: report),
                          ),
                        ),
                      )
                      .toList();

                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _mapCenter,
                              initialZoom: 12,
                              onPositionChanged: (position, hasGesture) {
                                final center = position.center;
                                _mapCenter = center;
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.appmascotas.app',
                              ),
                              MarkerLayer(markers: markers),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 32,
                        bottom: 36,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'map-refresh',
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.textPrimary,
                              onPressed: _reloadReports,
                              child: const Icon(Icons.refresh_rounded),
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton.small(
                              heroTag: 'map-center',
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              onPressed: _isLocating ? null : _centerOnCurrentLocation,
                              child: _isLocating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMarker extends StatelessWidget {
  const _ReportMarker({required this.report});

  final ReportEntity report;

  @override
  Widget build(BuildContext context) {
    final color = report.type == ReportType.lost ? AppColors.lostPet : AppColors.foundPet;
    final icon = report.type == ReportType.lost ? Icons.search_off_rounded : Icons.favorite_rounded;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(90),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _MapFeedbackState extends StatelessWidget {
  const _MapFeedbackState({
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

class _MapFiltersResult {
  const _MapFiltersResult({
    required this.includeLost,
    required this.includeFound,
    required this.zone,
    required this.neighborhood,
    required this.city,
    required this.radiusKm,
    required this.petType,
    required this.breed,
    required this.color,
    required this.size,
    required this.status,
  });

  final bool includeLost;
  final bool includeFound;
  final String zone;
  final String neighborhood;
  final String city;
  final double radiusKm;
  final ReportPetType? petType;
  final String breed;
  final String color;
  final ReportPetSize? size;
  final ReportStatus? status;
}

class _MapFiltersSheet extends StatefulWidget {
  const _MapFiltersSheet({
    required this.includeLost,
    required this.includeFound,
    required this.zone,
    required this.neighborhood,
    required this.city,
    required this.radiusKm,
    required this.petType,
    required this.breed,
    required this.color,
    required this.size,
    required this.status,
  });

  final bool includeLost;
  final bool includeFound;
  final String zone;
  final String neighborhood;
  final String city;
  final double radiusKm;
  final ReportPetType? petType;
  final String breed;
  final String color;
  final ReportPetSize? size;
  final ReportStatus? status;

  @override
  State<_MapFiltersSheet> createState() => _MapFiltersSheetState();
}

class _MapFiltersSheetState extends State<_MapFiltersSheet> {
  late bool _includeLost = widget.includeLost;
  late bool _includeFound = widget.includeFound;
  late double _radiusKm = widget.radiusKm;
  late ReportPetType? _petType = widget.petType;
  late ReportPetSize? _size = widget.size;
  late ReportStatus? _status = widget.status;

  late final TextEditingController _zoneCtrl = TextEditingController(text: widget.zone);
  late final TextEditingController _neighborhoodCtrl = TextEditingController(text: widget.neighborhood);
  late final TextEditingController _cityCtrl = TextEditingController(text: widget.city);
  late final TextEditingController _breedCtrl = TextEditingController(text: widget.breed);
  late final TextEditingController _colorCtrl = TextEditingController(text: widget.color);

  @override
  void dispose() {
    _zoneCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _breedCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  'Filtros del mapa',
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
                        onSelected: (value) => setState(() => _includeLost = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Encontradas'),
                        selected: _includeFound,
                        onSelected: (value) => setState(() => _includeFound = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LabeledField(label: 'Zona', child: TextField(controller: _zoneCtrl, decoration: _sheetInput('Ej. norte, centro...'))),
                const SizedBox(height: 12),
                _LabeledField(label: 'Barrio', child: TextField(controller: _neighborhoodCtrl, decoration: _sheetInput('Ej. Chapinero'))),
                const SizedBox(height: 12),
                _LabeledField(label: 'Ciudad', child: TextField(controller: _cityCtrl, decoration: _sheetInput('Ej. Bogotá'))),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Radio (${_radiusKm.toStringAsFixed(0)} km)',
                  child: Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setState(() => _radiusKm = value),
                  ),
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Tipo de mascota',
                  child: DropdownButtonFormField<ReportPetType?>(
                    initialValue: _petType,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: ReportPetType.dog, child: Text('Perro')),
                      DropdownMenuItem(value: ReportPetType.cat, child: Text('Gato')),
                      DropdownMenuItem(value: ReportPetType.other, child: Text('Otro')),
                    ],
                    onChanged: (value) => setState(() => _petType = value),
                    decoration: _sheetInput('Selecciona'),
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(label: 'Raza', child: TextField(controller: _breedCtrl, decoration: _sheetInput('Ej. Labrador'))),
                const SizedBox(height: 12),
                _LabeledField(label: 'Color', child: TextField(controller: _colorCtrl, decoration: _sheetInput('Ej. negro'))),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Tamaño',
                  child: DropdownButtonFormField<ReportPetSize?>(
                    initialValue: _size,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: ReportPetSize.small, child: Text('Pequeño')),
                      DropdownMenuItem(value: ReportPetSize.medium, child: Text('Mediano')),
                      DropdownMenuItem(value: ReportPetSize.large, child: Text('Grande')),
                      DropdownMenuItem(value: ReportPetSize.extraLarge, child: Text('Extra grande')),
                    ],
                    onChanged: (value) => setState(() => _size = value),
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
                      DropdownMenuItem(value: ReportStatus.active, child: Text('Activo')),
                      DropdownMenuItem(value: ReportStatus.underReview, child: Text('En revisión')),
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
                            _radiusKm = 10;
                            _petType = null;
                            _size = null;
                            _status = null;
                            _zoneCtrl.clear();
                            _neighborhoodCtrl.clear();
                            _cityCtrl.clear();
                            _breedCtrl.clear();
                            _colorCtrl.clear();
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
                            _MapFiltersResult(
                              includeLost: _includeLost,
                              includeFound: _includeFound,
                              zone: _zoneCtrl.text.trim(),
                              neighborhood: _neighborhoodCtrl.text.trim(),
                              city: _cityCtrl.text.trim(),
                              radiusKm: _radiusKm,
                              petType: _petType,
                              breed: _breedCtrl.text.trim(),
                              color: _colorCtrl.text.trim(),
                              size: _size,
                              status: _status,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.report});

  final ReportEntity report;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM y, HH:mm', 'es').format(report.occurredAt);
    final title = report.type == ReportType.lost
        ? (report.petName ?? 'Mascota perdida')
        : _foundReportTitle(report);
    final badgeColor = report.type == ReportType.lost ? AppColors.lostPet : AppColors.foundPet;
    final badgeBg = report.type == ReportType.lost ? AppColors.pastelPink : AppColors.pastelGreen;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.primaryPhotoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      report.primaryPhotoUrl!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      report.type == ReportType.lost ? Icons.search_off_rounded : Icons.favorite_rounded,
                      color: badgeColor,
                      size: 34,
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          report.type == ReportType.lost ? 'Perdida' : 'Encontrada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.locationDescription ?? 'Ubicación aproximada registrada',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.schedule_rounded, text: dateLabel),
            if (report.petBreed != null && report.petBreed!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _DetailRow(icon: Icons.pets_rounded, text: report.petBreed!),
              ),
            if ((report.description ?? report.foundPetDescription)?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  report.description?.trim().isNotEmpty == true
                      ? report.description!
                      : report.foundPetDescription!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _foundReportTitle(ReportEntity report) {
  final petType = switch (report.foundPetType) {
    ReportPetType.cat => 'Gato encontrado',
    ReportPetType.other => 'Mascota encontrada',
    _ => 'Perro encontrado',
  };
  final color = report.foundPetColor?.trim();
  if (color == null || color.isEmpty) {
    return petType;
  }
  return '$petType · $color';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
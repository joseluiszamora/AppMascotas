import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

class ReportLocationSelection {
  const ReportLocationSelection({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class ReportLocationPickerCard extends StatelessWidget {
  const ReportLocationPickerCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.disabled,
    required this.onTap,
  });

  final String latitude;
  final String longitude;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        latitude.trim().isNotEmpty && longitude.trim().isNotEmpty;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasSelection
                ? AppColors.primary.withAlpha(80)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.pastelBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.place_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelection
                        ? 'Punto seleccionado en el mapa'
                        : 'Selecciona el punto en el mapa',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasSelection
                        ? '$latitude, $longitude'
                        : 'Se abrirá el mapa con tu ubicación actual para marcar el lugar exacto.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

Future<ReportLocationSelection?> pickReportLocation(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
}) {
  return Navigator.of(context).push<ReportLocationSelection>(
    MaterialPageRoute(
      builder: (_) => ReportLocationPickerPage(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      ),
      fullscreenDialog: true,
    ),
  );
}

class ReportLocationPickerPage extends StatefulWidget {
  const ReportLocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<ReportLocationPickerPage> createState() =>
      _ReportLocationPickerPageState();
}

class _ReportLocationPickerPageState extends State<ReportLocationPickerPage> {
  static const _defaultCenter = LatLng(4.7110, -74.0721);

  final MapController _mapController = MapController();
  LatLng _mapCenter = _defaultCenter;
  LatLng? _selectedLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      final initialPoint = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _mapCenter = initialPoint;
      _selectedLocation = initialPoint;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedLocation == null) {
        _centerOnCurrentLocation();
      }
    });
  }

  Future<void> _centerOnCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        _showMessage('Activa la ubicación para elegir el punto en el mapa.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Debes autorizar la ubicación para usar el mapa.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'La ubicación está bloqueada. Habilítala desde ajustes del sistema.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final nextPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _mapCenter = nextPoint;
        _selectedLocation = nextPoint;
      });
      _mapController.move(nextPoint, 16);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos obtener tu ubicación actual.');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmSelection() {
    final selectedLocation = _selectedLocation;
    if (selectedLocation == null) {
      _showMessage('Selecciona un punto en el mapa antes de continuar.');
      return;
    }

    Navigator.of(context).pop(
      ReportLocationSelection(
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = _selectedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Seleccionar ubicación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Toca el mapa para mover el marcador al punto aproximado del reporte.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter,
                          initialZoom: 16,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _selectedLocation = point;
                              _mapCenter = point;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.appmascotas.app',
                          ),
                          MarkerLayer(
                            markers: [
                              if (selectedLocation != null)
                                Marker(
                                  point: selectedLocation,
                                  width: 52,
                                  height: 52,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    size: 44,
                                    color: AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 14,
                        top: 14,
                        child: FloatingActionButton.small(
                          heroTag: 'location-picker-current-location',
                          onPressed: _isLocating
                              ? null
                              : _centerOnCurrentLocation,
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                          child: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Punto seleccionado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedLocation == null
                          ? 'Aún no has seleccionado una ubicación.'
                          : '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _confirmSelection,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'Usar esta ubicación',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

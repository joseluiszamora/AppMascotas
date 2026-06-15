import 'report_entity.dart';

class ReportMapQuery {
  ReportMapQuery({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    this.includeLost = true,
    this.includeFound = true,
    this.zone,
    this.neighborhood,
    this.city,
    this.petType,
    this.breed,
    this.color,
    this.size,
    this.status,
    this.limit = 250,
  });

  final double centerLatitude;
  final double centerLongitude;
  final double radiusKm;
  final bool includeLost;
  final bool includeFound;
  final String? zone;
  final String? neighborhood;
  final String? city;
  final ReportPetType? petType;
  final String? breed;
  final String? color;
  final ReportPetSize? size;
  final ReportStatus? status;
  final int limit;
}

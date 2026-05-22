import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetMapReports {
  const GetMapReports(this._repository);

  final ReportRepository _repository;

  Future<List<ReportEntity>> call() {
    return _repository.getMapReports();
  }
}

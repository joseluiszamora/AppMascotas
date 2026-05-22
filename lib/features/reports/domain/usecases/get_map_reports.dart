import '../entities/report_entity.dart';
import '../entities/report_map_query.dart';
import '../repositories/report_repository.dart';

class GetMapReports {
  const GetMapReports(this._repository);

  final ReportRepository _repository;

  Future<List<ReportEntity>> call(ReportMapQuery query) {
    return _repository.getMapReports(query);
  }
}

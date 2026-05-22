import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetRecentReports {
  const GetRecentReports(this._repository);

  final ReportRepository _repository;

  Future<List<ReportEntity>> call({int limit = 5}) {
    return _repository.getRecentReports(limit: limit);
  }
}

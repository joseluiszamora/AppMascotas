import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetMyReports {
  GetMyReports(this._repository);

  final ReportRepository _repository;

  Future<List<ReportEntity>> call({int limit = 100}) {
    return _repository.getMyReports(limit: limit);
  }
}

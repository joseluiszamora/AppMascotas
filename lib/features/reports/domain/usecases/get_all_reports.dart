import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetAllReports {
  const GetAllReports(this._repository);

  final ReportRepository _repository;

  Future<List<ReportEntity>> call({int limit = 200}) {
    return _repository.getAllReports(limit: limit);
  }
}

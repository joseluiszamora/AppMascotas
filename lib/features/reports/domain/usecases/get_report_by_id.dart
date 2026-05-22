import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetReportById {
  const GetReportById(this._repository);

  final ReportRepository _repository;

  Future<ReportEntity> call(String reportId) {
    return _repository.getReportById(reportId);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/report_entity.dart';
import '../models/report_model.dart';

class ReportProvider {
  const ReportProvider({required this.supabase});

  final SupabaseClient supabase;

  Future<List<ReportEntity>> getRecentReports({int limit = 5}) async {
    final data = await supabase
        .from('reports')
        .select('*, report_photos(*), pets(name, breed)')
        .inFilter('status', ['active', 'under_review'])
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List<dynamic>)
        .map((row) => ReportModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ReportEntity> createLostReport({
    required String petId,
    required double latitude,
    required double longitude,
    String? locationDescription,
    required DateTime occurredAt,
    String? description,
    required bool showContact,
  }) async {
    final reportId = await supabase.rpc(
      'create_lost_report',
      params: {
        'p_pet_id': petId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_location_description': locationDescription,
        'p_occurred_at': occurredAt.toIso8601String(),
        'p_description': description,
        'p_show_contact': showContact,
      },
    ) as String;

    final data = await supabase
        .from('reports')
        .select('*, report_photos(*)')
        .eq('id', reportId)
        .single();

    return ReportModel.fromJson(data);
  }
}
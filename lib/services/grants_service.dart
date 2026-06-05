import 'package:dio/dio.dart';
import '../models/access_grant_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class GrantsService {
  final ApiService _api = ApiService();

  // ─── My grants ────────────────────────────────────────────────────

  Future<List<AccessGrant>> getMyGrants() async {
    try {
      final response = await _api.dio.get(AppConstants.grantsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data is Map
            ? (data['items'] ?? data['grants'] ?? [])
            : data as List;
        return items
            .map((j) => AccessGrant.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      throw Exception(_extractError(response.data, response.statusCode));
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.response?.statusCode));
    }
  }

  // ─── Available doctors ────────────────────────────────────────────

  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _api.dio.get(AppConstants.doctorsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> items = data['items'] ?? [];
        return items
            .map((j) => Doctor.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      throw Exception(_extractError(response.data, response.statusCode));
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.response?.statusCode));
    }
  }

  // ─── Create grant ─────────────────────────────────────────────────

  Future<AccessGrant> createGrant({
    required String doctorId,
    required int expiresInHours,
  }) async {
    try {
      final response = await _api.dio.post(
        AppConstants.grantsEndpoint,
        data: {
          'doctorId': doctorId,
          'expiresInHours': expiresInHours,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return AccessGrant.fromJson({
          ...data,
          'patientId': '',
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      throw Exception(_extractError(response.data, response.statusCode));
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.response?.statusCode));
    }
  }

  // ─── Revoke grant ─────────────────────────────────────────────────

  Future<void> revokeGrant(String id) async {
    try {
      final response =
          await _api.dio.delete('${AppConstants.grantsEndpoint}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(_extractError(response.data, response.statusCode));
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.response?.statusCode));
    }
  }

  // ─── helpers ──────────────────────────────────────────────────────

  String _extractError(dynamic body, int? statusCode) {
    if (body is Map) {
      return (body['message'] ?? body['error'] ?? 'خطأ (${statusCode ?? '?'})').toString();
    }
    return 'خطأ في الاتصال بالخادم';
  }
}

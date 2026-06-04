import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/access_grant_model.dart';
import '../utils/constants.dart';

class GrantsService {
  final _api = ApiService();

  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _api.dio.get(AppConstants.doctorsEndpoint);
      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : response.data['doctors'] ?? [];
        return data.map((e) => Doctor.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'فشل تحميل قائمة الأطباء');
    }
  }

  Future<List<AccessGrant>> getMyGrants() async {
    try {
      final response = await _api.dio.get(AppConstants.grantsEndpoint);
      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : response.data['grants'] ?? [];
        return data.map((e) => AccessGrant.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'فشل تحميل المواعيد');
    }
  }

  /// Create a new appointment request (access grant) for a doctor
  Future<AccessGrant> createGrant({
    required String doctorId,
    int expiresInHours = 72,
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
        return AccessGrant.fromJson(response.data);
      }
      throw Exception('فشل طلب الموعد');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'فشل طلب الموعد');
    }
  }

  /// Cancel / revoke a grant
  Future<void> revokeGrant(String grantId) async {
    try {
      await _api.dio.delete('${AppConstants.grantsEndpoint}/$grantId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'فشل إلغاء الموعد');
    }
  }
}

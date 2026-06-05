import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/medical_record_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class RecordsService {
  final ApiService _api = ApiService();

  // ─── Fetch records ────────────────────────────────────────────────

  Future<List<MedicalRecord>> getMyRecords() async {
    try {
      final response = await _api.dio.get(AppConstants.recordsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        // The backend returns { items: [...] }
        final List<dynamic> items =
            data is Map ? (data['items'] ?? data['records'] ?? []) : data as List;
        return items
            .map((j) => MedicalRecord.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      final msg = _extractError(response.data, response.statusCode);
      throw Exception(msg);
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.response?.statusCode));
    }
  }

  // ─── Upload ───────────────────────────────────────────────────────

  /// Uploads a [PlatformFile] as multipart/form-data.
  /// Works on both mobile (uses path) and web (uses bytes).
  Future<MedicalRecord> uploadFile(
    PlatformFile platformFile, {
    String? description,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final String fileName = platformFile.name;
      MultipartFile multipartFile;

      if (platformFile.bytes != null) {
        // Web — bytes are available directly
        multipartFile = MultipartFile.fromBytes(
          platformFile.bytes!,
          filename: fileName,
        );
      } else if (platformFile.path != null) {
        // Mobile / desktop — use file path
        multipartFile = await MultipartFile.fromFile(
          platformFile.path!,
          filename: fileName,
        );
      } else {
        throw Exception('لا يمكن قراءة الملف');
      }

      final formData = FormData.fromMap({
        'files': multipartFile,
        if (description != null && description.isNotEmpty)
          'description': description,
      });

      final response = await _api.dio.post(
        AppConstants.recordsEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          // Remove the default application/json Content-Type for this request
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        // Backend returns { items: [{ id, fileUrl, fileName }] }
        final items = data['items'] as List<dynamic>;
        if (items.isEmpty) throw Exception('لم يتم استلام بيانات الملف');
        final item = items.first as Map<String, dynamic>;
        // Build a full MedicalRecord from the returned partial data
        return MedicalRecord.fromJson({
          ...item,
          'createdAt': DateTime.now().toIso8601String(),
          'description': description,
        });
      }

      throw Exception(_extractError(response.data, response.statusCode));
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.response?.statusCode));
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────

  Future<void> deleteRecord(String id) async {
    try {
      final response =
          await _api.dio.delete('${AppConstants.recordsEndpoint}/$id');
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

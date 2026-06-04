import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import '../models/medical_record_model.dart';
import '../utils/constants.dart';

class RecordsService {
  final _api = ApiService();

  /// جلب سجلات المريض
  Future<List<MedicalRecord>> getMyRecords() async {
    try {
      final response = await _api.dio.get(AppConstants.recordsEndpoint);
      if (response.statusCode == 200) {
        final data = response.data;
        // الـ API يعيد { items: [...] } أو قائمة مباشرة
        final List raw = data is List
            ? data
            : (data['items'] ?? data['records'] ?? []);
        return raw.map((e) => MedicalRecord.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'فشل تحميل السجلات';
      throw Exception(msg);
    }
  }

  /// رفع ملف طبي — يعمل على الويب والموبايل
  Future<MedicalRecord> uploadFile(
    PlatformFile platformFile, {
    String? description,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      late MultipartFile multipartFile;

      if (kIsWeb) {
        // على الويب: نستخدم الـ bytes مباشرة (لا يوجد path)
        final bytes = platformFile.bytes;
        if (bytes == null) throw Exception('لا يمكن قراءة الملف');
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: platformFile.name,
        );
      } else {
        // على الموبايل: نستخدم المسار
        final path = platformFile.path;
        if (path == null) throw Exception('لا يمكن قراءة مسار الملف');
        multipartFile = await MultipartFile.fromFile(
          path,
          filename: platformFile.name,
        );
      }

      // اسم الحقل في الـ API هو 'files' (وليس 'file')
      final formData = FormData.fromMap({
        'files': multipartFile,
        if (description != null && description.isNotEmpty)
          'description': description,
      });

      // ✅ Add blob token header for upload
      final response = await _api.dio.post(
        AppConstants.recordsEndpoint,
        data: formData,
        options: Options(
          headers: {
            'x-blob-token': AppConstants.blobReadWriteToken,
          },
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // الـ API يعيد { items: [{id, fileUrl, fileName}] }
        final itemsList = data['items'] as List?;
        if (itemsList != null && itemsList.isNotEmpty) {
          return MedicalRecord.fromJson(itemsList.first);
        }
        return MedicalRecord.fromJson(data);
      }
      throw Exception(response.data?['error'] ?? 'فشل رفع الملف');
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'فشل رفع الملف';
      throw Exception(msg);
    }
  }

  /// حذف سجل طبي
  Future<void> deleteRecord(String recordId) async {
    try {
      await _api.dio.delete('${AppConstants.recordsEndpoint}/$recordId');
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'فشل حذف السجل';
      throw Exception(msg);
    }
  }
}

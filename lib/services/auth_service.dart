// lib/services/auth_service.dart
import 'api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = response.data;

        // Extract and save the token
        final token = data['token'];
        if (token == null) throw Exception('No token received');
        await _api.saveToken(token);

        // Extract user data (adjust the path if needed)
        final userData = data['user'] ?? data;
        return UserModel.fromJson(userData);
      } else {
        final errorMsg = response.data?['error'] ?? response.data?['message'] ?? 'فشل تسجيل الدخول';
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.response?.data?['message'];
      throw Exception(msg ?? 'خطأ في الاتصال بالخادم');
    }
  }

  Future<UserModel?> getSession() async {
    try {
      final response = await _api.dio.get(AppConstants.sessionEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data['user'] ?? response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _api.dio.post(AppConstants.signOutEndpoint);
    } finally {
      await _api.clearToken();
    }
  }
}

// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {'email': email, 'password': password},
      );
      print('🔵 Login response status: ${response.statusCode}');
      print('🔵 Full response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        if (token == null) {
          print('❌ No token in response');
          throw Exception('No token received');
        }
        await _api.saveToken(token);

        final userJson = data['user'];
        if (userJson == null) {
          print('❌ No user object in response');
          throw Exception('No user data received');
        }
        return UserModel.fromJson(userJson);
      } else {
        throw Exception('Login failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Message: ${e.message}');
      if (e.response != null) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Data: ${e.response?.data}');
      } else {
        print('❌ No response (network/CORS)');
      }
      throw Exception(e.response?.data['message'] ?? 'فشل تسجيل الدخول');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('خطأ غير متوقع');
    }
  }

  // getSession and signOut unchanged...
  Future<UserModel?> getSession() async {
    try {
      final response = await _api.dio.get(AppConstants.sessionEndpoint);
      if (response.statusCode == 200 && response.data['user'] != null) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      print('getSession error: $e');
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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // ✅ ADDED for debugPrint

import '../utils/constants.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  late final CookieJar _cookieJar;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _cookieJar = CookieJar();

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 600,
      extra: {'withCredentials': true},
    ));

    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }

    // 🔑 CRITICAL: Add token interceptor for ALL platforms
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint('🔑 [ApiService] Token attached to ${options.path}');
        } else {
          debugPrint('⚠️ [ApiService] No token for ${options.path}');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearSession();
          debugPrint('🔄 [ApiService] 401 → session cleared');
        }
        handler.next(error);
      },
    ));
  }

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  /// Save the Bearer token after login
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    debugPrint('💾 [ApiService] Token saved');
  }

  /// Clear the Bearer token on logout
  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    debugPrint('🗑️ [ApiService] Token cleared');
  }

  /// Clear both cookies (mobile) and token
  Future<void> clearSession() async {
    if (!kIsWeb) {
      await _cookieJar.deleteAll();
    }
    await clearToken();
  }

  // ✅ ADDED: public getter to manually read token (used as fallback)
  Future<String?> getToken() async => await _storage.read(key: 'auth_token');
}

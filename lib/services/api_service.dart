import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  late final CookieJar? _cookieJar;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _cookieJar = kIsWeb ? null : CookieJar();

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 600,
      // Disable credentials (cookies) on web – only Bearer token
      extra: {'withCredentials': !kIsWeb},
    ));

    if (!kIsWeb && _cookieJar != null) {
      _dio.interceptors.add(CookieManager(_cookieJar!));
    }

    // Token interceptor (always first)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('✅ Token attached to ${options.path}');
        } else {
          print('⚠️ No token for ${options.path}');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearSession();
          print('🔄 401 → session cleared');
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

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    print('💾 Token saved');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    print('🗑️ Token cleared');
  }

  Future<void> clearSession() async {
    if (!kIsWeb && _cookieJar != null) {
      await _cookieJar!.deleteAll();
    }
    await clearToken();
  }

  Future<String?> getToken() async => await _storage.read(key: 'auth_token');
}

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../utils/constants.dart';

class ApiService {
  static ApiService? _instance;
  late Dio _dio;
  late CookieJar _cookieJar;

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
      // Better Auth uses cookies — accept all status codes so we can read errors
      validateStatus: (status) => status != null && status < 600,
    ));

    // Cookie manager: automatically sends/stores session cookies (like a browser)
    _dio.interceptors.add(CookieManager(_cookieJar));

    // Auto-handle 401 by clearing cookies
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearSession();
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

  /// Clear all session cookies (called on sign-out or 401)
  Future<void> clearSession() async {
    await _cookieJar.deleteAll();
  }
}

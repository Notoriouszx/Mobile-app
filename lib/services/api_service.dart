import 'package:dio/dio.dart';
import 'package:dio/browser.dart' show BrowserHttpClientAdapter;
import 'package:flutter/foundation.dart' show kIsWeb;
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
      // Never throw on 4xx/5xx — let callers inspect statusCode
      validateStatus: (status) => status != null && status < 600,
    ));

    if (kIsWeb) {
      // On web: the browser handles cookies automatically when
      // withCredentials = true. We must NOT add CookieManager.
      (_dio.httpClientAdapter as BrowserHttpClientAdapter)
          .withCredentials = true;
    } else {
      // On mobile/desktop: dio_cookie_manager persists the
      // better-auth.session_token cookie between requests.
      _dio.interceptors.add(CookieManager(_cookieJar));
    }

    // Log errors in debug mode and auto-clear session on 401
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

  /// Clears the cookie jar on logout (mobile/desktop only;
  /// on web the browser handles cookie deletion via the server's
  /// Set-Cookie: ...; Max-Age=0 response from /api/auth/sign-out).
  Future<void> clearSession() async {
    if (!kIsWeb) {
      await _cookieJar.deleteAll();
    }
  }
}

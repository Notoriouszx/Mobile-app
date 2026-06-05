import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../utils/constants.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  late final CookieJar _cookieJar;

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
      // Never throw on 4xx/5xx — callers check statusCode themselves
      validateStatus: (status) => status != null && status < 600,
      // This is the Dio 5.x way to enable withCredentials on web.
      // It tells the underlying XHR to include cookies / auth headers
      // in cross-origin requests.
      extra: {'withCredentials': true},
    ));

    if (!kIsWeb) {
      // Mobile / desktop: persist the better-auth session cookie and
      // replay it on every request automatically.
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
    // On web: the browser handles cookies. 'withCredentials: true' in
    // BaseOptions.extra is enough — no CookieManager needed.

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

  /// Clears local cookies on mobile/desktop.
  /// On web the server clears the cookie via Set-Cookie on sign-out.
  Future<void> clearSession() async {
    if (!kIsWeb) {
      await _cookieJar.deleteAll();
    }
  }
}

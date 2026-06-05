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
      // withCredentials=true is required on web so the browser
      // sends the better-auth session cookie on cross-origin requests
      // AND accepts the credentialed CORS response from Vercel.
      extra: {'withCredentials': true},
    ));

    if (!kIsWeb) {
      // Mobile / desktop: CookieManager stores the better-auth
      // session cookie from the login response and replays it
      // automatically on every subsequent request.
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
    // On web: withCredentials=true in extra is sufficient.
    // The browser handles cookie storage and replay natively.
    // Do NOT add CookieManager on web.

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

  Future<void> clearSession() async {
    if (!kIsWeb) {
      await _cookieJar.deleteAll();
    }
    // On web the server clears the cookie via Set-Cookie on sign-out.
  }
}

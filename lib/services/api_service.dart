import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      validateStatus: (status) => status != null && status < 600,
      extra: {'withCredentials': true},
    ));

    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }

    // Intercept every request and attach the session token as a header.
    // This is required because the cookie is on notoriouszx.github.io
    // but the API is on project-9g6if.vercel.app — browsers never send
    // cookies cross-domain, so we read the saved token and send it as
    // the "x-session-token" header which the backend reads explicitly.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('session_token');
        if (token != null) {
          options.headers['x-session-token'] = token;
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // After login, Better Auth returns the session token in the
        // response body under session.token — save it for future requests.
        if (response.requestOptions.path == AppConstants.signInEndpoint &&
            response.statusCode == 200) {
          final data = response.data;
          if (data is Map) {
            final sessionToken =
                data['session']?['token'] as String? ??
                data['token'] as String?;
            if (sessionToken != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('session_token', sessionToken);
            }
          }
        }
        handler.next(response);
      },
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
  }
}

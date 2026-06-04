import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';

class ApiService {
  static ApiService? _instance;
  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Enable credentials (cookies) for authentication
      // This allows session cookies to be sent with each request
      extra: {'withCredentials': true},
      // Don't throw on any status code - we handle them ourselves
      validateStatus: (status) => status != null && status < 600,
    ));

    // Add interceptors for debugging and cookie management
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Ensure credentials are sent with each request
        options.extra['withCredentials'] = true;
        print('API Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} ${error.requestOptions.path} - ${error.message}');
        handler.next(error);
      },
    ));

    // Add cookie manager for mobile platforms
    if (!kIsWeb) {
      _addMobileCookieSupport();
    }
  }

  void _addMobileCookieSupport() {
    try {
      final cookieJar = CookieJarInterceptor();
      _dio.interceptors.add(cookieJar);
      print('Cookie jar interceptor added for mobile');
    } catch (e) {
      print('Cookie support error: $e');
    }
  }

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<void> clearCookies() async {
    // Cookies are managed by the interceptor and server session
    print('Cookies cleared via logout');
  }
}

/// Simple cookie interceptor for mobile platforms
/// Handles Set-Cookie headers from responses and sends cookies with requests
class CookieJarInterceptor extends Interceptor {
  final Map<String, String> _cookies = {};

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      print('Set-Cookie header found: $setCookie');
      for (final cookie in setCookie) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          _cookies[name] = value;
          print('Stored cookie: $name=$value');
        }
      }
    }
    handler.next(response);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_cookies.isNotEmpty) {
      final cookieHeader = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      options.headers['Cookie'] = cookieHeader;
      print('Sending cookies: $cookieHeader');
    }
    handler.next(options);
  }
}

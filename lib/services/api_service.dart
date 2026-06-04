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
      // On web, browser handles cookies automatically via credentials
      extra: {'withCredentials': true},
    ));

    // Only add cookie manager on mobile (not web)
    if (!kIsWeb) {
      _addMobileCookieSupport();
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // On web, browser sends cookies automatically
        // On mobile, cookies are managed by the cookie jar
        options.extra['withCredentials'] = true;
        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        handler.next(error);
      },
    ));
  }

  void _addMobileCookieSupport() async {
    try {
      // Dynamic import only on mobile platforms
      // ignore: avoid_dynamic_calls
      final cookieJar = await _createCookieJar();
      if (cookieJar != null) {
        _dio.interceptors.add(cookieJar);
      }
    } catch (_) {}
  }

  Future<Interceptor?> _createCookieJar() async {
    try {
      // This will only be called on non-web platforms
      final CookieJarInterceptor interceptor = CookieJarInterceptor();
      return interceptor;
    } catch (_) {
      return null;
    }
  }

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<void> clearCookies() async {
    // On web, we can't clear cookies directly
    // Better Auth handles logout via the API
  }
}

// Simple cookie interceptor for mobile
class CookieJarInterceptor extends Interceptor {
  final Map<String, String> _cookies = {};

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      for (final cookie in setCookie) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length >= 2) {
          _cookies[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }
    handler.next(response);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_cookies.isNotEmpty) {
      options.headers['Cookie'] = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    handler.next(options);
  }
}

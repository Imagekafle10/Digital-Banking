import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

/// Thin wrapper around [Dio] that:
/// - keeps the httpOnly `refreshToken` cookie alive across requests (and
///   across app restarts, via a persisted [PersistCookieJar]) exactly the
///   way a browser would - the "httpOnly" flag only matters to JS running
///   inside a browser, an HTTP client still sends/receives the cookie.
/// - attaches the short-lived access token as a Bearer header.
/// - transparently refreshes the access token once on a 401 and retries
///   the original request, matching the backend's /auth/refresh contract.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  late final Dio dio;
  String? _accessToken;
  bool _initialized = false;
  Future<void>? _refreshing;

  static const _accessTokenKey = 'nepal_bank_access_token';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
        extra: {'withCredentials': true},
      ),
    );

    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      final cookieJar = PersistCookieJar(
        storage: FileStorage('${appDir.path}/.cookies/'),
        ignoreExpires: false,
      );
      dio.interceptors.add(CookieManager(cookieJar));
    }

    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null &&
              !options.path.contains('/auth/login') &&
              !options.path.contains('/auth/register')) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthRoute = error.requestOptions.path.contains('/auth/');
          if (error.response?.statusCode == 401 && !isAuthRoute) {
            try {
              await _refreshAccessToken();
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await dio.fetch(retryOptions);
              return handler.resolve(response);
            } catch (_) {
              await clearAccessToken();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _refreshAccessToken() {
    // De-dupe concurrent 401s into a single /refresh call.
    _refreshing ??= dio.post(ApiConstants.refresh).then((response) async {
      final token = response.data['data']['accessToken'] as String;
      await setAccessToken(token);
    }).whenComplete(() => _refreshing = null);
    return _refreshing!;
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  Future<void> clearAccessToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
  }

  bool get hasAccessToken => _accessToken != null;

  /// Tries a silent refresh - used on app launch to figure out whether the
  /// user already has a valid session (refresh cookie) without asking them
  /// to log in again.
  Future<bool> trySilentRefresh() async {
    try {
      await _refreshAccessToken();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Small helper for turning Dio errors into a message the UI can show
/// directly, matching the backend's `{ message }` / `{ errors: [...] }`
/// error shape (see app.ts's centralized error handler and the Joi
/// validation middlewares).
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        return (data['errors'] as List).join('\n');
      }
      if (data['message'] is String) return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return "Couldn't reach the server. Check your connection and the "
          'API base URL in api_constants.dart.';
    }
  }
  return 'Something went wrong. Please try again.';
}

import 'package:bbeta/config/env_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static String get baseUrl => EnvConfig.apiBaseUrl;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: EnvConfig.connectTimeout,
      receiveTimeout: EnvConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    if (EnvConfig.enableLogging) {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          print('📤 [API] ${options.method.toUpperCase()} ${options.path}');
          print('📤 [API] Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 [API] Response ${response.statusCode}: ${response.requestOptions.path}');
          print('📥 [API] Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ [API] Error: ${error.message}');
          print('❌ [API] Status: ${error.response?.statusCode}');
          print('❌ [API] Response: ${error.response?.data}');
          return handler.next(error);
        },
      ));
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            final token = await getAccessToken();
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  // ─── Token Management ───

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh = await getRefreshToken();
      if (refresh == null) return false;

      final response = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/auth/refresh/',
        data: {'refresh': refresh},
      );

      if (response.statusCode == 200) {
        await saveTokens(
          response.data['access'],
          refresh,
        );
        return true;
      }
    } catch (_) {}
    await clearTokens();
    return false;
  }

  // ─── Auth ───

  Future<Response> register(String email, String password) async {
    return await dio.post('/auth/register/', data: {
      'email': email,
      'password': password,
      'password2': password,
    });
  }

  Future<Response> verifyEmail(String code) async {
    return await dio.post('/auth/register/verify_email/', data: {
      'code': code,
    });
  }

  Future<Response> login(String email, String password) async {
    return await dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> googleAuth(String idToken) async {
    return await dio.post('/auth/google/', data: {
      'credential': idToken,
    });
  }

  Future<Response> getProfile() async {
    return await dio.get('/auth/profile/profile/');
  }

  Future<void> logout() async {
    try {
      await dio.post('/auth/logout/logout/');
    } catch (_) {}
    await clearTokens();
  }

  // ─── Books ───

  Future<Response> getBooks({String? query, List<int>? genreIds}) async {
    final params = <String, dynamic>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (genreIds != null && genreIds.isNotEmpty) {
      params['genre'] = genreIds;
    }
    return await dio.get('/books/', queryParameters: params);
  }

  Future<Response> getBookDetail(int id) async {
    return await dio.get('/books/$id/');
  }

  Future<Response> searchGoogleBooks(String query) async {
    return await dio.get('/books/search-google/', queryParameters: {'q': query});
  }

  Future<Response> getGenres() async {
    return await dio.get('/genres/');
  }

  // ─── Reading ───

  Future<Response> getReadingProgress() async {
    return await dio.get('/reading/progress/');
  }

  Future<Response> getCurrentlyReading() async {
    return await dio.get('/reading/progress/currently-reading/');
  }

  Future<Response> getReadingStats() async {
    return await dio.get('/reading/progress/stats/');
  }

  Future<Response> startReading(int bookId) async {
    return await dio.post('/reading/progress/start/', data: {
      'book_id': bookId,
    });
  }

  Future<Response> logSession({
    required int bookId,
    required int startPage,
    required int endPage,
    required int durationMinutes,
  }) async {
    return await dio.post('/reading/progress/log-session/', data: {
      'book_id': bookId,
      'start_page': startPage,
      'end_page': endPage,
      'duration_minutes': durationMinutes,
    });
  }
  Future<Response> registerFCMToken(String token) async {
    return await dio.post('/notifications/register-token/', data: {'token': token});
  }

  Future<Response> unregisterFCMToken(String token) async {
    return await dio.delete('/notifications/unregister-token/', data: {'token': token});
  }

  Future<Response> getNotifications() async {
    return await dio.get('/notifications/');
  }

  Future<Response> getUnreadCount() async {
    return await dio.get('/notifications/unread-count/');
  }

  Future<Response> markNotificationRead(int id) async {
    return await dio.patch('/notifications/$id/read/');
  }

  Future<Response> markAllNotificationsRead() async {
    return await dio.post('/notifications/mark-all-read/');
  }

  Future<Response> getNotificationPreferences() async {
    return await dio.get('/notifications/preferences/');
  }

  Future<Response> updateNotificationPreferences(Map<String, dynamic> data) async {
    // Auto-attach device timezone
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    data['timezone'] = 'Etc/GMT${offset.inHours == 0 ? '' : (offset.isNegative ? '+' : '-')}${offset.inHours.abs()}';
    return await dio.patch('/notifications/preferences/', data: data);
  }

  Future<Response> deleteNotification(int id) async {
    return await dio.delete('/notifications/$id/delete/');
  }

  Future<Response> deleteAllNotifications() async {
    return await dio.delete('/notifications/delete-all/');
  }

  // ─── Gamification / Leaderboard ───

  Future<Response> getLeaderboard({int limit = 20}) async {
    return await dio.get('/gamification/leaderboard/', queryParameters: {'limit': limit});
  }

  Future<Response> getMyRank() async {
    return await dio.get('/gamification/my-rank/');
  }

  Future<Response> getMyBadges() async {
    return await dio.get('/gamification/badges/');
  }
}

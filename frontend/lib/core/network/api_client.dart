import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        extra: {'withCredentials': true}, // Enables HttpOnly cookies for Web / PWA
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.extra['withCredentials'] = true;

          // Attach short-lived Bearer access token
          final token = await TokenStorage.getAccessToken();
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Attach CSRF protection header if available
          final csrf = await TokenStorage.getCsrfToken();
          if (csrf != null && !options.headers.containsKey('X-CSRF-Token')) {
            options.headers['X-CSRF-Token'] = csrf;
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            // Attempt token refresh
            try {
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: ApiConstants.baseUrl,
                  extra: {'withCredentials': true},
                ),
              );

              final csrfToken = await TokenStorage.getCsrfToken();
              final Map<String, dynamic> headers = {};
              if (csrfToken != null) {
                headers['X-CSRF-Token'] = csrfToken;
              }

              Map<String, dynamic> body = {};
              if (!kIsWeb) {
                final refreshToken = await TokenStorage.getRefreshToken();
                if (refreshToken == null) {
                  return handler.next(error);
                }
                body['refresh_token'] = refreshToken;
              }

              final response = await refreshDio.post(
                ApiConstants.refresh,
                data: body,
                options: Options(headers: headers),
              );

              if (response.statusCode == 200) {
                final newAccess = response.data['access_token'] as String;
                final newRefresh = response.data['refresh_token'] as String?;
                final newCsrf = response.data['csrf_token'] as String?;

                await TokenStorage.saveTokens(
                  accessToken: newAccess,
                  refreshToken: newRefresh,
                  csrfToken: newCsrf,
                );

                // Retry original request with new token
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                if (newCsrf != null) {
                  error.requestOptions.headers['X-CSRF-Token'] = newCsrf;
                }
                final retryResponse = await dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              await TokenStorage.clear();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}

final apiClient = ApiClient();

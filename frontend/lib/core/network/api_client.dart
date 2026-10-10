import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            // Attempt token refresh
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
                final response = await refreshDio.post(
                  ApiConstants.refresh,
                  data: {'refresh_token': refreshToken},
                );
                if (response.statusCode == 200) {
                  final newAccess = response.data['access_token'] as String;
                  final newRefresh = response.data['refresh_token'] as String;
                  await TokenStorage.saveTokens(
                    accessToken: newAccess,
                    refreshToken: newRefresh,
                  );

                  // Retry original request with new token
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                  final retryResponse = await dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                await TokenStorage.clear();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}

final apiClient = ApiClient();

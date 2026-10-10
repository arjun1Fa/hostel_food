import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        state = const AuthState(isAuthenticated: false, isLoading: false);
        return;
      }

      final response = await apiClient.dio.get(ApiConstants.me);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        await TokenStorage.saveUserData(
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          role: user.role,
          roomNumber: user.roomNumber,
        );
        state = AuthState(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );
      } else {
        await TokenStorage.clear();
        state = const AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (_) {
      // Check cached data if offline
      final cached = await TokenStorage.getUserData();
      if (cached != null) {
        state = AuthState(
          isAuthenticated: true,
          user: UserModel.fromJson(cached),
          isLoading: false,
        );
      } else {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200) {
        final access = response.data['access_token'] as String;
        final refresh = response.data['refresh_token'] as String;
        await TokenStorage.saveTokens(accessToken: access, refreshToken: refresh);

        // Fetch user profile
        final meResponse = await apiClient.dio.get(
          ApiConstants.me,
          options: Options(headers: {'Authorization': 'Bearer $access'}),
        );
        final user = UserModel.fromJson(meResponse.data);
        await TokenStorage.saveUserData(
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          role: user.role,
          roomNumber: user.roomNumber,
        );

        state = AuthState(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Login failed. Please check credentials.';
      state = state.copyWith(isLoading: false, errorMessage: detail.toString());
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? roomNumber,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await apiClient.dio.post(
        ApiConstants.register,
        data: {
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
          'room_number': roomNumber?.trim(),
          'phone_number': phoneNumber?.trim(),
        },
      );

      if (response.statusCode == 201) {
        // Automatically log in after registration
        return await login(email: email, password: password);
      }
      return false;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Registration failed.';
      state = state.copyWith(isLoading: false, errorMessage: detail.toString());
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await TokenStorage.getRefreshToken();
      if (refresh != null) {
        await apiClient.dio.post(
          '/auth/logout',
          data: {'refresh_token': refresh},
        );
      }
    } catch (_) {}
    await TokenStorage.clear();
    state = const AuthState(isAuthenticated: false, user: null, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

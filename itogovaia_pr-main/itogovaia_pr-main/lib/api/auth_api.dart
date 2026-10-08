import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/app_user.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login(String username, String password) {
    return guard(() async {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthTokens.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) {
    return guard(() async {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
        },
      );
      return AppUser.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  Future<AppUser> me() {
    return guard(() async {
      final response = await _dio.get('/auth/me');
      return AppUser.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  Future<AuthTokens> refresh(String refreshToken) {
    return guard(() async {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthTokens.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  Future<void> logout(String? refreshToken) {
    return guard(() async {
      await _dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    });
  }

  Future<List<AppUser>> listUsers() {
    return guard(() async {
      final response = await _dio.get('/users');
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }
}

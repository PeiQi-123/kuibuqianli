// lib/services/auth_service.dart
// 认证服务类
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<UserModel?> login(String username, String password) async {
    try {
      // 1. 登录前先清除所有旧token
      await StorageService.removeToken();

      // 2. 使用专门的登录方法，不传递任何token
      final response = await _apiService.postForLogin('/user/login', {
        'username': username,
        'password': password,
      });

      if (response != null) {
        if (response['code'] == 200) {
          // 登录成功
          final data = response['data'];
          final token = data['token'].toString();
          final user = data['user'];

          // 保存新token到本地存储
          await StorageService.saveToken(token);

          return UserModel(
            id: user['id'].toString(),
            username: user['username'],
            email: user['email'],
            token: token,
          );
        } else {
          // 登录失败
          print('Login failed: ${response['message']}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      // 注册时也不应该带token
      await StorageService.removeToken();

      final response = await _apiService.postForLogin('/user/register', {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response != null) {
        if (response['code'] == 200) {
          return true; // 注册成功
        } else {
          print('Registration failed: ${response['message']}');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.removeToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  // 添加获取当前用户信息的方法
  Future<UserModel?> getCurrentUser() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiService.get('/user/info', params: {'userId': '1'});

      if (response != null && response['code'] == 200) {
        final user = response['data'];
        return UserModel(
          id: user['id'].toString(),
          username: user['username'],
          email: user['email'],
          token: token,
        );
      }
      return null;
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }
}
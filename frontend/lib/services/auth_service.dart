// lib/services/auth_service.dart
// 认证服务类
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
          
          // 保存用户ID到本地存储
          if (user['id'] != null) {
            await StorageService.saveUserId(user['id'].toString());
          }

          // 使用新的fromJson方法创建UserModel，包含所有字段
          return UserModel.fromJson({
            ...user,
            'token': token,
          });
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
          // 注册成功
          // 注意：后端返回的data是字符串"注册成功"，不是包含user信息的对象
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
    await StorageService.removeUserId();
  }

  // 更新用户信息
  Future<bool> updateUserInfo({
    String? username,
    String? email,
    String? phone,
    String? password,
    double? height,
    double? weight,
    int? age,
    String? gender,
    bool? remindEnabled,
    int? remindInterval,
    int? remindMaxTimes,
    List<Map<String, String>>? remindAvoidTime,
  }) async {
    try {
      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        print('No user ID found');
        return false;
      }

      // 构建更新数据
      final Map<String, dynamic> updateData = {};

      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (password != null && password.isNotEmpty) updateData['password'] = password;
      if (height != null) updateData['height'] = height;
      if (weight != null) updateData['weight'] = weight;
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (remindEnabled != null) updateData['remindEnabled'] = remindEnabled ? 1 : 0;
      if (remindInterval != null) updateData['remindInterval'] = remindInterval;
      if (remindMaxTimes != null) updateData['remindMaxTimes'] = remindMaxTimes;
      if (remindAvoidTime != null) updateData['remindAvoidTime'] = remindAvoidTime;

      // 构建完整的URL，包含userId参数
      final endpoint = '/user/update?userId=$userId';
      final response = await _apiService.post(endpoint, updateData);

      if (response != null && response['code'] == 200) {
        return true;
      } else {
        print('Update user info failed: ${response?['message']}');
        return false;
      }
    } catch (e) {
      print('Update user info error: $e');
      return false;
    }
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
      // 尝试从本地存储获取用户ID
      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        // 如果没有保存的用户ID，尝试从token解析或使用默认值
        // 这里简化处理，实际应该解析JWT token获取用户ID
        return null;
      }
      
      final response = await _apiService.get('/user/info', params: {'userId': userId});

      if (response != null && response['code'] == 200) {
        final user = response['data'];
        // 使用新的fromJson方法创建UserModel，包含所有字段
        return UserModel.fromJson({
          ...user,
          'token': token,
        });
      }
      return null;
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }
}

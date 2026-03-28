// lib/services/api_service.dart
// API服务类
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  // 根据运行环境自动选择后端地址
  static String get baseUrl {
    if (kIsWeb) {
      // 浏览器调试
      return 'http://10.27.246.204:8080/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android 模拟器访问宿主机
        return 'http://10.27.246.204:8080/api';
      case TargetPlatform.iOS:
        // iOS 模拟器一般直接用 localhost
        return 'http://10.27.246.204:8080/api';
      default:
        // Windows / macOS / Linux 桌面
        return 'http://10.27.246.204:8080/api';
    }
  }

  // 登录专用的post方法 - 不包含任何token
  Future<Map<String, dynamic>?> postForLogin(String endpoint, Map<String, dynamic> data) async {
    try {
      // 登录请求使用特殊headers - 绝对不包含Authorization
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

      print('=== DEBUG: Making LOGIN POST request to: $baseUrl$endpoint');
      print('=== DEBUG: Headers: $headers');
      print('=== DEBUG: Body: $data');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      print('=== DEBUG: Response status: ${response.statusCode}');
      print('=== DEBUG: Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        // 强制按 UTF-8 解码，避免因服务端未声明 charset 导致的乱码
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        print('=== DEBUG: Decoded response: $decodedResponse');
        return decodedResponse;
      } else {
        print('=== ERROR: API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('=== ERROR: Network Error: $e');
      return null;
    }
  }

  // 普通post方法 - 包含token
  Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await StorageService.getToken();

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

      // 只有登录和注册接口不添加token
      final isAuthEndpoint = endpoint.contains('/login') || endpoint.contains('/register');
      if (token != null && !isAuthEndpoint) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('=== DEBUG: Making POST request to: $baseUrl$endpoint');
      print('=== DEBUG: Headers: $headers');
      print('=== DEBUG: Body: $data');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      print('=== DEBUG: Response status: ${response.statusCode}');
      print('=== DEBUG: Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        print('=== DEBUG: Decoded response: $decodedResponse');
        return decodedResponse;
      } else {
        print('=== ERROR: API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('=== ERROR: Network Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> get(String endpoint, {Map<String, String>? params}) async {
    try {
      final token = await StorageService.getToken();

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

      // 只有登录和注册接口不添加token
      final isAuthEndpoint = endpoint.contains('/login') || endpoint.contains('/register');
      if (token != null && !isAuthEndpoint) {
        headers['Authorization'] = 'Bearer $token';
      }

      // 构建带参数的 URL
      String url = '$baseUrl$endpoint';
      if (params != null && params.isNotEmpty) {
        url += '?${_buildQueryString(params)}';
      }

      print('=== DEBUG: Making GET request to: $url');
      print('=== DEBUG: Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('=== DEBUG: Response status: ${response.statusCode}');
      print('=== DEBUG: Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        print('=== DEBUG: Decoded response: $decodedResponse');
        return decodedResponse;
      } else {
        print('=== ERROR: API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('=== ERROR: Network Error: $e');
      return null;
    }
  }

  // 辅助方法：构建查询字符串
  String _buildQueryString(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

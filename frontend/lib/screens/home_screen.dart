// lib/screens/home_screen.dart
// 主页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';  // 添加导入
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {  // 检查widget是否仍然挂载
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('跬步千里'),
        actions: [
          if (_currentUser != null)
            IconButton(
              onPressed: () async {
                await _authService.logout();
                if (mounted) {
                  context.go('/login');  // 使用GoRouter的导航方式
                }
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_walk,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                '微运动健康管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentUser != null
                  ? '欢迎，${_currentUser!.username}'
                  : '请先登录',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_currentUser != null)
                ElevatedButton(
                  onPressed: () {
                    // 这里可以导航到运动页面
                  },
                  child: const Text('开始运动'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.go('/login');  // 使用GoRouter的导航方式
                  },
                  child: const Text('前往登录'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

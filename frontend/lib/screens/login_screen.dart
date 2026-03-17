// lib/screens/login_screen.dart
// 登录页面
import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _usernameController,
                labelText: '用户名',
                validator: Validators.validateUsername,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: '密码',
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(
                text: '登录',
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go('/register');
                },
                child: const Text('还没有账号？点击注册'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/preview/body_model');
                },
                icon: const Icon(Icons.view_in_ar_outlined),
                label: const Text('免登录测试 3D 身体模型'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 登录并获取完整的用户模型
        final userModel = await _authService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (userModel != null && mounted) {
          // 判断用户是否已填写问卷
          // 根据返回的UserModel判断：如果有身高、体重、年龄等基本信息，说明已填写问卷
          bool hasCompletedSurvey =
              userModel.height != null &&
                  userModel.weight != null &&
                  userModel.age != null;

          // 或者更严格的条件：检查是否有完整的用户信息
          // bool hasCompletedSurvey =
          //     userModel.height != null &&
          //     userModel.weight != null &&
          //     userModel.age != null &&
          //     userModel.gender != null;

          print('=== 用户问卷状态检查 ===');
          print('用户ID: ${userModel.id}');
          print('用户名: ${userModel.username}');
          print('身高: ${userModel.height}');
          print('体重: ${userModel.weight}');
          print('年龄: ${userModel.age}');
          print('性别: ${userModel.gender}');
          print('是否已完成问卷: $hasCompletedSurvey');
          print('======================');

          if (hasCompletedSurvey) {
            // 用户已填写问卷，标记本地状态并跳转到主界面
            await StorageService.markOnboardingCompleted();

            if (mounted) {
              context.go('/app_screen');
            }
          } else {
            // 用户未填写问卷，确保本地状态为false并跳转到问卷页面
            await StorageService.clearOnboardingStatus();

            if (mounted) {
              context.go('/onboarding_survey');
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登录失败，请检查用户名和密码')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
// lib/screens/login_screen.dart
// 登录页面
import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('登录'),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '欢迎回来',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '登录您的账号',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
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
                        icon: const Icon(Icons.view_in_ar_outlined, size: 18),
                        label: const Text('免登录测试 3D 身体模型'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
        final userModel = await _authService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (userModel != null && mounted) {
          bool hasCompletedSurvey =
              userModel.height != null &&
                  userModel.weight != null &&
                  userModel.age != null;
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

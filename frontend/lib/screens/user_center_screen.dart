// 用户中心页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserCenterScreen extends StatefulWidget {
  const UserCenterScreen({super.key});

  @override
  State<UserCenterScreen> createState() => _UserCenterScreenState();
}

class _UserCenterScreenState extends State<UserCenterScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  late TabController _tabController;
  int _selectedTabIndex = -1; // 使用单独的变量跟踪选中状态

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面重新显示时，重置选项卡选中状态
    setState(() {
      _selectedTabIndex = -1;
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户中心'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // 用户信息卡片
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentUser?.username ?? '未登录用户',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser?.email ?? '请先登录',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // 三个选项卡
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[100],
              child: Column(
                children: [
                  _buildVerticalTab('用户信息', 0),
                  _buildVerticalTab('运动偏好', 1),
                  _buildVerticalTab('历史记录', 2),
                  const Spacer(),
                  // 退出登录按钮
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutConfirmation,
                        icon: const Icon(Icons.logout),
                        label: const Text('退出登录'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildVerticalTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0) {
          // 用户信息选项卡 - 跳转到详情页面
          context.push('/user_info');
        } else if (index == 1) {
          // 运动偏好选项卡 - 跳转到偏好设置页面
          context.push('/preference');
        } else {
          // 历史记录选项卡 - 更新选中状态
          setState(() {
            _selectedTabIndex = index;
          });
          _tabController.animateTo(index);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.grey[600]! : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 20),
            Icon(
              _getTabIcon(index),
              color: Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.grey[700],
              ),
            ),
            if (index == 0 || index == 1) const Spacer(),
            if (index == 0 || index == 1) const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.person;
      case 1:
        return Icons.settings;
      case 2:
        return Icons.history;
      default:
        return Icons.info;
    }
  }

  // 显示退出登录确认对话框
  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出登录'),
        content: const Text('您确定要退出登录吗？退出后将返回登录界面。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _performLogout();
    }
  }

  // 执行退出登录操作
  Future<void> _performLogout() async {
    try {
      await _authService.logout();
      
      // 清除当前用户状态
      if (mounted) {
        setState(() {
          _currentUser = null;
        });
      }
      
      // 导航回登录界面
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      // 如果退出登录失败，显示错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退出登录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}
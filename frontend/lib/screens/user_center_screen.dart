// 用户中心页面
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserCenterScreen extends StatefulWidget {
  const UserCenterScreen({super.key});

  @override
  State<UserCenterScreen> createState() => _UserCenterScreenState();
}

class _UserCenterScreenState extends State<UserCenterScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  UserModel? _currentUser;
  late TabController _tabController;
  int _selectedTabIndex = -1;
  bool _isUploading = false;

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

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      String uploadUrl = '${ApiService.baseUrl}/file/avatar';
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      final mimeType = _getMimeType(image.path);
      final bytes = await image.readAsBytes();
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
        contentType: MediaType.parse(mimeType),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['code'] == 200) {
          String avatarUrl = data['data'];

          final userId = _currentUser?.id;
          if (userId != null) {
            final updateResponse = await _apiService.post(
              '/user/avatar?userId=$userId',
              {'avatarUrl': avatarUrl},
            );

            if (updateResponse != null && updateResponse['code'] == 200) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('头像上传成功')),
                );
              }
              await _loadCurrentUser();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('头像保存失败')),
                );
              }
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? '上传失败')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('头像上传失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _getAvatarUrl() {
    final avatarUrl = _currentUser?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return avatarUrl;
      }
      // 处理各种格式的URL
      String path = avatarUrl;
      // 移除开头的 /api/ 或 /api 前缀
      if (path.startsWith('/api/')) {
        path = path.substring(4);
      } else if (path.startsWith('/api')) {
        path = path.substring(4);
      }
      // 确保以 / 开头
      if (!path.startsWith('/')) {
        path = '/' + path;
      }
      return 'http://localhost:8080/api$path';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _getAvatarUrl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户中心'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: avatarUrl.isNotEmpty 
                            ? NetworkImage(avatarUrl) 
                            : null,
                        child: avatarUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.blue.shade600,
                              )
                            : null,
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
// 用户信息详情页面
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/sedentary_reminder_service.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  // 表单数据
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  double _height = 0;
  double _weight = 0;
  int _age = 0;
  String _gender = '男';
  bool _remindEnabled = true;
  int _remindInterval = 30;
  int _remindMaxTimes = 3;
  List<Map<String, String>> _avoidTimes = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      // 使用真实用户数据初始化表单
      _username = user?.username ?? '';
      _email = user?.email ?? '';
      _phone = user?.phone ?? '';

      // 身高、体重、年龄：如果为0或null，使用默认值
      _height = user?.height ?? 0;
      if (_height <= 0) _height = 160.0;

      _weight = user?.weight ?? 0;
      if (_weight <= 0) _weight = 50.0;

      _age = user?.age ?? 0;
      if (_age <= 0) _age = 16;

      _gender = user?.gender ?? '男';

      // 初始化提醒设置：使用remindEnabled字段
      _remindEnabled = user?.remindEnabled ?? true;
      _remindInterval = user?.remindInterval ?? 30;
      _remindMaxTimes = user?.remindMaxTimes ?? 3;
      // 初始化免打扰时间段
      if (user?.remindAvoidTime != null && user!.remindAvoidTime!.isNotEmpty) {
        _avoidTimes = List.from(user.remindAvoidTime!);
      }
    });
  }

  void _addAvoidTime() {
    setState(() {
      _avoidTimes.add({'start': '12:00', 'end': '14:00'});
    });
  }

  void _removeAvoidTime(int index) {
    setState(() {
      _avoidTimes.removeAt(index);
    });
  }

  void _updateAvoidTime(int index, String field, String value) {
    setState(() {
      _avoidTimes[index][field] = value;
    });
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 显示加载指示器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在保存用户信息...')),
      );

      try {
        // 调用后端API保存数据
        final success = await _authService.updateUserInfo(
          username: _username,
          email: _email,
          phone: _phone,
          password: _password.isNotEmpty ? _password : null,
          height: _height > 0 ? _height : null,
          weight: _weight > 0 ? _weight : null,
          age: _age > 0 ? _age : null,
          gender: _gender,
          remindEnabled: _remindEnabled,
          remindInterval: _remindEnabled ? _remindInterval : null,
          remindMaxTimes: _remindEnabled ? _remindMaxTimes : null,
          remindAvoidTime: _remindEnabled ? _avoidTimes : null,
        );

        if (success) {
          // 保存成功，重新加载用户数据
          await _loadCurrentUser();
          await SedentaryReminderService.instance.refreshConfig();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('用户信息已保存成功')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请重试')),
          );
        }
      } catch (e) {
        print('Save user info error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存出错: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '用户信息',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () async {
                await _saveUserInfo();
              },
              icon: const Icon(Icons.save),
              tooltip: '保存',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 页面说明
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '完善您的个人信息，获取更精准的运动推荐',
                              style: TextStyle(color: Colors.blue.shade700, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 基本信息
                    _buildSectionTitle('基本信息', Icons.person_outline),
                    _buildTextField(
                      label: '用户名',
                      initialValue: _username,
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入用户名';
                        }
                        return null;
                      },
                      onSaved: (value) => _username = value!,
                    ),
                    _buildTextField(
                      label: '邮箱',
                      initialValue: _email,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!value.contains('@')) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                      onSaved: (value) => _email = value!,
                    ),
                    _buildTextField(
                      label: '电话（可选）',
                      initialValue: _phone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 11) {
                            return '请输入11位手机号码（或留空）';
                          }
                        }
                        return null;
                      },
                      onSaved: (value) => _phone = value ?? '',
                    ),
                    _buildTextField(
                      label: '密码',
                      initialValue: '',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      hintText: '留空表示不修改',
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return '密码至少6位';
                        }
                        return null;
                      },
                      onSaved: (value) => _password = value ?? '',
                    ),

                    const SizedBox(height: 24),

                    // 健康信息
                    _buildSectionTitle('健康信息', Icons.health_and_safety_outlined),

                    // 身高滑动条
                    _buildSliderField(
                      label: '身高',
                      value: _height,
                      min: 100,
                      max: 220,
                      unit: 'cm',
                      onChanged: (value) => setState(() => _height = value),
                    ),

                    const SizedBox(height: 16),

                    // 体重滑动条
                    _buildSliderField(
                      label: '体重',
                      value: _weight,
                      min: 30,
                      max: 150,
                      unit: 'kg',
                      divisions: 240, // 30-150, 0.5kg步进
                      onChanged: (value) => setState(() => _weight = value),
                    ),

                    const SizedBox(height: 16),

                    // 年龄滑动条
                    _buildSliderField(
                      label: '年龄',
                      value: _age.toDouble(),
                      min: 1,
                      max: 100,
                      unit: '岁',
                      divisions: 99,
                      onChanged: (value) => setState(() => _age = value.toInt()),
                    ),

                    const SizedBox(height: 16),

                    // 性别选择
                    _buildGenderSelector(),

                    const SizedBox(height: 24),

                    // 提醒设置
                    _buildSectionTitle('提醒设置', Icons.notifications_outlined),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SwitchListTile(
                        title: const Text('启用提醒'),
                        subtitle: const Text('开启后将在久坐时收到运动提醒'),
                        value: _remindEnabled,
                        activeColor: Colors.blue,
                        onChanged: (value) => setState(() => _remindEnabled = value),
                      ),
                    ),

                    if (_remindEnabled) ...[
                      const SizedBox(height: 16),

                      // 提醒间隔滑动条
                      _buildSliderField(
                        label: '提醒间隔',
                        value: _remindInterval.toDouble(),
                        min: 5,
                        max: 120,
                        unit: '分钟',
                        divisions: 115,
                        onChanged: (value) => setState(() => _remindInterval = value.toInt()),
                      ),
                      const SizedBox(height: 12),
                      _buildNumberField(
                        label: '每日最大提醒次数',
                        value: _remindMaxTimes.toDouble(),
                        min: 1,
                        max: 10,
                        onChanged: (value) => setState(() => _remindMaxTimes = value.toInt()),
                      ),
                      const SizedBox(height: 16),

                      _buildAvoidTimesSection(),
                    ],

                    const SizedBox(height: 32),

                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveUserInfo();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          '保存用户信息',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.blue.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    int? divisions,
    required void Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions ?? (max - min).toInt(),
            activeColor: Colors.blue,
            inactiveColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min $unit',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '$max $unit',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required double min,
    required double max,
    required void Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: Colors.blue,
            inactiveColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toInt().toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                max.toInt().toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '性别',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('男'),
                  selected: _gender == '男',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _gender = '男');
                    }
                  },
                  selectedColor: Colors.blue.shade100,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _gender == '男' ? Colors.blue.shade700 : Colors.grey.shade700,
                    fontWeight: _gender == '男' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('女'),
                  selected: _gender == '女',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _gender = '女');
                    }
                  },
                  selectedColor: Colors.pink.shade100,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _gender == '女' ? Colors.pink.shade700 : Colors.grey.shade700,
                    fontWeight: _gender == '女' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvoidTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '免打扰时间段',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _addAvoidTime,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.blue,
              tooltip: '添加时间段',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._avoidTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      label: '开始时间',
                      value: time['start']!,
                      onChanged: (value) => _updateAvoidTime(index, 'start', value),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  ),
                  Expanded(
                    child: _buildTimePicker(
                      label: '结束时间',
                      value: time['end']!,
                      onChanged: (value) => _updateAvoidTime(index, 'end', value),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeAvoidTime(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: '删除',
                  ),
                ],
              ),
            ),
          );
        }),
        if (_avoidTimes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_off_outlined, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    '暂无免打扰时间段',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = value.split(':');
            final initialTime = TimeOfDay(
              hour: int.parse(time[0]),
              minute: int.parse(time[1]),
            );

            final selectedTime = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );

            if (selectedTime != null) {
              final formattedTime =
                  '${selectedTime.hour.toString().padLeft(2, '0')}:'
                  '${selectedTime.minute.toString().padLeft(2, '0')}';
              onChanged(formattedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 用户信息详情页面
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

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
  List<Map<String, String>> _avoidTimes = [
    {'start': '22:00', 'end': '08:00'}
  ];

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
      // 注意：user?.remindEnabled 已经是布尔值（来自UserModel.fromJson的解析）
      _remindEnabled = user?.remindEnabled ?? true;
      _remindInterval = user?.remindInterval ?? 30;

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
          remindAvoidTime: _remindEnabled ? _avoidTimes : null,
        );

        if (success) {
          // 保存成功，重新加载用户数据
          await _loadCurrentUser();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('用户信息已保存成功')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请重试')),
          );
        }
      } catch (e) {
        print('Save user info error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存出错: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户信息'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () async {
              await _saveUserInfo();
            },
            icon: const Icon(Icons.save),
            tooltip: '保存',
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本信息
              _buildSectionTitle('基本信息'),
              _buildTextField(
                label: '用户名',
                initialValue: _username,
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
                keyboardType: TextInputType.phone,
                validator: (value) {
                  // 电话为可选字段，可以为空
                  if (value != null && value.isNotEmpty) {
                    // 如果用户输入了电话，则验证格式
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
              _buildSectionTitle('健康信息'),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      label: '身高 (cm)',
                      value: _height > 0 ? _height : 160.0,
                      min: 50,
                      max: 250,
                      onChanged: (value) => setState(() => _height = value),
                      isInt: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      label: '体重 (kg)',
                      value: _weight > 0 ? _weight : 50.0,
                      min: 20,
                      max: 200,
                      onChanged: (value) => setState(() => _weight = value),
                      isInt: false, // 体重支持0.5kg增量
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      label: '年龄',
                      value: _age > 0 ? _age.toDouble() : 16.0,
                      min: 16,
                      max: 120,
                      onChanged: (value) => setState(() => _age = value.toInt()),
                      isInt: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderSelector(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 提醒设置
              _buildSectionTitle('提醒设置'),
              SwitchListTile(
                title: const Text('启用提醒'),
                value: _remindEnabled,
                onChanged: (value) => setState(() => _remindEnabled = value),
              ),
              if (_remindEnabled) ...[
                const SizedBox(height: 8),
                _buildNumberField(
                  label: '提醒间隔 (分钟)',
                  value: _remindInterval.toDouble(),
                  min: 5,
                  max: 240,
                  onChanged: (value) => setState(() => _remindInterval = value.toInt()),
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
                  ),
                  child: const Text('保存用户信息'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
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
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required double min,
    required double max,
    required void Function(double) onChanged,
    bool isInt = true,
  }) {
    // 生成选项列表
    final List<double> options = [];
    for (double i = min; i <= max; i += (isInt ? 1 : 0.5)) {
      options.add(i);
    }

    final int selectedIndex = options.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: CupertinoPicker(
            itemExtent: 40,
            scrollController: FixedExtentScrollController(
              initialItem: selectedIndex >= 0 ? selectedIndex : 0,
            ),
            onSelectedItemChanged: (index) {
              onChanged(options[index]);
            },
            children: options.map((option) {
              return Center(
                child: Text(
                  isInt ? option.toInt().toString() : option.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 20),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '当前选择: ${isInt ? value.toInt() : value.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性别',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
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
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('女'),
                selected: _gender == '女',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _gender = '女');
                  }
                },
              ),
            ),
          ],
        ),
      ],
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
              icon: const Icon(Icons.add),
              tooltip: '添加时间段',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._avoidTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
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
                    child: Text('至'),
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
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: '删除',
                  ),
                ],
              ),
            ),
          );
        }),
        if (_avoidTimes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '暂无免打扰时间段',
                style: TextStyle(color: Colors.grey),
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.access_time, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
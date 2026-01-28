// 表单验证工具
// 表单验证工具
class Validators {
  /// 验证用户名
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入用户名';
    }
    if (value.length < 3) {
      return '用户名长度至少3位';
    }
    if (value.length > 20) {
      return '用户名长度不能超过20位';
    }
    // 只允许字母、数字和下划线
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return '用户名只能包含字母、数字和下划线';
    }
    return null;
  }

  /// 验证密码
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码长度至少6位';
    }
    // 密码至少包含一个字母和一个数字
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]').hasMatch(value)) {
      return '密码至少包含一个字母和一个数字';
    }
    return null;
  }

  /// 验证邮箱
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  /// 验证确认密码
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }
    if (value != originalPassword) {
      return '两次输入的密码不一致';
    }
    return null;
  }
}

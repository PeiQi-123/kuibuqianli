// 用户模型类
class UserModel {
  final String? id;
  final String username;
  final String email;
  final String? token;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'token': token,
    };
  }
}

// 用户模型类
import 'dart:convert';

class UserModel {
  final String? id;
  final String username;
  final String email;
  final String? token;
  final String? phone;
  final double? height;
  final double? weight;
  final double? bmi;
  final String? bmiType;
  final int? age;
  final String? gender;
  final bool? remindEnabled;
  final int? remindInterval;
  final int? remindMaxTimes;
  final List<Map<String, String>>? remindAvoidTime;
  final String? avatarUrl;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    this.token,
    this.phone,
    this.height,
    this.weight,
    this.bmi,
    this.bmiType,
    this.age,
    this.gender,
    this.remindEnabled,
    this.remindInterval,
    this.remindMaxTimes,
    this.remindAvoidTime,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 解析免打扰时间段
    List<Map<String, String>>? avoidTime;
    if (json['remind_avoid_time'] != null) {
      try {
        final avoidTimeJson = json['remind_avoid_time'];
        if (avoidTimeJson is String) {
          // 如果是JSON字符串，解析它
          final parsed = jsonDecode(avoidTimeJson);
          if (parsed is List) {
            avoidTime = List<Map<String, String>>.from(
              parsed.map((item) => Map<String, String>.from(item)),
            );
          }
        } else if (avoidTimeJson is List) {
          avoidTime = List<Map<String, String>>.from(
            avoidTimeJson.map((item) => Map<String, String>.from(item)),
          );
        }
      } catch (e) {
        avoidTime = null;
      }
    }

    return UserModel(
      id: json['id']?.toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      phone: json['phone'],
      height: json['height'] != null ? double.tryParse(json['height'].toString()) : null,
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      bmi: json['bmi'] != null ? double.tryParse(json['bmi'].toString()) : null,
      bmiType: json['bmiType'] ?? json['bmi_type'],
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender'],
      remindEnabled: (json['remindEnabled'] ?? json['remind_enabled']) != null ? 
          ((json['remindEnabled'] ?? json['remind_enabled']) is bool ? 
            (json['remindEnabled'] ?? json['remind_enabled']) : 
            (json['remindEnabled'] ?? json['remind_enabled']) == 1 || (json['remindEnabled'] ?? json['remind_enabled']) == true) : null,
      remindInterval: (json['remindInterval'] ?? json['remind_interval']) != null ? int.tryParse((json['remindInterval'] ?? json['remind_interval']).toString()) : null,
      remindMaxTimes: (json['remindMaxTimes'] ?? json['remind_max_times']) != null ? int.tryParse((json['remindMaxTimes'] ?? json['remind_max_times']).toString()) : null,
      remindAvoidTime: avoidTime,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'token': token,
      'phone': phone,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'bmi_type': bmiType,
      'age': age,
      'gender': gender,
      'remindEnabled': remindEnabled,
      'remindInterval': remindInterval,
      'remindMaxTimes': remindMaxTimes,
      'remindAvoidTime': remindAvoidTime,
      'avatarUrl': avatarUrl,
    };
  }
}

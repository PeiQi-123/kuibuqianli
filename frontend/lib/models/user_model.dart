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
      bmiType: json['bmi_type'],
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender'],
      remindEnabled: json['remind_enabled'] != null ? (json['remind_enabled'] is bool ? json['remind_enabled'] : json['remind_enabled'] == 1 || json['remind_enabled'] == true) : null,
      remindInterval: json['remind_interval'] != null ? int.tryParse(json['remind_interval'].toString()) : null,
      remindMaxTimes: json['remind_max_times'] != null ? int.tryParse(json['remind_max_times'].toString()) : null,
      remindAvoidTime: avoidTime,
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
      'remind_enabled': remindEnabled,
      'remind_interval': remindInterval,
      'remind_max_times': remindMaxTimes,
      'remind_avoid_time': remindAvoidTime,
    };
  }
}

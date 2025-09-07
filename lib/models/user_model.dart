import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String password;

  @HiveField(3)
  String email;

  @HiveField(4)
  String fullName;

  @HiveField(5)
  String mobile;

  @HiveField(6)
  String position;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.mobile,
    required this.position,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      mobile: json['mobile'] as String,
      position: json['position'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'fullName': fullName,
      'mobile': mobile,
      'position': position,
    };
  }
}

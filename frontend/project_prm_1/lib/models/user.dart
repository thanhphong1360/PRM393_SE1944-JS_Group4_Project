
class User {
  final int userId;
  final String? fullName;
  final String email;
  final String role;

  User({
    required this.userId,
    this.fullName,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
    };
  }
}

class Attendee {
  final int userId;
  final String fullName;
  final String email;
  final bool isActive;

  Attendee({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.isActive,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'is_active': isActive,
    };
  }
}
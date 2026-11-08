import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Có thể điền IP thủ công nếu test trên điện thoại thật (VD: 'http://192.168.1.15:8081/ConferenceAPI')
  static String customBaseUrl = '';

  /// Tự động nhận diện môi trường:
  /// - Web / Trình duyệt Chrome / Cốc Cốc: Dùng http://localhost:8081/ConferenceAPI
  /// - Máy ảo Android (Android Emulator): Dùng http://10.0.2.2:8081/ConferenceAPI
  /// - Windows / macOS / Linux Desktop: Dùng http://localhost:8081/ConferenceAPI
  static String get baseUrl {
    if (customBaseUrl.trim().isNotEmpty) {
      return customBaseUrl.trim();
    }

    if (kIsWeb) {
      return 'http://localhost:8081/ConferenceAPI';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081/ConferenceAPI';
    }

    return 'http://localhost:8081/ConferenceAPI';
  }

  // Authentication
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';

  // User
  static String get me => '$baseUrl/api/me';

  // Conferences
  static String get conferences => '$baseUrl/api/conferences';

  // Attendee
  static String get myRegistrations => '$baseUrl/api/my-registrations';

  // Admin
  static String get adminConferences => '$baseUrl/api/admin/conferences';
  static String get adminAttendees => '$baseUrl/api/admin/attendees';

  // Staff
  static String get staffCheckIn => '$baseUrl/api/staff/check-in';

  // Register conference
  static String get registerConference => '$baseUrl/api/register-conference';
}

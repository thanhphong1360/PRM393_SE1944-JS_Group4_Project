
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

  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';
  static const String me = '$baseUrl/api/me';

  static const String conferences = '$baseUrl/api/conferences';

  static const String myRegistrations = '$baseUrl/api/my-registrations';

  static const String adminConferences =
      '$baseUrl/api/admin/conferences';
  static const String adminAttendees =
      '$baseUrl/api/admin/attendees';

  static const String staffCheckIn =
      '$baseUrl/api/staff/check-in';

  static const String registerConference =
      '$baseUrl/api/register-conference';
}

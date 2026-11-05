class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080/ConferenceAPI';

  // Authentication
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';

  // User
  static const String me = '$baseUrl/api/me';

  // Conferences
  static const String conferences = '$baseUrl/api/conferences';

  // Attendee
  static const String myRegistrations =
      '$baseUrl/api/my-registrations';

  // Admin
  static const String adminConferences =
      '$baseUrl/api/admin/conferences';

  static const String adminAttendees =
      '$baseUrl/api/admin/attendees';

  // Staff
  static const String staffCheckIn =
      '$baseUrl/api/staff/check-in';
}
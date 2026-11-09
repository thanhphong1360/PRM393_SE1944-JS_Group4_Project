
class ApiConfig {
  static const String baseUrl =
      'http://10.0.2.2:8080/ConferenceAPI';

  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';
  static const String me = '$baseUrl/api/me';

  static const String conferences = '$baseUrl/api/conferences';

  static const String myRegistrations =
      '$baseUrl/api/my-registrations';

  static const String adminConferences =
      '$baseUrl/api/admin/conferences';

  static const String adminAttendees =
      '$baseUrl/api/admin/attendees';

  static const String staffValidateTicket =
      '$baseUrl/api/staff/validate-ticket';

  static const String staffCheckIn =
      '$baseUrl/api/staff/check-in';

  static const String registerConference =
      '$baseUrl/api/register-conference';
}


import '../../models/attendee.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class AttendeeService {
  // Get all attendees or search by name/email
  static Future<List<Attendee>> getAttendees({
    String? search,
  }) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in as Admin.');
    }

    // Build API URL
    final uri = Uri.parse(ApiConfig.adminAttendees);

    final query = search?.trim();

    final requestUri = query != null && query.isNotEmpty
        ? uri.replace(
      queryParameters: {'search': query},
    )
        : uri;

    // Call API
    final response = await ApiService.get(
      requestUri.toString(),
      token: token,
    );

    // Parse attendees
    final attendees = response['attendees'];

    if (attendees is! List) {
      throw Exception('Invalid attendee data from API.');
    }

    return attendees.map((item) {
      return Attendee.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }
}

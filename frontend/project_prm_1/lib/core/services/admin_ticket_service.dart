
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class AdminTicketService {
  // Issue a ticket to an attendee
  static Future<Map<String, dynamic>> issueTicket({
    required int conferenceId,
    required int attendeeId,
  }) async {
    final token = await _getAdminToken();

    return await ApiService.post(
      '${ApiConfig.baseUrl}/api/admin/issue-ticket/$conferenceId',
      token: token,
      body: {
        'attendee_id': attendeeId,
      },
    );
  }

  // Revoke an existing ticket
  static Future<Map<String, dynamic>> revokeTicket({
    required String ticketId,
  }) async {
    final token = await _getAdminToken();

    return await ApiService.post(
      '${ApiConfig.baseUrl}/api/admin/revoke-ticket/$ticketId',
      token: token,
    );
  }

  // Get Admin JWT token
  static Future<String> _getAdminToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in as Admin.');
    }

    return token;
  }
}

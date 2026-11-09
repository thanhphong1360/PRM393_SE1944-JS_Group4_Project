import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class StaffCheckInService {
  static Future<Map<String, dynamic>> validateTicket({
    required String ticketId,
    required int conferenceId,
  }) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found. Please log in again.',
      );
    }

    final response = await ApiService.post(
      ApiConfig.staffValidateTicket,
      token: token,
      body: {
        'ticket_id': ticketId,
        'conference_id': conferenceId,
      },
    );

    return response;
  }

  static Future<Map<String, dynamic>> checkIn({
    required String ticketId,
    required int conferenceId,
  }) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found. Please log in again.',
      );
    }

    final response = await ApiService.post(
      ApiConfig.staffCheckIn,
      token: token,
      body: {
        'ticket_id': ticketId,
        'conference_id': conferenceId,
      },
    );

    return response;
  }
}
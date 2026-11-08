
import '../../models/ticket.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class RegistrationService {
  // Register for a conference
  static Future<Map<String, dynamic>> registerConference(
      int conferenceId,
      ) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in to register.');
    }

    return await ApiService.post(
      '${ApiConfig.registerConference}/$conferenceId',
      token: token,
    );
  }

  // Get current user's registrations
  static Future<List<Ticket>> getMyRegistrations() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in to view registrations.');
    }

    final response = await ApiService.get(
      ApiConfig.myRegistrations,
      token: token,
    );

    final registrations = response['registrations'] as List<dynamic>;

    return registrations.map((item) {
      return Ticket.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  // Get details of a specific ticket
  static Future<Ticket> getTicketDetail(String ticketId) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in to view ticket details.');
    }

    final response = await ApiService.get(
      '${ApiConfig.myRegistrations}/$ticketId',
      token: token,
    );

    return Ticket.fromJson(response);
  }

  // Cancel a valid registration
  static Future<Map<String, dynamic>> cancelRegistration(
      String ticketId,
      ) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in to cancel registration.');
    }

    return await ApiService.delete(
      '${ApiConfig.myRegistrations}/$ticketId',
      token: token,
    );
  }
}

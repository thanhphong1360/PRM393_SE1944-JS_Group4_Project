
import '../../models/conference.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class ConferenceService {
  // Get public conference list
  static Future<List<Conference>> getConferences() async {
    final data = await ApiService.getList(
      ApiConfig.conferences,
    );

    return data.map((item) {
      return Conference.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  // Get public conference detail
  static Future<Conference> getConferenceDetail(int id) async {
    final response = await ApiService.get(
      '${ApiConfig.conferences}/$id',
    );

    return Conference.fromJson(response);
  }

  // Get all conferences for Admin, including Cancelled
  static Future<List<Conference>> getAdminConferences() async {
    final token = await _getAdminToken();

    final data = await ApiService.getList(
      '${ApiConfig.adminConferences}/all',
      token: token,
    );

    return data.map((item) {
      return Conference.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  // Create a new conference
  static Future<Map<String, dynamic>> createConference({
    required String title,
    required String location,
    required DateTime startDate,
    String? description,
    required String registrationPolicy,
  }) async {
    final token = await _getAdminToken();

    return await ApiService.post(
      ApiConfig.adminConferences,
      token: token,
      body: {
        'title': title,
        'location': location,
        'start_date': _formatDate(startDate),
        'description': description,
        'registration_policy': registrationPolicy,
      },
    );
  }

  // Update an existing conference
  static Future<Map<String, dynamic>> updateConference({
    required int conferenceId,
    required String title,
    required String location,
    required DateTime startDate,
    String? description,
    required String registrationPolicy,
  }) async {
    final token = await _getAdminToken();

    return await ApiService.put(
      '${ApiConfig.adminConferences}/$conferenceId',
      token: token,
      body: {
        'title': title,
        'location': location,
        'start_date': _formatDate(startDate),
        'description': description,
        'registration_policy': registrationPolicy,
      },
    );
  }

  // Cancel a conference (soft delete)
  static Future<Map<String, dynamic>> cancelConference(
      int conferenceId,
      ) async {
    final token = await _getAdminToken();

    return await ApiService.delete(
      '${ApiConfig.adminConferences}/$conferenceId',
      token: token,
    );
  }

  // Get JWT token
  static Future<String> _getAdminToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in as Admin.');
    }

    return token;
  }

  // Format DateTime as yyyy-MM-dd
  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

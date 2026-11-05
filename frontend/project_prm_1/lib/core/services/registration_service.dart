
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class RegistrationService {
  static Future<Map<String, dynamic>> registerConference(
      int conferenceId,
      ) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You must log in to register.');
    }

    final response = await ApiService.post(
      '${ApiConfig.conferences}/../register-conference/$conferenceId',
      token: token,
    );

    return response;
  }
}

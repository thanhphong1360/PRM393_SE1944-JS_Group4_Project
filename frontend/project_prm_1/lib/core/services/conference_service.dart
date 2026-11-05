
import '../../models/conference.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ConferenceService {
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

  static Future<Conference> getConferenceDetail(int id) async {
    final response = await ApiService.get(
      '${ApiConfig.conferences}/$id',
    );

    return Conference.fromJson(response);
  }

}

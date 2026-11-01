
import 'dart:convert';

import 'package:http/http.dart' as http;

class ConferenceService {
  static const String _baseUrl =
      'http://10.0.2.2:8080/ConferenceAPI/api/conference';

  Future<List<dynamic>> fetchConferences() async {
    final uri = Uri.parse(_baseUrl);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data =
      jsonDecode(response.body) as List<dynamic>;

      return data;
    } else {
      throw Exception(
        'Failed to load conferences: HTTP ${response.statusCode}',
      );
    }
  }
}

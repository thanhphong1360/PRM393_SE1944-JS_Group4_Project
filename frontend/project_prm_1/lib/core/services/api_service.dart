import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> get(
      String url, {
        String? token,
      }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
      String url, {
        Map<String, dynamic>? body,
        String? token,
      }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
      String url, {
        Map<String, dynamic>? body,
        String? token,
      }) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(
      String url, {
        String? token,
      }) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );

    return _handleResponse(response);
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _handleResponse(
      http.Response response,
      ) {
    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Request failed: ${response.statusCode}',
    );
  }
}
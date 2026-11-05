import '../../models/user.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class AuthService {
  // Login
  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    final token = response['access_token'];

    if (token == null || token.toString().isEmpty) {
      throw Exception('Login response does not contain access_token');
    }

    await TokenStorage.saveToken(token.toString());

    return User.fromJson(
      Map<String, dynamic>.from(response['user']),
    );
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return await ApiService.post(
      ApiConfig.register,
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
      },
    );
  }

  // Get current user
  static Future<User> getCurrentUser() async {
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('User is not logged in');
    }

    final response = await ApiService.get(
      ApiConfig.me,
      token: token,
    );

    final userData = response['user'] ?? response;

    return User.fromJson(
      Map<String, dynamic>.from(userData),
    );
  }

  // Logout
  static Future<void> logout() async {
    await TokenStorage.removeToken();
  }
}
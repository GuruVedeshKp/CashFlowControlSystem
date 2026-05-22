import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  Future<bool> login(String phone, String password) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/login',
        data: {'phone': phone, 'password': password},
      );

      final token = response.data['data']['token'];

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', token);

      ApiService.dio.options.headers['Authorization'] = 'Bearer $token';

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/register',
        data: {'name': name, 'phone': phone, 'password': password},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');

    ApiService.dio.options.headers.remove('Authorization');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      ApiService.dio.options.headers['Authorization'] = 'Bearer $token';
      return true;
    }

    return false;
  }
}

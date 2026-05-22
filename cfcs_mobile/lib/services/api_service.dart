import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static late Dio dio;

  static const String baseUrl = 'http://192.168.1.114:3000/api/v1';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
  }

  static String uploadUrl(String filePath) {
    final apiUri = Uri.parse(baseUrl);
    return apiUri
        .replace(path: '/uploads/$filePath', query: null, fragment: null)
        .toString();
  }
}

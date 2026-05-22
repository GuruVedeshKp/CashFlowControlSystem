import 'api_service.dart';

class DashboardService {
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final response = await ApiService.dio.get('/dashboard/summary');

      if (response.statusCode != 200) {
        return null;
      }

      return response.data['data']['cashSummary'];
    } catch (e) {
      return null;
    }
  }
}

import 'api_service.dart';

class NotificationsService {
  Future<List<dynamic>> getReminderHistory() async {
    try {
      final response = await ApiService.dio.get('/notifications/reminders');

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }
}

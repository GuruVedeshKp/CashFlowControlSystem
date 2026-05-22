import 'api_service.dart';

class SettingsService {
  Future<Map<String, dynamic>?> getBusinessProfile() async {
    try {
      final response = await ApiService.dio.get('/settings/business-profile');

      return response.data['data'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveBusinessProfile({
    required String businessName,
    required String ownerName,
    required String phone,
    String? address,
    String? gstNumber,
    String? upiId,
    String defaultReminderTone = 'polite',
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/settings/business-profile',
        data: {
          'businessName': businessName,
          'ownerName': ownerName,
          'phone': phone,
          'address': address,
          'gstNumber': gstNumber,
          'upiId': upiId,
          'defaultReminderTone': defaultReminderTone,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

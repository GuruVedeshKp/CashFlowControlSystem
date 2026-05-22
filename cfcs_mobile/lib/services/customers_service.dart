import 'api_service.dart';

class CustomersService {
  Future<List<dynamic>> getCustomers() async {
    try {
      final response = await ApiService.dio.get('/customers');

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createCustomer({
    required String name,
    required String phone,
    String? businessName,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/customers',
        data: {'name': name, 'phone': phone, 'businessName': businessName},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? businessName,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/customers/$customerId',
        data: {'name': name, 'phone': phone, 'businessName': businessName},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      final response = await ApiService.dio.delete('/customers/$customerId');

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCustomerHistory(String customerId) async {
    try {
      final response = await ApiService.dio.get(
        '/customers/$customerId/history',
      );

      return response.data['data'];
    } catch (e) {
      return null;
    }
  }
}

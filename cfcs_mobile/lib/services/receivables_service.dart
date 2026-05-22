import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class ReceivablesService {
  Future<List<dynamic>> getFollowUps() async {
    try {
      final response = await ApiService.dio.get('/receivables/follow-up');

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getReceivableDetails(String id) async {
    try {
      final response = await ApiService.dio.get('/receivables/$id');

      return response.data['data'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateDueDate(String receivableId, String newDate) async {
    try {
      final response = await ApiService.dio.patch(
        '/receivables/$receivableId/due-date',
        data: {'dueDate': newDate},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateReceivable({
    required String receivableId,
    required String description,
    required double totalAmount,
    required String dueDate,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/receivables/$receivableId',
        data: {
          'description': description,
          'totalAmount': totalAmount,
          'dueDate': dueDate,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReceivable(String receivableId) async {
    try {
      final response = await ApiService.dio.delete(
        '/receivables/$receivableId',
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreReceivable(String receivableId) async {
    try {
      final response = await ApiService.dio.patch(
        '/receivables/$receivableId/restore',
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> sendReminder(String receivableId, String tone) async {
    try {
      final response = await ApiService.dio.post(
        '/receivables/$receivableId/send-reminder',
        data: {'tone': tone},
      );

      return response.data['data']['whatsAppUrl'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> markPaid(
    String receivableId,
    double amount,
    String paidDate,
    String? note,
  ) async {
    try {
      final response = await ApiService.dio.post(
        '/receivables/$receivableId/mark-paid',
        data: {'amount': amount, 'paidDate': paidDate, 'note': note},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createReceivable({
    required String customerId,
    required String description,
    required double totalAmount,
    required String dueDate,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/receivables',
        data: {
          'customerId': customerId,
          'description': description,
          'totalAmount': totalAmount,
          'dueDate': dueDate,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getAllReceivables() async {
    try {
      final response = await ApiService.dio.get('/receivables');

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getReceivableHistory() async {
    try {
      final response = await ApiService.dio.get('/receivables/history');

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getReceivablesByCustomer(String customerId) async {
    try {
      final response = await ApiService.dio.get(
        '/receivables?customerId=$customerId',
      );

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getDocuments(String receivableId) async {
    try {
      final response = await ApiService.dio.get(
        '/receivables/$receivableId/documents',
      );

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      final response = await ApiService.dio.delete('/documents/$documentId');

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadDocument(String receivableId, File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await ApiService.dio.post(
        '/receivables/$receivableId/documents',
        data: formData,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getPaymentHistory(String receivableId) async {
    try {
      final response = await ApiService.dio.get(
        '/payments?receivableId=$receivableId',
      );

      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updatePayment({
    required String paymentId,
    required double amount,
    required String paymentDate,
    String? note,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/payments/$paymentId',
        data: {'amount': amount, 'paymentDate': paymentDate, 'note': note},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePayment(String paymentId) async {
    try {
      final response = await ApiService.dio.delete('/payments/$paymentId');

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

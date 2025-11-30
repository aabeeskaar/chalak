import '../../core/constants/api_constants.dart';
import '../../core/network/http_client.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<List<InvoiceModel>> getInvoices({
    String? studentId,
    String? instituteId,
    String? status,
    int page = 1,
    int limit = 20,
  });
  Future<InvoiceModel> getInvoiceById(String id);
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data);
  Future<InvoiceModel> markAsPaid(String id);
  Future<void> deleteInvoice(String id);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final HttpClient httpClient;

  InvoiceRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<List<InvoiceModel>> getInvoices({
    String? studentId,
    String? instituteId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (studentId != null) queryParams['student_id'] = studentId;
    if (instituteId != null) queryParams['institute_id'] = instituteId;
    if (status != null) queryParams['status'] = status;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await httpClient.get('/invoices?$queryString');

    final List<dynamic> invoicesJson = response['data'] ?? [];
    return invoicesJson.map((json) => InvoiceModel.fromJson(json)).toList();
  }

  @override
  Future<InvoiceModel> getInvoiceById(String id) async {
    final response = await httpClient.get('/invoices/$id');
    return InvoiceModel.fromJson(response['data']);
  }

  @override
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    // Debug logging
    print('Creating invoice with data: ${data}');
    final response = await httpClient.post('/invoices', data);
    // Backend returns invoice directly, not wrapped in 'data'
    return InvoiceModel.fromJson(response);
  }

  @override
  Future<InvoiceModel> markAsPaid(String id) async {
    final response = await httpClient.put('/invoices/$id/pay', {});
    return InvoiceModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await httpClient.delete('/invoices/$id');
  }
}
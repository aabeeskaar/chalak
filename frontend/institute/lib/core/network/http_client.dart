import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/storage_service.dart';

class HttpClient {
  final http.Client client;
  final StorageService storageService;

  HttpClient({
    required this.client,
    required this.storageService,
  });

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await storageService.getToken();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(token),
      ).timeout(const Duration(milliseconds: AppConstants.connectTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await storageService.getToken();
      final jsonBody = jsonEncode(body);
      final headers = _buildHeaders(token);
      print('[HTTP Client] POST $endpoint');
      print('[HTTP Client] Token: ${token?.substring(0, 20) ?? "null"}...');
      print('[HTTP Client] Headers: $headers');
      print('[HTTP Client] Body: $jsonBody');
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonBody,
      ).timeout(const Duration(milliseconds: AppConstants.connectTimeout));

      print('[HTTP Client] Response status: ${response.statusCode}');
      print('[HTTP Client] Response body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('[HTTP Client] Error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await storageService.getToken();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: AppConstants.connectTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final token = await storageService.getToken();
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(token),
      ).timeout(const Duration(milliseconds: AppConstants.connectTimeout));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerException(
          'Failed to delete resource',
          response.statusCode,
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw AuthException('Unauthorized access');
    } else {
      final errorMessage = _extractErrorMessage(response);
      throw ServerException(errorMessage, response.statusCode);
    }
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] ?? body['message'] ?? 'Unknown error occurred';
    } catch (_) {
      return 'Server error: ${response.statusCode}';
    }
  }

  Exception _handleError(dynamic error) {
    if (error is ServerException ||
        error is AuthException ||
        error is NetworkException) {
      return error as Exception;
    }

    if (error.toString().contains('SocketException')) {
      return NetworkException('No internet connection');
    }

    if (error.toString().contains('TimeoutException')) {
      return NetworkException('Connection timeout');
    }

    return ServerException('Unexpected error: ${error.toString()}');
  }
}
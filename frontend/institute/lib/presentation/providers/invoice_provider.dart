import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/invoice/get_invoices_usecase.dart';
import '../../domain/usecases/invoice/create_invoice_usecase.dart';
import '../../domain/usecases/invoice/mark_invoice_paid_usecase.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

enum InvoiceState { initial, loading, loaded, error }

class InvoiceProvider extends ChangeNotifier {
  final GetInvoicesUseCase getInvoicesUseCase;
  final CreateInvoiceUseCase createInvoiceUseCase;
  final MarkInvoicePaidUseCase markInvoicePaidUseCase;

  InvoiceState _state = InvoiceState.initial;
  List<InvoiceEntity> _invoices = [];
  String? _errorMessage;
  bool _hasMoreData = true;
  int _currentPage = 1;

  InvoiceState get state => _state;
  List<InvoiceEntity> get invoices => _invoices;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isLoading => _state == InvoiceState.loading;

  InvoiceProvider({
    required this.getInvoicesUseCase,
    required this.createInvoiceUseCase,
    required this.markInvoicePaidUseCase,
  });

  Future<void> getInvoices({
    bool refresh = false,
    String? studentId,
    String? instituteId,
    String? status,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _invoices.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    _setState(InvoiceState.loading);
    _errorMessage = null;

    final result = await getInvoicesUseCase(
      page: _currentPage,
      studentId: studentId,
      instituteId: instituteId,
      status: status,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(InvoiceState.error);
      },
      (newInvoices) {
        if (refresh) {
          _invoices = newInvoices;
        } else {
          _invoices.addAll(newInvoices);
        }

        if (newInvoices.length < 20) {
          _hasMoreData = false;
        } else {
          _currentPage++;
        }

        _setState(InvoiceState.loaded);
      },
    );
  }

  Future<InvoiceEntity?> createInvoice(Map<String, dynamic> data) async {
    _setState(InvoiceState.loading);
    _errorMessage = null;

    final result = await createInvoiceUseCase(data);

    InvoiceEntity? createdInvoice;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(InvoiceState.error);
      },
      (invoice) {
        _invoices.insert(0, invoice);
        createdInvoice = invoice;
        _setState(InvoiceState.loaded);
      },
    );

    return createdInvoice;
  }

  Future<void> markAsPaid(String invoiceId) async {
    _setState(InvoiceState.loading);
    _errorMessage = null;

    final result = await markInvoicePaidUseCase(invoiceId);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(InvoiceState.error);
      },
      (updatedInvoice) {
        final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
        if (index != -1) {
          _invoices[index] = updatedInvoice;
        }
        _setState(InvoiceState.loaded);
      },
    );
  }

  Future<bool> addPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    _setState(InvoiceState.loading);
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _setState(InvoiceState.error);
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'invoice_id': invoiceId,
          'amount': amount,
          'payment_method': paymentMethod,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        // Refresh invoices to get updated data
        await getInvoices(refresh: true);
        _setState(InvoiceState.loaded);
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to add payment';
        _setState(InvoiceState.error);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(InvoiceState.error);
      return false;
    }
  }

  Future<List<PaymentEntity>> getPaymentsByInvoiceId(String invoiceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payments/invoice/$invoiceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> paymentsJson = jsonData['data'] ?? [];

        return paymentsJson.map((json) {
          return PaymentEntity(
            id: json['id'],
            invoiceId: json['invoice_id'],
            amount: (json['amount'] as num).toDouble(),
            paymentMethod: json['payment_method'],
            paymentDate: DateTime.parse(json['payment_date']),
            notes: json['notes'],
            createdBy: json['created_by'],
            createdAt: DateTime.parse(json['created_at']),
            updatedAt: DateTime.parse(json['updated_at']),
            deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
          );
        }).toList();
      } else {
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  void filterByStatus(String? status) {
    getInvoices(refresh: true, status: status);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(InvoiceState newState) {
    _state = newState;
    notifyListeners();
  }
}

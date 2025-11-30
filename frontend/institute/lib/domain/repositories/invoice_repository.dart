import '../../core/utils/either.dart';
import '../entities/invoice_entity.dart';

abstract class InvoiceRepository {
  Future<EitherFailure<List<InvoiceEntity>>> getInvoices({
    String? studentId,
    String? instituteId,
    String? status,
    int page = 1,
    int limit = 20,
  });
  Future<EitherFailure<InvoiceEntity>> getInvoiceById(String id);
  Future<EitherFailure<InvoiceEntity>> createInvoice(Map<String, dynamic> data);
  Future<EitherFailure<InvoiceEntity>> markAsPaid(String id);
  Future<EitherFailure<void>> deleteInvoice(String id);
}
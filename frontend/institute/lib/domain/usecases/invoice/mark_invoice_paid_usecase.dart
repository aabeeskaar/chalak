import '../../../core/utils/either.dart';
import '../../entities/invoice_entity.dart';
import '../../repositories/invoice_repository.dart';

class MarkInvoicePaidUseCase {
  final InvoiceRepository repository;

  MarkInvoicePaidUseCase(this.repository);

  Future<EitherFailure<InvoiceEntity>> call(String id) async {
    return await repository.markAsPaid(id);
  }
}

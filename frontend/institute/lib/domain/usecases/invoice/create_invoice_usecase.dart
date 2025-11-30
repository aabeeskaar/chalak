import '../../../core/utils/either.dart';
import '../../entities/invoice_entity.dart';
import '../../repositories/invoice_repository.dart';

class CreateInvoiceUseCase {
  final InvoiceRepository repository;

  CreateInvoiceUseCase(this.repository);

  Future<EitherFailure<InvoiceEntity>> call(Map<String, dynamic> data) async {
    return await repository.createInvoice(data);
  }
}

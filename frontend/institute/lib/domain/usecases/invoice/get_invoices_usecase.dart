import '../../../core/utils/either.dart';
import '../../entities/invoice_entity.dart';
import '../../repositories/invoice_repository.dart';

class GetInvoicesUseCase {
  final InvoiceRepository repository;

  GetInvoicesUseCase(this.repository);

  Future<EitherFailure<List<InvoiceEntity>>> call({
    String? studentId,
    String? instituteId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getInvoices(
      studentId: studentId,
      instituteId: instituteId,
      status: status,
      page: page,
      limit: limit,
    );
  }
}

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;

  InvoiceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<EitherFailure<List<InvoiceEntity>>> getInvoices({
    String? studentId,
    String? instituteId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final invoices = await remoteDataSource.getInvoices(
        studentId: studentId,
        instituteId: instituteId,
        status: status,
        page: page,
        limit: limit,
      );
      return Right(invoices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<InvoiceEntity>> getInvoiceById(String id) async {
    try {
      final invoice = await remoteDataSource.getInvoiceById(id);
      return Right(invoice);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<InvoiceEntity>> createInvoice(Map<String, dynamic> data) async {
    try {
      final invoice = await remoteDataSource.createInvoice(data);
      return Right(invoice);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<InvoiceEntity>> markAsPaid(String id) async {
    try {
      final invoice = await remoteDataSource.markAsPaid(id);
      return Right(invoice);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<void>> deleteInvoice(String id) async {
    try {
      await remoteDataSource.deleteInvoice(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
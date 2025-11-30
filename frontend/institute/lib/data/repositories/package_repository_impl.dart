import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/package_entity.dart';
import '../../domain/repositories/package_repository.dart';
import '../datasources/package_remote_datasource.dart';

class PackageRepositoryImpl implements PackageRepository {
  final PackageRemoteDataSource remoteDataSource;

  PackageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<EitherFailure<List<PackageEntity>>> getPackages({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    try {
      final packages = await remoteDataSource.getPackages(
        page: page,
        limit: limit,
        search: search,
        isActive: isActive,
      );
      return Right(packages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<PackageEntity>> getPackageById(String id) async {
    try {
      final package = await remoteDataSource.getPackageById(id);
      return Right(package);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<PackageEntity>> createPackage(Map<String, dynamic> data) async {
    try {
      final package = await remoteDataSource.createPackage(data);
      return Right(package);
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
  Future<EitherFailure<PackageEntity>> updatePackage(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final package = await remoteDataSource.updatePackage(id, data);
      return Right(package);
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
  Future<EitherFailure<void>> deletePackage(String id) async {
    try {
      await remoteDataSource.deletePackage(id);
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
import '../../core/utils/either.dart';
import '../entities/package_entity.dart';

abstract class PackageRepository {
  Future<EitherFailure<List<PackageEntity>>> getPackages({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  });
  Future<EitherFailure<PackageEntity>> getPackageById(String id);
  Future<EitherFailure<PackageEntity>> createPackage(Map<String, dynamic> data);
  Future<EitherFailure<PackageEntity>> updatePackage(
    String id,
    Map<String, dynamic> data,
  );
  Future<EitherFailure<void>> deletePackage(String id);
}
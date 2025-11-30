import '../../../core/utils/either.dart';
import '../../entities/package_entity.dart';
import '../../repositories/package_repository.dart';

class GetPackagesUseCase {
  final PackageRepository repository;

  GetPackagesUseCase(this.repository);

  Future<EitherFailure<List<PackageEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    return await repository.getPackages(
      page: page,
      limit: limit,
      search: search,
      isActive: isActive,
    );
  }
}
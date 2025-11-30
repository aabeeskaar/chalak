import '../../../core/utils/either.dart';
import '../../entities/package_entity.dart';
import '../../repositories/package_repository.dart';

class CreatePackageUseCase {
  final PackageRepository repository;

  CreatePackageUseCase(this.repository);

  Future<EitherFailure<PackageEntity>> call(Map<String, dynamic> data) async {
    return await repository.createPackage(data);
  }
}
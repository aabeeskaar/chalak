import '../../../core/utils/either.dart';
import '../../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<EitherFailure<void>> call() async {
    return await repository.logout();
  }
}
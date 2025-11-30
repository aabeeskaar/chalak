import '../../../core/utils/either.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<EitherFailure<UserEntity>> call(String email, String password) async {
    print('LOGIN_USECASE DEBUG: Calling repository.login() with email: $email');
    try {
      final result = await repository.login(email, password);
      print('LOGIN_USECASE DEBUG: Repository.login() returned result');
      return result;
    } catch (e) {
      print('LOGIN_USECASE DEBUG: Exception in repository.login(): $e');
      rethrow;
    }
  }
}
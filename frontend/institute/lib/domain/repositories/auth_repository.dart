import '../../core/utils/either.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<EitherFailure<UserEntity>> login(String email, String password);
  Future<EitherFailure<void>> logout();
  Future<EitherFailure<UserEntity>> getCurrentUser();
  Future<EitherFailure<String>> refreshToken();
}
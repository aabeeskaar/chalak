import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../core/utils/storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<EitherFailure<UserEntity>> login(String email, String password) async {
    print('AUTH_REPOSITORY DEBUG: login() called with email: $email');
    try {
      print('AUTH_REPOSITORY DEBUG: Calling remoteDataSource.login()...');
      final user = await remoteDataSource.login(email, password);
      print('AUTH_REPOSITORY DEBUG: remoteDataSource.login() returned user: ${user.email}');
      return Right(user);
    } on ServerException catch (e) {
      print('AUTH_REPOSITORY DEBUG: ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      print('AUTH_REPOSITORY DEBUG: NetworkException: ${e.message}');
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      print('AUTH_REPOSITORY DEBUG: AuthException: ${e.message}');
      return Left(AuthFailure(e.message));
    } catch (e) {
      print('AUTH_REPOSITORY DEBUG: Unexpected error: ${e.toString()}');
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<void>> logout() async {
    try {
      await remoteDataSource.logout();
      await storageService.clearAll();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<String>> refreshToken() async {
    try {
      final token = await remoteDataSource.refreshToken();
      await storageService.saveToken(token);
      return Right(token);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
import '../../core/constants/api_constants.dart';
import '../../core/network/http_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<String> refreshToken();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final HttpClient httpClient;

  AuthRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<UserModel> login(String email, String password) async {
    print('AUTH_REMOTE_DATASOURCE DEBUG: login() called with email: $email');
    print('AUTH_REMOTE_DATASOURCE DEBUG: Making POST request to: ${ApiConstants.login}');

    try {
      final response = await httpClient.post(
        ApiConstants.login,
        {
          'email': email,
          'password': password,
        },
      );

      print('AUTH_REMOTE_DATASOURCE DEBUG: HTTP client returned response: $response');

      if (response['user'] == null) {
        print('AUTH_REMOTE_DATASOURCE DEBUG: Warning - response[\'user\'] is null');
      }

      // Store the tokens from the response
      if (response['access_token'] != null) {
        await httpClient.storageService.saveToken(response['access_token']);
        print('AUTH_REMOTE_DATASOURCE DEBUG: Access token saved');
      }

      if (response['refresh_token'] != null) {
        await httpClient.storageService.saveRefreshToken(response['refresh_token']);
        print('AUTH_REMOTE_DATASOURCE DEBUG: Refresh token saved');
      }

      final userModel = UserModel.fromJson(response['user']);
      print('AUTH_REMOTE_DATASOURCE DEBUG: UserModel created successfully for: ${userModel.email}');
      return userModel;
    } catch (e) {
      print('AUTH_REMOTE_DATASOURCE DEBUG: Exception in login: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await httpClient.post('/auth/logout', {});
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await httpClient.get('/auth/me');
    return UserModel.fromJson(response['user']);
  }

  @override
  Future<String> refreshToken() async {
    final response = await httpClient.post(ApiConstants.refreshToken, {});
    return response['token'];
  }
}
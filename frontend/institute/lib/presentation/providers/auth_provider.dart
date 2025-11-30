import 'package:flutter/material.dart';
import '../../core/utils/storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final StorageService storageService;

  AuthState _state = AuthState.initial;
  UserEntity? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  // Get token from storage
  Future<String?> get token async => await storageService.getToken();

  AuthProvider({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.storageService,
  }) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _setState(AuthState.loading);

    final isLoggedIn = await storageService.isLoggedIn();
    if (isLoggedIn) {
      // Verify token validity by making a test API call
      try {
        final token = await storageService.getToken();
        if (token != null) {
          // For now, just check if we have user data
          // In production, you'd validate with backend here
          final userData = await storageService.getUser();
          if (userData != null) {
            _user = UserEntity(
              id: userData['id'] ?? '',
              email: userData['email'] ?? '',
              name: userData['name'] ?? '',
              role: userData['role'] ?? '',
              phone: userData['phone'],
              createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
            );
            _setState(AuthState.authenticated);
            return;
          }
        }
      } catch (e) {
        print('AUTH_PROVIDER: Token validation failed: $e');
      }

      // Clear invalid token and redirect to login
      await storageService.clearAll();
      _setState(AuthState.unauthenticated);
    } else {
      _setState(AuthState.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    print('AUTH_PROVIDER DEBUG: login() called with email: $email');
    _setState(AuthState.loading);
    _errorMessage = null;

    print('AUTH_PROVIDER DEBUG: Calling loginUseCase...');
    try {
      final result = await loginUseCase(email, password);

      print('AUTH_PROVIDER DEBUG: loginUseCase returned, processing result...');
      if (result.isLeft()) {
        final failure = result.left;
        print('AUTH_PROVIDER DEBUG: Login failed - ${failure.message}');
        _errorMessage = failure.message;
        _setState(AuthState.error);
      } else {
        final user = result.right;
        print('AUTH_PROVIDER DEBUG: Login successful for user: ${user.email}');
        _user = user;
        await storageService.saveUser({
          'id': user.id,
          'email': user.email,
          'name': user.name,
          'role': user.role,
          'phone': user.phone,
          'created_at': user.createdAt.toIso8601String(),
        });
        await storageService.saveRole(user.role);
        _setState(AuthState.authenticated);
        print('AUTH_PROVIDER DEBUG: User data saved, state set to authenticated');
      }
    } catch (e) {
      print('AUTH_PROVIDER DEBUG: Exception in login: $e');
      _errorMessage = 'An unexpected error occurred: $e';
      _setState(AuthState.error);
    }
  }

  Future<void> logout() async {
    _setState(AuthState.loading);

    // Clear stored credentials
    await storageService.clearAll();
    _user = null;
    _setState(AuthState.unauthenticated);

    // Try to call backend logout (optional, don't block on failure)
    try {
      await logoutUseCase();
    } catch (e) {
      print('AUTH_PROVIDER: Logout API call failed (non-blocking): $e');
    }
  }

  Future<void> forceLogout() async {
    // Force logout without API call (for expired tokens)
    await storageService.clearAll();
    _user = null;
    _setState(AuthState.unauthenticated);
  }

  Future<void> clearStorageAndLogout() async {
    // Clear all stored data and set to unauthenticated
    print('AUTH_PROVIDER: Clearing all storage and forcing logout');
    await storageService.clearAll();
    _user = null;
    _errorMessage = null;
    _setState(AuthState.unauthenticated);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
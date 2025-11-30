import 'package:flutter/material.dart';
import '../../domain/entities/package_entity.dart';
import '../../domain/usecases/package/get_packages_usecase.dart';
import '../../domain/usecases/package/create_package_usecase.dart';

enum PackageState { initial, loading, loaded, error }

class PackageProvider extends ChangeNotifier {
  final GetPackagesUseCase getPackagesUseCase;
  final CreatePackageUseCase createPackageUseCase;

  PackageState _state = PackageState.initial;
  List<PackageEntity> _packages = [];
  List<PackageEntity> _popularPackages = [];
  String? _errorMessage;
  bool _hasMoreData = true;
  int _currentPage = 1;

  PackageState get state => _state;
  List<PackageEntity> get packages => _packages;
  List<PackageEntity> get popularPackages => _popularPackages;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isLoading => _state == PackageState.loading;

  PackageProvider({
    required this.getPackagesUseCase,
    required this.createPackageUseCase,
  });

  Future<void> getPackages({
    bool refresh = false,
    String? search,
    bool? isActive,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _packages.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    _setState(PackageState.loading);
    _errorMessage = null;

    final result = await getPackagesUseCase(
      page: _currentPage,
      search: search,
      isActive: isActive,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(PackageState.error);
      },
      (newPackages) {
        if (refresh) {
          _packages = newPackages;
        } else {
          _packages.addAll(newPackages);
        }

        if (newPackages.length < 20) {
          _hasMoreData = false;
        } else {
          _currentPage++;
        }

        _setState(PackageState.loaded);
      },
    );
  }

  Future<void> createPackage(Map<String, dynamic> data) async {
    _setState(PackageState.loading);
    _errorMessage = null;

    final result = await createPackageUseCase(data);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(PackageState.error);
      },
      (package) {
        _packages.insert(0, package);
        _setState(PackageState.loaded);
      },
    );
  }

  void searchPackages(String query) {
    getPackages(refresh: true, search: query);
  }

  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    _setState(PackageState.loading);
    _errorMessage = null;

    // This would need UpdatePackageUseCase to be added
    // For now, just refresh the list after update
    getPackages(refresh: true);
  }

  Future<void> deletePackage(String id) async {
    _setState(PackageState.loading);
    _errorMessage = null;

    // This would need DeletePackageUseCase to be added
    // For now, just remove from list locally
    _packages.removeWhere((p) => p.id == id);
    _setState(PackageState.loaded);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(PackageState newState) {
    _state = newState;
    notifyListeners();
  }
}
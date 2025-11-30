import '../../core/network/http_client.dart';
import '../models/package_model.dart';

abstract class PackageRemoteDataSource {
  Future<List<PackageModel>> getPackages({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
    bool? isPopular,
  });
  Future<PackageModel> getPackageById(String id);
  Future<PackageModel> createPackage(Map<String, dynamic> data);
  Future<PackageModel> updatePackage(String id, Map<String, dynamic> data);
  Future<void> deletePackage(String id);
}

class PackageRemoteDataSourceImpl implements PackageRemoteDataSource {
  final HttpClient httpClient;

  PackageRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<List<PackageModel>> getPackages({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
    bool? isPopular,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await httpClient.get('/packages?$queryString');

    final List<dynamic> packagesJson = response['data'] ?? [];
    return packagesJson.map((json) => PackageModel.fromJson(json)).toList();
  }

  @override
  Future<PackageModel> getPackageById(String id) async {
    final response = await httpClient.get('/packages/$id');
    return PackageModel.fromJson(response['data']);
  }

  @override
  Future<PackageModel> createPackage(Map<String, dynamic> data) async {
    final response = await httpClient.post('/packages', data);
    return PackageModel.fromJson(response['data']);
  }

  @override
  Future<PackageModel> updatePackage(String id, Map<String, dynamic> data) async {
    final response = await httpClient.put('/packages/$id', data);
    return PackageModel.fromJson(response['data']);
  }

  @override
  Future<void> deletePackage(String id) async {
    await httpClient.delete('/packages/$id');
  }
}
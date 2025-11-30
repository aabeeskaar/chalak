import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/http_client.dart';
import '../utils/storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/student_remote_datasource.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/datasources/invoice_remote_datasource.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/package_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/package_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/package_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/student/get_students_usecase.dart';
import '../../domain/usecases/student/create_student_usecase.dart';
import '../../domain/usecases/attendance/get_attendance_usecase.dart';
import '../../domain/usecases/attendance/mark_attendance_usecase.dart';
import '../../domain/usecases/course/get_courses_usecase.dart';
import '../../domain/usecases/course/create_course_usecase.dart';
import '../../domain/usecases/course/update_course_usecase.dart';
import '../../domain/usecases/package/get_packages_usecase.dart';
import '../../domain/usecases/package/create_package_usecase.dart';
import '../../domain/usecases/invoice/get_invoices_usecase.dart';
import '../../domain/usecases/invoice/create_invoice_usecase.dart';
import '../../domain/usecases/invoice/mark_invoice_paid_usecase.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/student_provider.dart';
import '../../presentation/providers/attendance_provider.dart';
import '../../presentation/providers/course_provider.dart';
import '../../presentation/providers/package_provider.dart';
import '../../presentation/providers/invoice_provider.dart';
import '../../presentation/providers/report_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => http.Client());

  sl.registerLazySingleton(() => StorageService(sl()));

  sl.registerLazySingleton(() => HttpClient(
        client: sl(),
        storageService: sl(),
      ));

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(httpClient: sl()),
  );
  sl.registerLazySingleton<StudentRemoteDataSource>(
    () => StudentRemoteDataSourceImpl(httpClient: sl()),
  );
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(httpClient: sl()),
  );
  sl.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSourceImpl(httpClient: sl()),
  );
  sl.registerLazySingleton<CourseRemoteDataSource>(
    () => CourseRemoteDataSourceImpl(httpClient: sl()),
  );
  sl.registerLazySingleton<PackageRemoteDataSource>(
    () => PackageRemoteDataSourceImpl(httpClient: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      storageService: sl(),
    ),
  );
  sl.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<PackageRepository>(
    () => PackageRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentsUseCase(sl()));
  sl.registerLazySingleton(() => CreateStudentUseCase(sl()));
  sl.registerLazySingleton(() => GetAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => MarkAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => GetCoursesUseCase(sl()));
  sl.registerLazySingleton(() => CreateCourseUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCourseUseCase(sl()));
  sl.registerLazySingleton(() => GetPackagesUseCase(sl()));
  sl.registerLazySingleton(() => CreatePackageUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => CreateInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => MarkInvoicePaidUseCase(sl()));

  sl.registerFactory(() => AuthProvider(
        loginUseCase: sl(),
        logoutUseCase: sl(),
        storageService: sl(),
      ));
  sl.registerFactory(() => StudentProvider(
        getStudentsUseCase: sl(),
        createStudentUseCase: sl(),
      ));
  sl.registerFactory(() => AttendanceProvider(
        getAttendanceUseCase: sl(),
        markAttendanceUseCase: sl(),
      ));
  sl.registerFactory(() => CourseProvider(
        getCoursesUseCase: sl(),
        createCourseUseCase: sl(),
        updateCourseUseCase: sl(),
      ));
  sl.registerFactory(() => PackageProvider(
        getPackagesUseCase: sl(),
        createPackageUseCase: sl(),
      ));
  sl.registerFactory(() => InvoiceProvider(
        getInvoicesUseCase: sl(),
        createInvoiceUseCase: sl(),
        markInvoicePaidUseCase: sl(),
      ));
  sl.registerFactory(() => ReportProvider());
}

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
  ChangeNotifierProvider(create: (_) => sl<StudentProvider>()),
  ChangeNotifierProvider(create: (_) => sl<AttendanceProvider>()),
  ChangeNotifierProvider(create: (_) => sl<CourseProvider>()),
  ChangeNotifierProvider(create: (_) => sl<PackageProvider>()),
  ChangeNotifierProvider(create: (_) => sl<InvoiceProvider>()),
  ChangeNotifierProvider(create: (_) => sl<ReportProvider>()),
];
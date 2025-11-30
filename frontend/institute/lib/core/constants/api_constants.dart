class ApiConstants {
  // Android emulator uses 10.0.2.2 to reach host machine's localhost
  // For Windows/Web development, use localhost
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';

  static const String students = '/students';
  static const String studentById = '/students/{id}';
  static const String studentSearch = '/students/search';

  static const String attendance = '/attendance';
  static const String attendanceById = '/attendance/{id}';
  static const String attendanceByStudent = '/attendance/student/{id}';
  static const String markAttendance = '/attendance';

  static const String invoices = '/invoices';
  static const String invoiceById = '/invoices/{id}';
  static const String invoicesByStudent = '/invoices/student/{id}';

  static const String employees = '/employees';
  static const String employeeById = '/employees/{id}';

  static const String expenses = '/expenses';
  static const String expenseById = '/expenses/{id}';

  static const String notifications = '/notifications';
  static const String notificationById = '/notifications/{id}';
  static const String sendNotification = '/notifications/send';

  static const String courses = '/courses';
  static const String courseById = '/courses/{id}';
  static const String courseCategories = '/courses/categories';

  static const String packages = '/packages';
  static const String packageById = '/packages/{id}';

  static String getStudentById(String id) => studentById.replaceAll('{id}', id);
  static String getAttendanceById(String id) => attendanceById.replaceAll('{id}', id);
  static String getAttendanceByStudent(String id) => attendanceByStudent.replaceAll('{id}', id);
  static String getInvoiceById(String id) => invoiceById.replaceAll('{id}', id);
  static String getInvoicesByStudent(String id) => invoicesByStudent.replaceAll('{id}', id);
  static String getEmployeeById(String id) => employeeById.replaceAll('{id}', id);
  static String getExpenseById(String id) => expenseById.replaceAll('{id}', id);
  static String getNotificationById(String id) => notificationById.replaceAll('{id}', id);
  static String getCourseById(String id) => courseById.replaceAll('{id}', id);
  static String getPackageById(String id) => packageById.replaceAll('{id}', id);
}
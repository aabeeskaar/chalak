class AppConstants {
  static const String appName = 'Chalak Institute';
  static const String appVersion = '1.0.0';

  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  static const int pageSize = 20;
  static const int maxRetries = 3;
}

enum UserRole {
  admin,
  instructor,
  accountant,
  staff;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.instructor:
        return 'Instructor';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.staff:
        return 'Staff';
    }
  }
}

enum AttendanceStatus {
  present,
  absent,
  late;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  partial,
  overdue;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.overdue:
        return 'Overdue';
    }
  }
}
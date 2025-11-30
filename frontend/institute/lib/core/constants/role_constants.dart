import 'package:flutter/material.dart';

class UserRoles {
  static const String admin = 'admin';
  static const String instructor = 'instructor';
  static const String accountant = 'accountant';
  static const String staff = 'staff';

  static const List<String> allRoles = [admin, instructor, accountant, staff];

  static bool isValidRole(String role) {
    return allRoles.contains(role.toLowerCase());
  }
}

class RolePermissions {
  // Define what each role can access
  static const Map<String, List<String>> permissions = {
    UserRoles.admin: [
      'dashboard',
      'students',
      'attendance',
      'courses',
      'packages',
      'invoices',
      'expenses',
      'reports',
      'hr_management',
      'analytics',
      'settings',
      'user_management',
    ],
    UserRoles.instructor: [
      'dashboard',
      'students',
      'attendance',
      'courses',
      'packages',
      'reports',
    ],
    UserRoles.accountant: [
      'dashboard',
      'students',
      'invoices',
      'expenses',
      'reports',
      'analytics',
    ],
    UserRoles.staff: [
      'dashboard',
      'students',
      'attendance',
      'courses',
    ],
  };

  static bool hasPermission(String userRole, String permission) {
    final rolePermissions = permissions[userRole.toLowerCase()];
    return rolePermissions?.contains(permission) ?? false;
  }

  static List<String> getUserPermissions(String userRole) {
    return permissions[userRole.toLowerCase()] ?? [];
  }
}

class NavigationItems {
  static const String dashboard = 'dashboard';
  static const String students = 'students';
  static const String attendance = 'attendance';
  static const String courses = 'courses';
  static const String packages = 'packages';
  static const String invoices = 'invoices';
  static const String expenses = 'expenses';
  static const String reports = 'reports';
  static const String hrManagement = 'hr_management';
  static const String analytics = 'analytics';
  static const String settings = 'settings';

  static List<NavigationItem> getNavigationItems(String userRole) {
    final allItems = [
      NavigationItem(
        key: dashboard,
        icon: Icons.dashboard,
        label: 'Dashboard',
        permission: 'dashboard',
      ),
      NavigationItem(
        key: students,
        icon: Icons.people,
        label: 'Students',
        permission: 'students',
      ),
      NavigationItem(
        key: attendance,
        icon: Icons.check_circle,
        label: 'Attendance',
        permission: 'attendance',
      ),
      NavigationItem(
        key: courses,
        icon: Icons.school,
        label: 'Courses',
        permission: 'courses',
      ),
      NavigationItem(
        key: packages,
        icon: Icons.card_giftcard,
        label: 'Packages',
        permission: 'packages',
      ),
      NavigationItem(
        key: invoices,
        icon: Icons.receipt,
        label: 'Invoices',
        permission: 'invoices',
      ),
      NavigationItem(
        key: expenses,
        icon: Icons.money_off,
        label: 'Expenses',
        permission: 'expenses',
      ),
      NavigationItem(
        key: reports,
        icon: Icons.analytics,
        label: 'Reports',
        permission: 'reports',
      ),
      NavigationItem(
        key: hrManagement,
        icon: Icons.business,
        label: 'HR',
        permission: 'hr_management',
      ),
    ];

    return allItems
        .where((item) => RolePermissions.hasPermission(userRole, item.permission))
        .toList();
  }
}

class NavigationItem {
  final String key;
  final IconData icon;
  final String label;
  final String permission;

  const NavigationItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.permission,
  });
}
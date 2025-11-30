# Chalak Institute App

A comprehensive driving institute management mobile application built with Flutter and clean architecture.

## 🏗️ Architecture

This app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                     # Core application infrastructure
│   ├── constants/           # API endpoints, app constants
│   ├── di/                  # Dependency injection setup
│   ├── errors/              # Error handling (failures, exceptions)
│   ├── network/             # HTTP client and network layer
│   ├── theme/               # App theming and styling
│   └── utils/               # Utilities (Either, storage service)
├── data/                     # Data layer
│   ├── datasources/         # Remote API data sources
│   ├── models/              # Data models with JSON serialization
│   └── repositories/        # Repository implementations
├── domain/                   # Business logic layer
│   ├── entities/            # Core business entities
│   ├── repositories/        # Repository interfaces
│   └── usecases/            # Business use cases
└── presentation/             # UI layer
    ├── providers/           # State management (Provider pattern)
    ├── screens/             # Application screens
    └── widgets/             # Reusable UI components
```

## 🚀 Features

### ✅ Completed Features
- **Clean Architecture Setup**: Complete project structure with separation of concerns
- **Authentication System**: Login/logout with JWT token management
- **Dashboard**: Overview with key metrics and analytics cards
- **Student Management**: List, search, and view student profiles
- **Attendance System**: View and manage attendance records
- **State Management**: Provider-based state management
- **API Integration**: Complete HTTP client with error handling
- **Dependency Injection**: GetIt-based DI container

### 🔄 In Progress
- **QR Code Attendance**: QR code scanning for attendance marking

### 📋 Planned Features
- **Course/Package Management**: Manage driving course packages
- **Invoice & Payment Tracking**: Financial management system
- **Expense Logging**: Track institute expenses and generate reports
- **HR/Employee Management**: Staff management and payroll
- **Notifications**: Push notifications and in-app messaging
- **Report Generation**: PDF/Excel export functionality

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Provider
- **Dependency Injection**: GetIt
- **HTTP Client**: HTTP package with custom wrapper
- **Storage**: SharedPreferences
- **Architecture**: Clean Architecture
- **Navigation**: Material Navigation

## 📱 Key Modules

### 1. Authentication
- Role-based login (Admin, Instructor, Accountant, Staff)
- JWT token management
- Persistent login state

### 2. Student Management
- Student profiles with personal information
- QR code generation for each student
- Search and filtering capabilities
- Status tracking (Active, Inactive, Suspended)

### 3. Attendance Tracking
- Real-time attendance marking
- QR code scanning integration
- Date range filtering
- Attendance history and reports

### 4. Dashboard & Analytics
- Key performance indicators
- Student statistics
- Revenue tracking
- Quick action cards

## 🔧 Getting Started

### Prerequisites
- Flutter 3.10 or higher
- Dart 3.0 or higher
- Android Studio / VS Code
- Backend API running (Chalak Go backend)

### Installation

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure API endpoint**:
   Update `lib/core/constants/api_constants.dart` with your backend URL:
   ```dart
   static const String baseUrl = 'http://your-backend-url:8080/api/v1';
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## 🏃‍♂️ Running the App

1. **Start the backend**: Ensure the Chalak Go backend is running
2. **Run Flutter app**: `flutter run`
3. **Login**: Use institute credentials to access the dashboard

## 🔗 API Integration

The app integrates with the Chalak backend API with the following endpoints:
- `/auth/login` - User authentication
- `/students` - Student management
- `/attendance` - Attendance tracking
- `/invoices` - Invoice management
- `/employees` - Staff management
- `/expenses` - Expense tracking
- `/notifications` - Notification system

## 📋 Role-Based Access

Different user roles have different permissions:
- **Admin**: Full access to all features
- **Instructor**: Student and attendance management
- **Accountant**: Financial and invoice management
- **Staff**: Limited access based on responsibilities

## 🎯 Next Steps

1. **Complete QR Code Integration**: Implement camera-based QR scanning
2. **Add Course Management**: Create and manage driving course packages
3. **Implement Invoice System**: Complete payment tracking functionality
4. **Add Report Generation**: PDF/Excel export capabilities
5. **Setup Push Notifications**: Firebase Cloud Messaging integration
6. **Add Offline Support**: Local caching with Hive database

## 🤝 Contributing

This app is part of the Chalak driving institute management platform. Follow the existing clean architecture patterns when adding new features.

## 📄 License

This project is part of the Chalak platform - a comprehensive driving institute management system.
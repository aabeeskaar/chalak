# Claude Code Context for Chalak Full-Stack Project

## Project Status Summary
**Chalak** is a driving institute management system with **complete backend** and **ready frontend** setup.

### ✅ Current State
- **Backend**: Production-ready Go API with 7 modules and 40+ endpoints
- **Frontend**: Flutter app with clean architecture setup, ready for development
- **Project Structure**: Organized into separate backend/ and frontend/ directories

### 📁 Project Organization
```
Chalak/
├── backend/          # Go API (Production Ready)
│   ├── cmd/api/     # 7 complete modules
│   ├── internal/    # Clean architecture
│   ├── pkg/         # Shared utilities
│   ├── migrations/  # 7 database tables
│   └── *.md         # Documentation
└── frontend/         # Flutter App (Ready for Development)
    ├── android/ios/  # Platform files
    ├── lib/         # Clean architecture structure
    └── pubspec.yaml # Flutter dependencies
```

### 🗂️ Key Files to Reference
- `PROJECT_STRUCTURE.md` - Complete project overview and status
- `backend/PROJECT_SUMMARY.md` - Backend implementation details
- `backend/ARCHITECTURE.md` - Technical architecture decisions
- `backend/IMPLEMENTATION_GUIDE.md` - Development patterns

### 🔧 Common Commands

#### Backend (Go API)
```bash
cd backend/

# Start infrastructure
make docker-up && make migrate-up

# Run API server (all 7 modules)
go run cmd/api/main.go

# Test API
curl http://localhost:8080/health

# Run tests
go test ./...
```

#### Frontend (Flutter App)
```bash
cd frontend/

# Get dependencies
flutter pub get

# Run app
flutter run

# Test app
flutter test
```

### 🎯 Recent Work/Context
- **Reorganized project** into backend/ and frontend/ directories
- **Backend is production-ready** with 7 complete modules:
  - Authentication, Students, Attendance, Invoices, Employees, Expenses, Notifications
- **Flutter project created** with clean architecture structure
- **Ready for mobile app development** connecting to existing API

### 🚀 Current Todo Status
1. ✅ Set up Flutter development environment and create new project
2. ✅ Design app architecture and folder structure for Chalak mobile app
3. 🔄 Create API service layer to connect with existing Chalak backend
4. 📱 Implement authentication screens (login, register, splash)
5. 📱 Build student dashboard and profile screens
6. 📱 Create attendance tracking and viewing screens
7. 📱 Implement invoice and payment viewing functionality
8. 📱 Add notifications and settings screens
9. 🧪 Test app integration with Chalak backend API
10. 🚀 Prepare app for deployment (Android/iOS)

### 🔗 Integration Points
- **Backend API**: http://localhost:8080/api/v1/
- **40+ REST endpoints** ready for mobile app consumption
- **JWT authentication** system in place
- **WebSocket support** available for real-time features

### 📱 Mobile App Features to Implement
- **Student Features**: Login, dashboard, attendance view, invoice view, notifications
- **Instructor Features**: Attendance marking, student management, schedules
- **Admin Features**: Analytics, user management, financial reports

### 📋 Notes for Future Sessions
- Project now has both backend and frontend properly separated
- Backend is fully functional and tested
- Frontend has clean architecture matching backend patterns
- Ready to implement API integration and UI screens
- All documentation is comprehensive and up-to-date
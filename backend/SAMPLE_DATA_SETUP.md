# 🎯 Chalak Sample Data Setup Guide

This guide will help you populate your Chalak backend database with realistic testing data for frontend development.

## 📋 Prerequisites

1. **Database Setup**
   ```bash
   # Option 1: Using Docker (Recommended)
   cd backend/
   docker compose up -d  # Start PostgreSQL and Redis

   # Option 2: Local PostgreSQL
   # Ensure PostgreSQL is running on localhost:5432
   # Database: chalak_db, User: chalak, Password: chalak123
   ```

2. **Run Migrations**
   ```bash
   cd backend/
   # Install golang-migrate if not available
   go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

   # Run migrations
   migrate -path migrations -database "postgres://chalak:chalak123@localhost:5432/chalak_db?sslmode=disable" up
   ```

3. **Start Backend Server**
   ```bash
   cd backend/
   go run cmd/api/main.go
   ```

## 🚀 Method 1: API Population (Recommended)

### Step 1: Start the Backend
```bash
cd backend/
go run cmd/api/main.go
```

You should see:
```
INFO starting chalak api server env=development port=8080
INFO database connection established
INFO redis connection established
INFO server listening addr=:8080
```

### Step 2: Test Health Endpoint
```bash
curl http://localhost:8080/health
# Expected: {"status":"ok","service":"chalak-api","version":"1.0.0"}
```

### Step 3: Run Data Population Script
```bash
cd backend/scripts/
go run populate_data.go
```

This will create:
- ✅ **1 Admin User** for login (admin@chalak.com / admin123)
- ✅ **8 Students** with diverse profiles and statuses
- ✅ **12 Attendance Records** with different statuses
- ✅ **5 Invoices** (paid, pending, overdue)
- ✅ **6 Employees** across different departments
- ✅ **6 Expense Records** with approval workflows
- ✅ **8 Notifications** for testing the notification system

## 🗃️ Method 2: Direct SQL Population

If the API method doesn't work, you can insert data directly:

```bash
# Connect to PostgreSQL
psql -h localhost -U chalak -d chalak_db

# Run the sample data script
\i scripts/sample_data.sql
```

## 🔐 Test Login Credentials

After data population, you can use these credentials:

### Admin Login
- **Email**: `admin@chalak.com`
- **Password**: `admin123`
- **Role**: `admin`

### API Authentication Test
```bash
# Login and get token
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@chalak.com", "password": "admin123"}'

# Use the returned access_token for authenticated requests
curl -X GET http://localhost:8080/api/v1/students \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 📊 Sample Data Overview

### Students (8 Total)
| Name | Email | Status | Enrollment Date |
|------|-------|--------|----------------|
| Alice Johnson | alice.johnson@email.com | active | 2024-01-15 |
| Bob Smith | bob.smith@email.com | active | 2024-01-20 |
| Carol Davis | carol.davis@email.com | active | 2024-02-01 |
| David Wilson | david.wilson@email.com | suspended | 2024-01-10 |
| Eva Brown | eva.brown@email.com | active | 2024-02-15 |
| Frank Miller | frank.miller@email.com | inactive | 2024-01-05 |
| Grace Taylor | grace.taylor@email.com | active | 2024-02-20 |
| Henry Anderson | henry.anderson@email.com | active | 2024-01-25 |

### Attendance Records
- **Alice Johnson**: Mostly present, one late arrival
- **Bob Smith**: Mixed record with one absence
- **Carol Davis**: Perfect attendance record
- Various check-in/out times for realistic testing

### Invoices (5 Total)
| Invoice # | Student | Amount | Status | Due Date |
|-----------|---------|--------|--------|----------|
| INV-2024-001 | Alice Johnson | $880.00 | paid | 2024-09-30 |
| INV-2024-002 | Bob Smith | $660.00 | pending | 2024-10-15 |
| INV-2024-003 | Carol Davis | $1,320.00 | paid | 2024-09-20 |
| INV-2024-004 | David Wilson | $495.00 | overdue | 2024-09-10 |
| INV-2024-005 | Eva Brown | $990.00 | pending | 2024-10-20 |

### Employees (6 Total)
- **John Smith** - Senior Driving Instructor ($55,000)
- **Sarah Johnson** - Operations Manager ($65,000)
- **Mike Davis** - Driving Instructor ($45,000)
- **Lisa Wilson** - Receptionist ($35,000)
- **Tom Brown** - Part-time Instructor ($25,000)
- **Emma Taylor** - Former Instructor (terminated)

### Expenses (6 Total)
- **Fuel**: $320.50 (approved)
- **Office Supplies**: $85.00 (pending)
- **Vehicle Maintenance**: $450.00 (approved)
- **Training Materials**: $150.00 (rejected)
- **Insurance**: $1,200.00 (pending)
- **Marketing**: $75.00 (approved)

### Notifications (8 Total)
- Welcome messages for new students
- Payment reminders
- Lesson reminders
- Attendance alerts
- Expense approval requests
- System notifications

## 🧪 Testing Frontend Integration

### 1. Authentication Flow
```bash
# Test login
POST /api/v1/auth/login
Body: {"email": "admin@chalak.com", "password": "admin123"}

# Test protected route
GET /api/v1/students
Headers: Authorization: Bearer <token>
```

### 2. Students Management
```bash
# List students
GET /api/v1/students

# Get specific student
GET /api/v1/students/{id}

# Create new student
POST /api/v1/students
```

### 3. Attendance Tracking
```bash
# List attendance
GET /api/v1/attendance

# Mark attendance
POST /api/v1/attendance
```

### 4. Invoice Management
```bash
# List invoices
GET /api/v1/invoices

# Mark invoice as paid
PUT /api/v1/invoices/{id}/pay
```

## 🎯 Frontend Testing Scenarios

With this sample data, you can test:

1. **Authentication**
   - Login with admin@chalak.com
   - Token validation
   - Protected route access

2. **Student Management**
   - View student list with different statuses
   - Student profile details
   - Search and filter functionality

3. **Attendance System**
   - QR code scanning simulation
   - Manual attendance marking
   - Attendance statistics

4. **Billing System**
   - Invoice creation and management
   - Payment status updates
   - Revenue calculations

5. **HR Management**
   - Employee profiles
   - Salary and department tracking
   - Employee status management

6. **Financial Tracking**
   - Expense submission
   - Approval workflows
   - Category-based reporting

7. **Notification System**
   - Unread notifications count
   - Different notification types
   - Mark as read functionality

## 🐛 Troubleshooting

### Backend Won't Start
```bash
# Check if PostgreSQL is running
pg_isready -h localhost -p 5432

# Check if Redis is running (optional)
redis-cli ping

# Check Go environment
go version
go mod tidy
```

### Database Connection Issues
```bash
# Verify database exists
psql -h localhost -U chalak -l

# Verify migrations
psql -h localhost -U chalak -d chalak_db -c "\dt"
```

### API Requests Failing
```bash
# Check server logs
# Verify CORS settings
# Check JWT token validity
```

## 📝 API Endpoints Summary

| Module | Endpoints | Description |
|--------|-----------|-------------|
| Auth | 4 endpoints | Login, register, refresh, profile |
| Students | 5 endpoints | CRUD operations |
| Attendance | 6 endpoints | Mark, view, stats |
| Invoices | 5 endpoints | Billing and payments |
| Employees | 6 endpoints | HR management |
| Expenses | 7 endpoints | Financial tracking |
| Notifications | 7 endpoints | Communication system |

## 🎉 Ready for Development!

After completing this setup, your backend will have realistic data for comprehensive frontend testing. The Flutter app can now connect to a fully populated system with:

- Multiple user roles and permissions
- Diverse student profiles and statuses
- Realistic attendance patterns
- Complete billing and payment workflows
- HR and employee management data
- Financial tracking and approval systems
- Multi-channel notification examples

Happy coding! 🚀
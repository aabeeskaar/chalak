## Chalak Backend - Implementation Guide

This guide explains the Clean Architecture implementation and how to extend the system with new modules.

## Architecture Summary

**Clean/Hexagonal Architecture** with 4 main layers:

```
1. Domain Layer (internal/domain/*/)
   - Entities: Core business objects
   - Repository Interfaces: Data access contracts
   - No external dependencies

2. Use Case Layer (internal/usecase/)
   - Business logic orchestration
   - Depends only on domain interfaces
   - Testable with mocks

3. Repository Layer (internal/repository/postgres/)
   - Implements domain repository interfaces
   - GORM/database specific code
   - Error handling and translation

4. Delivery Layer (internal/delivery/http/)
   - HTTP handlers (controllers)
   - Request/response DTOs
   - Input validation
   - Middleware
```

## Module Structure

Each feature module follows this pattern:

### 1. Domain Layer

**File: `internal/domain/{module}/entity.go`**

```go
package student

import (
    "time"
    "github.com/google/uuid"
)

// Entity - Core business object
type Student struct {
    ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key"`
    FirstName string    `json:"first_name" gorm:"type:varchar(100);not null"`
    // ... other fields
}

// TableName - GORM table mapping
func (Student) TableName() string {
    return "students"
}

// Request DTOs
type CreateStudentRequest struct {
    FirstName string `json:"first_name" validate:"required,min=2"`
    // ... validations
}
```

**File: `internal/domain/{module}/repository.go`**

```go
package student

import "context"

// Repository - Data access contract (interface)
type Repository interface {
    Create(ctx context.Context, student *Student) error
    FindByID(ctx context.Context, id uuid.UUID) (*Student, error)
    // ... other methods
}
```

### 2. Repository Implementation

**File: `internal/repository/postgres/{module}_repository.go`**

```go
package postgres

import (
    "context"
    "fmt"
    "github.com/chalak/backend/internal/domain/student"
    "gorm.io/gorm"
)

type StudentRepository struct {
    db *gorm.DB
}

// Constructor returns interface type
func NewStudentRepository(db *gorm.DB) student.Repository {
    return &StudentRepository{db: db}
}

func (r *StudentRepository) Create(ctx context.Context, s *student.Student) error {
    if err := r.db.WithContext(ctx).Create(s).Error; err != nil {
        return fmt.Errorf("failed to create student: %w", err)
    }
    return nil
}

func (r *StudentRepository) FindByID(ctx context.Context, id uuid.UUID) (*student.Student, error) {
    var s student.Student
    if err := r.db.WithContext(ctx).
        Where("id = ? AND deleted_at IS NULL", id).
        First(&s).Error; err != nil {
        if err == gorm.ErrRecordNotFound {
            return nil, fmt.Errorf("student not found")
        }
        return nil, fmt.Errorf("failed to find student: %w", err)
    }
    return &s, nil
}
```

### 3. Use Case Layer

**File: `internal/usecase/{module}_usecase.go`**

```go
package usecase

import (
    "context"
    "fmt"
    "github.com/chalak/backend/internal/domain/student"
    "github.com/chalak/backend/pkg/logger"
)

type StudentUseCase struct {
    repo   student.Repository  // Depends on interface, not implementation
    logger logger.Logger
}

// Constructor with dependency injection
func NewStudentUseCase(repo student.Repository, logger logger.Logger) *StudentUseCase {
    return &StudentUseCase{
        repo:   repo,
        logger: logger,
    }
}

func (uc *StudentUseCase) Create(ctx context.Context, req *student.CreateStudentRequest) (*student.Student, error) {
    // Business logic here
    s := &student.Student{
        ID:        uuid.New(),
        FirstName: req.FirstName,
        // ... map fields
        CreatedAt: time.Now().UTC(),
    }

    if err := uc.repo.Create(ctx, s); err != nil {
        uc.logger.Error(ctx, "failed to create student", map[string]interface{}{
            "error": err.Error(),
        })
        return nil, fmt.Errorf("failed to create student: %w", err)
    }

    uc.logger.Info(ctx, "student created", map[string]interface{}{
        "student_id": s.ID,
    })

    return s, nil
}
```

### 4. Handler Layer

**File: `internal/delivery/http/handler/{module}_handler.go`**

```go
package handler

import (
    "encoding/json"
    "net/http"
    "github.com/chalak/backend/internal/usecase"
    "github.com/chalak/backend/pkg/logger"
    "github.com/go-chi/chi/v5"
)

type StudentHandler struct {
    useCase *usecase.StudentUseCase
    logger  logger.Logger
}

func NewStudentHandler(useCase *usecase.StudentUseCase, logger logger.Logger) *StudentHandler {
    return &StudentHandler{
        useCase: useCase,
        logger:  logger,
    }
}

func (h *StudentHandler) Create(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var req student.CreateStudentRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        h.respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    s, err := h.useCase.Create(ctx, &req)
    if err != nil {
        h.respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    h.respondJSON(w, http.StatusCreated, s)
}

func (h *StudentHandler) respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(statusCode)
    json.NewEncoder(w).Encode(data)
}
```

### 5. Database Migration

**File: `migrations/000XXX_create_{module}_table.up.sql`**

```sql
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_deleted_at ON students(deleted_at);

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

**File: `migrations/000XXX_create_{module}_table.down.sql`**

```sql
DROP TRIGGER IF EXISTS update_students_updated_at ON students;
DROP INDEX IF EXISTS idx_students_email;
DROP TABLE IF EXISTS students;
```

### 6. Wire Up in main.go

```go
func (app *App) initializeHandlers() *Handlers {
    // Initialize repository
    studentRepo := postgres.NewStudentRepository(app.db.DB)

    // Initialize use case (inject dependencies)
    studentUseCase := usecase.NewStudentUseCase(studentRepo, app.logger)

    // Initialize handler (inject dependencies)
    studentHandler := handler.NewStudentHandler(studentUseCase, app.logger)

    return &Handlers{
        Student: studentHandler,
    }
}
```

### 7. Add Routes

**File: `internal/delivery/http/router/router.go`**

```go
func (r *Router) Setup() http.Handler {
    r.router.Route("/api/v1", func(rt chi.Router) {
        rt.Route("/students", func(rt chi.Router) {
            rt.Post("/", r.studentHandler.Create)
            rt.Get("/", r.studentHandler.List)
            rt.Get("/{id}", r.studentHandler.GetByID)
            rt.Put("/{id}", r.studentHandler.Update)
            rt.Delete("/{id}", r.studentHandler.Delete)
        })
    })

    return r.router
}
```

### 8. Unit Testing

**File: `internal/usecase/{module}_usecase_test.go`**

```go
package usecase_test

import (
    "context"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

// Mock repository
type MockStudentRepository struct {
    mock.Mock
}

func (m *MockStudentRepository) Create(ctx context.Context, s *student.Student) error {
    args := m.Called(ctx, s)
    return args.Error(0)
}

func TestStudentUseCase_Create(t *testing.T) {
    mockRepo := new(MockStudentRepository)
    mockLogger := &MockLogger{}
    uc := usecase.NewStudentUseCase(mockRepo, mockLogger)

    ctx := context.Background()

    t.Run("successful creation", func(t *testing.T) {
        req := &student.CreateStudentRequest{
            FirstName: "John",
            LastName:  "Doe",
            Email:     "john@example.com",
        }

        mockRepo.On("Create", ctx, mock.AnythingOfType("*student.Student")).Return(nil).Once()

        result, err := uc.Create(ctx, req)

        assert.NoError(t, err)
        assert.NotNil(t, result)
        assert.Equal(t, req.FirstName, result.FirstName)

        mockRepo.AssertExpectations(t)
    })
}
```

## Best Practices

### 1. Context Propagation
Always pass `context.Context` as the first parameter:
```go
func (uc *UseCase) DoSomething(ctx context.Context, param string) error
```

### 2. Error Wrapping
Use `fmt.Errorf` with `%w` to wrap errors:
```go
if err != nil {
    return fmt.Errorf("failed to create student: %w", err)
}
```

### 3. Structured Logging
Use structured logging with context:
```go
uc.logger.Info(ctx, "operation completed", map[string]interface{}{
    "user_id": userID,
    "duration_ms": elapsed.Milliseconds(),
})
```

### 4. Soft Deletes
Use `deleted_at` for soft deletes:
```go
query := db.Where("deleted_at IS NULL")
```

### 5. Repository Patterns
- Return domain errors, not database-specific errors
- Use transactions for multi-step operations
- Always use parameterized queries (GORM does this automatically)

### 6. Use Case Patterns
- Keep use cases focused (Single Responsibility)
- Inject all dependencies via constructor
- Validate business rules in use case, not handler
- Use transactions when modifying multiple entities

### 7. Handler Patterns
- Validate request structure
- Delegate business logic to use case
- Return consistent JSON responses
- Use HTTP status codes correctly

## Dependency Injection Benefits

### Testability
```go
// In tests, inject mocks
mockRepo := &MockRepo{}
useCase := NewUseCase(mockRepo, mockLogger)

// In production, inject real implementations
realRepo := postgres.NewRepo(db)
useCase := NewUseCase(realRepo, realLogger)
```

### Flexibility
Easy to swap implementations:
```go
// Switch from Postgres to MySQL
type Repository interface { /* same interface */ }

// Just change implementation
studentRepo := mysql.NewStudentRepository(db)  // Instead of postgres
```

### Microservices Migration
Each module can become a service:
```go
// Monolith
studentRepo := postgres.NewStudentRepository(db)

// Microservice
studentRepo := grpc.NewStudentClient(conn)  // Same interface, different implementation
```

## Background Jobs with Asynq

### Define Task
```go
package tasks

import (
    "context"
    "encoding/json"
    "github.com/hibiken/asynq"
)

const TypeEmailDelivery = "email:deliver"

type EmailPayload struct {
    To      string
    Subject string
    Body    string
}

func NewEmailDeliveryTask(to, subject, body string) (*asynq.Task, error) {
    payload, err := json.Marshal(EmailPayload{
        To:      to,
        Subject: subject,
        Body:    body,
    })
    if err != nil {
        return nil, err
    }
    return asynq.NewTask(TypeEmailDelivery, payload), nil
}

func HandleEmailDelivery(ctx context.Context, t *asynq.Task) error {
    var p EmailPayload
    if err := json.Unmarshal(t.Payload(), &p); err != nil {
        return err
    }

    // Send email logic here
    return nil
}
```

### Enqueue Task
```go
task, err := tasks.NewEmailDeliveryTask("user@example.com", "Welcome", "Hello!")
if err != nil {
    return err
}

err = queueClient.Enqueue(ctx, task, asynq.Queue("default"))
```

### Register Handler
```go
queueServer.RegisterHandler(tasks.TypeEmailDelivery, tasks.HandleEmailDelivery)
```

## API Examples

### Register User
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe",
    "role": "student"
  }'
```

### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Create Student (with JWT)
```bash
curl -X POST http://localhost:8080/api/v1/students \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access_token>" \
  -d '{
    "first_name": "Jane",
    "last_name": "Smith",
    "email": "jane@example.com",
    "phone": "1234567890",
    "date_of_birth": "2000-01-01T00:00:00Z",
    "institute_id": "123e4567-e89b-12d3-a456-426614174000"
  }'
```

## Running the Application

```bash
# Install dependencies
go mod download

# Run migrations
make migrate-up

# Run application
go run cmd/api/main.go

# Or use the improved version
go run cmd/api/main_improved.go

# Run tests
go test -v ./...

# Run tests with coverage
go test -v -race -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Environment Setup

Create `.env` file:
```env
# Server
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=chalak
DB_PASSWORD=chalak123
DB_NAME=chalak_db
DB_SSL_MODE=disable

# Redis (optional)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT
JWT_SECRET=your-super-secret-key
JWT_EXPIRY_HOURS=24
JWT_REFRESH_EXPIRY_HOURS=168

# Logging
LOG_LEVEL=debug
```

## Next Steps

1. **Add More Modules**: Follow the pattern above to add:
   - Classes/Courses
   - Instructors
   - Payments
   - Reports
   - Schedules

2. **Add Middleware**:
   - Rate limiting
   - Request ID tracing
   - CORS configuration
   - API versioning

3. **Add Features**:
   - File upload/download
   - Email notifications
   - SMS integration
   - Push notifications
   - Report generation (PDF)

4. **Improve Testing**:
   - Integration tests
   - E2E tests
   - Load testing
   - Security testing

5. **Add Monitoring**:
   - Prometheus metrics
   - Health check endpoints
   - Distributed tracing
   - Error tracking (Sentry)

6. **DevOps**:
   - Docker containers
   - Kubernetes deployment
   - CI/CD pipeline
   - Database backups
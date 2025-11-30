# Chalak Backend Architecture

## Architecture Overview

This project follows **Clean/Hexagonal Architecture** principles with a feature-based modular design, enabling future microservices extraction.

### Core Principles

1. **Dependency Rule**: Dependencies point inward (Delivery → UseCase → Domain)
2. **Domain Independence**: Business logic has no external dependencies
3. **Interface Segregation**: Each layer defines its own interfaces
4. **Dependency Injection**: All dependencies injected via constructors

## Technology Stack

- **Go 1.23+**: Latest Go features and performance
- **Chi**: Lightweight, idiomatic HTTP router with middleware support
- **GORM**: ORM for PostgreSQL with auto-migrations and query builder
- **golang-migrate**: Version-controlled database migrations
- **JWT (golang-jwt/jwt)**: Stateless authentication
- **Viper**: Configuration management with env/file support
- **Zerolog**: High-performance structured logging
- **Redis**: Caching layer (optional) and session store
- **Asynq**: Distributed task queue for background jobs
- **testify**: Testing framework with mocks and assertions

## Project Structure

```
chalak/
├── cmd/
│   └── api/
│       └── main.go                 # Application entry point
├── internal/
│   ├── domain/                     # Enterprise business rules
│   │   ├── student/
│   │   │   ├── entity.go          # Domain entities
│   │   │   └── repository.go      # Repository interface
│   │   ├── attendance/
│   │   ├── invoice/
│   │   ├── employee/
│   │   └── ...
│   ├── usecase/                    # Application business rules
│   │   ├── student_usecase.go
│   │   ├── attendance_usecase.go
│   │   └── ...
│   ├── repository/                 # Data access implementations
│   │   └── postgres/
│   │       ├── student_repository.go
│   │       └── ...
│   ├── delivery/                   # External interfaces
│   │   └── http/
│   │       ├── handler/
│   │       ├── middleware/
│   │       └── router/
│   └── config/                     # Configuration loader
├── pkg/                            # Reusable packages
│   ├── auth/                       # JWT service
│   ├── cache/                      # Redis client
│   ├── database/                   # Database connection
│   ├── logger/                     # Structured logger
│   ├── queue/                      # Asynq task queue
│   ├── validator/                  # Request validation
│   └── errors/                     # Custom error types
├── migrations/                     # Database migrations
├── config/                         # Configuration files
└── tests/                          # Integration tests
```

## Layer Responsibilities

### 1. Domain Layer (`internal/domain`)

**Purpose**: Core business entities and rules

- Defines entities (structs with business rules)
- Defines repository interfaces (contracts)
- No external dependencies (only stdlib and domain types)
- Completely testable without infrastructure

**Example**: `student.Entity`, `student.Repository`

### 2. Use Case Layer (`internal/usecase`)

**Purpose**: Application business logic and orchestration

- Implements business workflows
- Coordinates between repositories
- Handles transactions
- Depends only on domain interfaces
- Uses dependency injection

**Example**: `StudentUseCase` implements CRUD + business rules

### 3. Repository Layer (`internal/repository`)

**Purpose**: Data persistence implementations

- Implements domain repository interfaces
- GORM queries and transactions
- Database-specific logic
- Error translation to domain errors

**Example**: `postgres.StudentRepository` implements `student.Repository`

### 4. Delivery Layer (`internal/delivery`)

**Purpose**: External communication (HTTP, gRPC, CLI)

- HTTP handlers (controllers)
- Request/response DTOs
- Input validation
- Middleware (auth, logging, CORS)
- Routes definition

**Example**: `StudentHandler` exposes REST endpoints

### 5. Infrastructure (`pkg`)

**Purpose**: Shared utilities and external service wrappers

- Database connections
- Caching
- Authentication
- Logging
- Background jobs
- Email/SMS services

## Dependency Flow

```
main.go
  ↓
[Infrastructure Setup]
  ↓ (inject)
[Repositories]
  ↓ (inject)
[Use Cases]
  ↓ (inject)
[Handlers]
  ↓
[Router]
```

## Module Design Pattern

Each feature module follows this structure:

```go
// 1. Domain Entity (internal/domain/module/entity.go)
type Entity struct { /* fields */ }

// 2. Repository Interface (internal/domain/module/repository.go)
type Repository interface {
    Create(ctx context.Context, entity *Entity) error
    // ... other methods
}

// 3. Use Case (internal/usecase/module_usecase.go)
type UseCase struct {
    repo   domain.Repository
    logger logger.Logger
}

// 4. Repository Implementation (internal/repository/postgres/module_repository.go)
type Repository struct {
    db *gorm.DB
}

// 5. Handler (internal/delivery/http/handler/module_handler.go)
type Handler struct {
    useCase usecase.UseCase
    logger  logger.Logger
}
```

## Key Patterns Explained

### 1. Dependency Injection

**Why**: Loose coupling, testability, flexibility

```go
// Constructor injection (not field injection)
func NewStudentUseCase(repo student.Repository, logger logger.Logger) *StudentUseCase {
    return &StudentUseCase{
        repo:   repo,
        logger: logger,
    }
}
```

### 2. Repository Pattern

**Why**: Abstract data access, easier to test, swap implementations

```go
// Domain defines interface
type Repository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*Student, error)
}

// Postgres implements it
type PostgresRepo struct { db *gorm.DB }
func (r *PostgresRepo) FindByID(ctx context.Context, id uuid.UUID) (*Student, error)
```

### 3. Context Propagation

**Why**: Cancellation, timeouts, request-scoped values

```go
// Always pass context as first parameter
func (uc *StudentUseCase) GetByID(ctx context.Context, id uuid.UUID) (*Student, error)
```

### 4. Error Wrapping

**Why**: Maintain error chain, add context

```go
if err != nil {
    return fmt.Errorf("failed to create student: %w", err)
}
```

### 5. Structured Logging

**Why**: Machine-parseable logs, better debugging

```go
logger.Info(ctx, "student created", map[string]interface{}{
    "student_id": student.ID,
    "email":      student.Email,
})
```

## Testing Strategy

### Unit Tests
- Use Cases: Mock repositories with testify/mock
- Handlers: Mock use cases
- Repositories: Use test database or SQLite

### Integration Tests
- Full HTTP flow with test database
- Test migrations and queries
- Test background jobs

## Scalability to Microservices

The architecture supports gradual extraction:

1. **Phase 1**: Monolith with modular design (current)
2. **Phase 2**: Shared database, separate services
3. **Phase 3**: Database per service, event-driven

Each module can become a microservice by:
- Extracting `domain + usecase + repository + delivery`
- Adding inter-service communication (HTTP/gRPC/messaging)
- Keeping clean boundaries ensures minimal refactoring

## Background Jobs with Asynq

Asynq provides:
- Reliable task execution
- Retries with exponential backoff
- Task scheduling
- Monitoring UI

Use cases:
- Email notifications
- Invoice generation
- Report processing
- Data synchronization

## Configuration Management

Viper loads config from:
1. `config/config.yaml` (defaults)
2. Environment variables (overrides)
3. `.env` file (local development)

Priority: ENV > .env > config.yaml

## API Design

- RESTful conventions
- JSON responses
- JWT Bearer authentication
- Structured error responses
- Pagination for lists
- CORS enabled

## Security Practices

- JWT with short expiry + refresh tokens
- Password hashing with bcrypt
- SQL injection prevention (GORM parameterized queries)
- XSS prevention (proper content types)
- Rate limiting (middleware)
- Request ID tracing
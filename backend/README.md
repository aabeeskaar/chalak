# Chalak - Driving Institute Management System

A scalable backend system for managing driving institutes, built with Go using Clean/Hexagonal Architecture.

## Architecture Overview

The project follows Clean Architecture principles with clear separation of concerns:

```
cmd/api/                    # Application entry points
internal/
  ├── domain/              # Business entities and repository interfaces (Domain Layer)
  │   └── student/
  ├── usecase/             # Business logic/use cases (Application Layer)
  ├── repository/          # Data access implementations (Infrastructure Layer)
  │   └── postgres/
  ├── delivery/            # HTTP handlers, middleware, routing (Presentation Layer)
  │   └── http/
  └── config/              # Configuration management
pkg/                        # Shared packages (reusable across projects)
  ├── auth/                # JWT authentication
  ├── cache/               # Redis cache client
  ├── database/            # Database connection
  └── logger/              # Structured logging
migrations/                 # Database migrations
```

## Key Design Decisions

### 1. **Clean Architecture / Hexagonal Architecture**
- **Domain Layer**: Contains business entities and repository interfaces. No external dependencies.
- **Use Case Layer**: Contains business logic, coordinates between domain and infrastructure.
- **Infrastructure Layer**: Implements repository interfaces, database access.
- **Presentation Layer**: HTTP handlers, routes, middleware.

**Why**: Allows easy testing, swapping implementations, and future microservices migration.

### 2. **Dependency Injection**
All dependencies are injected through constructors in `cmd/api/main.go`.

**Why**: Makes testing easier, reduces coupling, enables runtime configuration.

### 3. **Interface-based Repository Pattern**
Repository interfaces defined in domain package, implemented in infrastructure.

**Why**: Domain logic doesn't depend on specific database implementation.

### 4. **Context Propagation**
All operations accept `context.Context` as first parameter.

**Why**: Enables request cancellation, timeout handling, and tracing.

### 5. **Structured Logging with Zerolog**
Uses Zerolog for fast, structured JSON logging.

**Why**: Better performance than standard library, structured logs for easy parsing.

### 6. **Error Wrapping**
Uses `fmt.Errorf` with `%w` for error context.

**Why**: Maintains error chain for debugging while adding context.

### 7. **GORM for Database ORM**
Uses GORM v2 with PostgreSQL driver.

**Why**: Mature ORM with excellent PostgreSQL support, reduces boilerplate.

### 8. **Chi Router**
Uses go-chi/chi for HTTP routing.

**Why**: Lightweight, idiomatic Go, excellent middleware support.

### 9. **JWT Authentication**
Custom JWT service in pkg/auth with golang-jwt/jwt.

**Why**: Stateless authentication, scalable for microservices.

### 10. **Redis for Caching**
Redis client wrapper in pkg/cache.

**Why**: Fast caching layer, supports background jobs with Asynq.

## Tech Stack

- **Go 1.23+**
- **Chi Router** - HTTP routing and middleware
- **GORM** - ORM for PostgreSQL
- **PostgreSQL 16** - Primary database
- **Redis 7** - Caching and background jobs
- **Zerolog** - Structured logging
- **JWT** - Authentication
- **Viper** - Configuration management
- **Testify** - Testing framework
- **golang-migrate** - Database migrations

## Getting Started

### Prerequisites

- Go 1.23 or higher
- Docker and Docker Compose (for PostgreSQL and Redis)
- golang-migrate CLI (for migrations)

### Installation

1. Clone the repository:
```bash
cd Chalak
```

2. Copy environment configuration:
```bash
cp .env.example .env
```

3. Install dependencies:
```bash
go mod download
```

4. Start infrastructure services:
```bash
make docker-up
```

5. Run database migrations:
```bash
make migrate-up
```

6. Run the application:
```bash
make run
```

The API will be available at `http://localhost:8080`

## API Endpoints

### Health Check
```
GET /health
```

### Students Module

All student endpoints require JWT authentication via `Authorization: Bearer <token>` header.

```
POST   /api/v1/students          # Create student
GET    /api/v1/students          # List students (with pagination and filters)
GET    /api/v1/students/:id      # Get student by ID
PUT    /api/v1/students/:id      # Update student
DELETE /api/v1/students/:id      # Delete student (soft delete)
```

#### Example: Create Student
```bash
curl -X POST http://localhost:8080/api/v1/students \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "date_of_birth": "2000-01-01T00:00:00Z",
    "address": "123 Main St",
    "institute_id": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

#### Example: List Students with Filters
```bash
curl "http://localhost:8080/api/v1/students?status=active&limit=20&page=1&search=john" \
  -H "Authorization: Bearer <token>"
```

## Testing

Run all tests:
```bash
make test
```

Run tests with coverage:
```bash
go test -v -race -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Database Migrations

Create a new migration:
```bash
make migrate-create NAME=create_users_table
```

Run migrations:
```bash
make migrate-up
```

Rollback last migration:
```bash
make migrate-down
```

## Project Structure Details

### Domain Layer (`internal/domain/`)
- Contains business entities (Student, Attendance, Invoice, etc.)
- Repository interfaces (contracts)
- Pure business logic, no external dependencies

### Use Case Layer (`internal/usecase/`)
- Orchestrates business workflows
- Implements business rules
- Depends only on domain interfaces

### Repository Layer (`internal/repository/`)
- Implements domain repository interfaces
- Database queries and data mapping
- GORM-based PostgreSQL implementation

### Delivery Layer (`internal/delivery/http/`)
- HTTP handlers convert requests to use case calls
- Middleware for auth, logging, CORS
- Request/response DTOs

### Shared Packages (`pkg/`)
- Reusable components across modules
- Can be extracted to separate libraries
- No business logic

## Next Steps

To expand the system, replicate the Student module pattern:

1. **Create domain entities** in `internal/domain/<module>/`
2. **Define repository interface** in domain package
3. **Implement repository** in `internal/repository/postgres/`
4. **Create use case** in `internal/usecase/`
5. **Add HTTP handlers** in `internal/delivery/http/handler/`
6. **Wire dependencies** in `cmd/api/main.go`
7. **Create migration** in `migrations/`
8. **Write tests** using testify mocks

### Planned Modules
- Authentication & Authorization
- Attendance Management
- Invoicing & Payments
- HR & Staff Management
- Expenses Tracking
- Notifications (Email/SMS)
- Scheduling & Calendar

## Contributing

1. Follow existing code structure and patterns
2. Write unit tests for new features
3. Use meaningful commit messages
4. Ensure migrations are reversible

## License

MIT License
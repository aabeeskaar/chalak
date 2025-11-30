package employee

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, employee *Employee) error
	FindByID(ctx context.Context, id uuid.UUID) (*Employee, error)
	FindByEmail(ctx context.Context, email string) (*Employee, error)
	Update(ctx context.Context, employee *Employee) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter EmployeeFilter) ([]*Employee, int64, error)
	Terminate(ctx context.Context, id uuid.UUID, terminationDate time.Time) error
}
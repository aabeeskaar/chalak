package course

import (
	"context"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, course *Course) error
	GetByID(ctx context.Context, id uuid.UUID) (*Course, error)
	GetByCode(ctx context.Context, code string) (*Course, error)
	Update(ctx context.Context, course *Course) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter CourseFilter) ([]*Course, int, error)
}

package student

import (
	"context"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, student *Student) error
	GetByID(ctx context.Context, id uuid.UUID) (*Student, error)
	GetByEmail(ctx context.Context, email string) (*Student, error)
	Update(ctx context.Context, student *Student) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter StudentFilter) ([]*Student, int64, error)
	ExistsByEmail(ctx context.Context, email string) (bool, error)
}
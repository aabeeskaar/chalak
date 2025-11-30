package pkg

import (
	"context"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, pkg *Package) error
	GetByID(ctx context.Context, id uuid.UUID) (*Package, error)
	GetByCode(ctx context.Context, code string) (*Package, error)
	Update(ctx context.Context, pkg *Package) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter PackageFilter) ([]*Package, int, error)
	AddCourse(ctx context.Context, packageID, courseID uuid.UUID) error
	RemoveCourse(ctx context.Context, packageID, courseID uuid.UUID) error
	GetCourses(ctx context.Context, packageID uuid.UUID) ([]uuid.UUID, error)
}

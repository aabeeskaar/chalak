package postgres

import (
	"context"
	"fmt"

	pkg "github.com/chalak/backend/internal/domain/package"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type packageRepository struct {
	db *gorm.DB
}

func NewPackageRepository(db *gorm.DB) pkg.Repository {
	return &packageRepository{db: db}
}

func (r *packageRepository) Create(ctx context.Context, p *pkg.Package) error {
	return r.db.WithContext(ctx).Create(p).Error
}

func (r *packageRepository) GetByID(ctx context.Context, id uuid.UUID) (*pkg.Package, error) {
	var p pkg.Package
	err := r.db.WithContext(ctx).
		Preload("Courses").
		Where("id = ? AND deleted_at IS NULL", id).
		First(&p).Error
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *packageRepository) GetByCode(ctx context.Context, code string) (*pkg.Package, error) {
	var p pkg.Package
	err := r.db.WithContext(ctx).
		Preload("Courses").
		Where("code = ? AND deleted_at IS NULL", code).
		First(&p).Error
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *packageRepository) Update(ctx context.Context, p *pkg.Package) error {
	return r.db.WithContext(ctx).Save(p).Error
}

func (r *packageRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&pkg.Package{}).
		Where("id = ?", id).
		Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP")).
		Error
}

func (r *packageRepository) List(ctx context.Context, filter pkg.PackageFilter) ([]*pkg.Package, int, error) {
	var packages []*pkg.Package
	var total int64

	query := r.db.WithContext(ctx).Model(&pkg.Package{}).Where("deleted_at IS NULL")

	if filter.Search != "" {
		searchPattern := fmt.Sprintf("%%%s%%", filter.Search)
		query = query.Where("name ILIKE ? OR code ILIKE ? OR description ILIKE ?",
			searchPattern, searchPattern, searchPattern)
	}

	if filter.IsActive != nil {
		query = query.Where("is_active = ?", *filter.IsActive)
	}

	if filter.MinPrice != nil {
		query = query.Where("price >= ?", *filter.MinPrice)
	}

	if filter.MaxPrice != nil {
		query = query.Where("price <= ?", *filter.MaxPrice)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}

	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	query = query.Preload("Courses").Order("created_at DESC")

	if err := query.Find(&packages).Error; err != nil {
		return nil, 0, err
	}

	return packages, int(total), nil
}

func (r *packageRepository) AddCourse(ctx context.Context, packageID, courseID uuid.UUID) error {
	packageCourse := &pkg.PackageCourse{
		PackageID: packageID,
		CourseID:  courseID,
	}
	return r.db.WithContext(ctx).Create(packageCourse).Error
}

func (r *packageRepository) RemoveCourse(ctx context.Context, packageID, courseID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Where("package_id = ? AND course_id = ?", packageID, courseID).
		Delete(&pkg.PackageCourse{}).
		Error
}

func (r *packageRepository) GetCourses(ctx context.Context, packageID uuid.UUID) ([]uuid.UUID, error) {
	var packageCourses []pkg.PackageCourse
	err := r.db.WithContext(ctx).
		Where("package_id = ?", packageID).
		Find(&packageCourses).Error
	if err != nil {
		return nil, err
	}

	courseIDs := make([]uuid.UUID, len(packageCourses))
	for i, pc := range packageCourses {
		courseIDs[i] = pc.CourseID
	}

	return courseIDs, nil
}

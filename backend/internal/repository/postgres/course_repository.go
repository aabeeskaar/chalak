package postgres

import (
	"context"
	"fmt"

	"github.com/chalak/backend/internal/domain/course"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type courseRepository struct {
	db *gorm.DB
}

func NewCourseRepository(db *gorm.DB) course.Repository {
	return &courseRepository{db: db}
}

func (r *courseRepository) Create(ctx context.Context, c *course.Course) error {
	if err := r.db.WithContext(ctx).Create(c).Error; err != nil {
		return fmt.Errorf("failed to create course: %w", err)
	}
	return nil
}

func (r *courseRepository) GetByID(ctx context.Context, id uuid.UUID) (*course.Course, error) {
	var c course.Course
	if err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&c).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("course not found")
		}
		return nil, fmt.Errorf("failed to get course: %w", err)
	}
	return &c, nil
}

func (r *courseRepository) GetByCode(ctx context.Context, code string) (*course.Course, error) {
	var c course.Course
	if err := r.db.WithContext(ctx).Where("code = ? AND deleted_at IS NULL", code).First(&c).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("course not found")
		}
		return nil, fmt.Errorf("failed to get course: %w", err)
	}
	return &c, nil
}

func (r *courseRepository) Update(ctx context.Context, c *course.Course) error {
	result := r.db.WithContext(ctx).Model(c).Where("id = ? AND deleted_at IS NULL", c.ID).Updates(c)
	if result.Error != nil {
		return fmt.Errorf("failed to update course: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return fmt.Errorf("course not found or already deleted")
	}
	return nil
}

func (r *courseRepository) Delete(ctx context.Context, id uuid.UUID) error {
	result := r.db.WithContext(ctx).Model(&course.Course{}).Where("id = ?", id).Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP"))
	if result.Error != nil {
		return fmt.Errorf("failed to delete course: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return fmt.Errorf("course not found")
	}
	return nil
}

func (r *courseRepository) List(ctx context.Context, filter course.CourseFilter) ([]*course.Course, int, error) {
	var courses []*course.Course
	var total int64

	query := r.db.WithContext(ctx).Model(&course.Course{}).Where("deleted_at IS NULL")

	if filter.IsActive != nil {
		query = query.Where("is_active = ?", *filter.IsActive)
	}

	if filter.Search != "" {
		searchPattern := "%" + filter.Search + "%"
		query = query.Where(
			"name ILIKE ? OR code ILIKE ? OR description ILIKE ?",
			searchPattern, searchPattern, searchPattern,
		)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count courses: %w", err)
	}

	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}
	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	query = query.Order("created_at DESC")

	if err := query.Find(&courses).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to list courses: %w", err)
	}

	return courses, int(total), nil
}

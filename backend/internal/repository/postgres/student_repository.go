package postgres

import (
	"context"
	"fmt"

	"github.com/chalak/backend/internal/domain/student"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type studentRepository struct {
	db *gorm.DB
}

func NewStudentRepository(db *gorm.DB) student.Repository {
	return &studentRepository{db: db}
}

func (r *studentRepository) Create(ctx context.Context, s *student.Student) error {
	if err := r.db.WithContext(ctx).Create(s).Error; err != nil {
		return fmt.Errorf("failed to create student: %w", err)
	}
	return nil
}

func (r *studentRepository) GetByID(ctx context.Context, id uuid.UUID) (*student.Student, error) {
	var s student.Student
	if err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&s).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("student not found")
		}
		return nil, fmt.Errorf("failed to get student: %w", err)
	}
	return &s, nil
}

func (r *studentRepository) GetByEmail(ctx context.Context, email string) (*student.Student, error) {
	var s student.Student
	if err := r.db.WithContext(ctx).Where("email = ? AND deleted_at IS NULL", email).First(&s).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("student not found")
		}
		return nil, fmt.Errorf("failed to get student: %w", err)
	}
	return &s, nil
}

func (r *studentRepository) Update(ctx context.Context, s *student.Student) error {
	result := r.db.WithContext(ctx).Model(s).Where("id = ? AND deleted_at IS NULL", s.ID).Updates(s)
	if result.Error != nil {
		return fmt.Errorf("failed to update student: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return fmt.Errorf("student not found or already deleted")
	}
	return nil
}

func (r *studentRepository) Delete(ctx context.Context, id uuid.UUID) error {
	result := r.db.WithContext(ctx).Model(&student.Student{}).Where("id = ?", id).Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP"))
	if result.Error != nil {
		return fmt.Errorf("failed to delete student: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return fmt.Errorf("student not found")
	}
	return nil
}

func (r *studentRepository) List(ctx context.Context, filter student.StudentFilter) ([]*student.Student, int64, error) {
	var students []*student.Student
	var total int64

	query := r.db.WithContext(ctx).Model(&student.Student{}).Where("deleted_at IS NULL")

	if filter.InstituteID != nil {
		query = query.Where("institute_id = ?", *filter.InstituteID)
	}

	if filter.Status != nil {
		query = query.Where("status = ?", *filter.Status)
	}

	if filter.Search != nil && *filter.Search != "" {
		searchPattern := "%" + *filter.Search + "%"
		query = query.Where(
			"first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
			searchPattern, searchPattern, searchPattern,
		)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count students: %w", err)
	}

	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}
	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	query = query.Order("created_at DESC")

	if err := query.Find(&students).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to list students: %w", err)
	}

	return students, total, nil
}

func (r *studentRepository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	var count int64
	if err := r.db.WithContext(ctx).Model(&student.Student{}).
		Where("email = ? AND deleted_at IS NULL", email).
		Count(&count).Error; err != nil {
		return false, fmt.Errorf("failed to check email existence: %w", err)
	}
	return count > 0, nil
}
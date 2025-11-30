package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/employee"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type EmployeeRepository struct {
	db *gorm.DB
}

func NewEmployeeRepository(db *gorm.DB) employee.Repository {
	return &EmployeeRepository{db: db}
}

func (r *EmployeeRepository) Create(ctx context.Context, emp *employee.Employee) error {
	if err := r.db.WithContext(ctx).Create(emp).Error; err != nil {
		return fmt.Errorf("failed to create employee: %w", err)
	}
	return nil
}

func (r *EmployeeRepository) FindByID(ctx context.Context, id uuid.UUID) (*employee.Employee, error) {
	var emp employee.Employee
	if err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&emp).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("employee not found")
		}
		return nil, fmt.Errorf("failed to find employee: %w", err)
	}
	return &emp, nil
}

func (r *EmployeeRepository) FindByEmail(ctx context.Context, email string) (*employee.Employee, error) {
	var emp employee.Employee
	if err := r.db.WithContext(ctx).Where("email = ? AND deleted_at IS NULL", email).First(&emp).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("employee not found")
		}
		return nil, fmt.Errorf("failed to find employee: %w", err)
	}
	return &emp, nil
}

func (r *EmployeeRepository) Update(ctx context.Context, emp *employee.Employee) error {
	if err := r.db.WithContext(ctx).Save(emp).Error; err != nil {
		return fmt.Errorf("failed to update employee: %w", err)
	}
	return nil
}

func (r *EmployeeRepository) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.db.WithContext(ctx).Model(&employee.Employee{}).Where("id = ?", id).Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP")).Error; err != nil {
		return fmt.Errorf("failed to delete employee: %w", err)
	}
	return nil
}

func (r *EmployeeRepository) List(ctx context.Context, filter employee.EmployeeFilter) ([]*employee.Employee, int64, error) {
	var employees []*employee.Employee
	var total int64

	query := r.db.WithContext(ctx).Model(&employee.Employee{}).Where("deleted_at IS NULL")

	if filter.InstituteID != nil {
		query = query.Where("institute_id = ?", *filter.InstituteID)
	}

	if filter.Department != nil {
		query = query.Where("department = ?", *filter.Department)
	}

	if filter.Position != nil {
		query = query.Where("position = ?", *filter.Position)
	}

	if filter.Status != nil {
		query = query.Where("status = ?", *filter.Status)
	}

	if filter.Search != nil {
		search := "%" + *filter.Search + "%"
		query = query.Where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", search, search, search)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count employees: %w", err)
	}

	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}
	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	if err := query.Order("first_name ASC, last_name ASC").Find(&employees).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to list employees: %w", err)
	}

	return employees, total, nil
}

func (r *EmployeeRepository) Terminate(ctx context.Context, id uuid.UUID, terminationDate time.Time) error {
	if err := r.db.WithContext(ctx).Model(&employee.Employee{}).Where("id = ?", id).Updates(map[string]interface{}{
		"status":        employee.StatusTerminated,
		"terminated_at": terminationDate,
	}).Error; err != nil {
		return fmt.Errorf("failed to terminate employee: %w", err)
	}
	return nil
}
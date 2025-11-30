package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/employee"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type EmployeeUseCase struct {
	repo   employee.Repository
	logger logger.Logger
}

func NewEmployeeUseCase(repo employee.Repository, logger logger.Logger) *EmployeeUseCase {
	return &EmployeeUseCase{
		repo:   repo,
		logger: logger,
	}
}

func (uc *EmployeeUseCase) Create(ctx context.Context, req *employee.CreateEmployeeRequest) (*employee.Employee, error) {
	// Check if email already exists
	if existingEmp, _ := uc.repo.FindByEmail(ctx, req.Email); existingEmp != nil {
		return nil, apperrors.BadRequest("employee with this email already exists")
	}

	emp := &employee.Employee{
		ID:          uuid.New(),
		FirstName:   req.FirstName,
		LastName:    req.LastName,
		Email:       req.Email,
		Phone:       req.Phone,
		Position:    req.Position,
		Department:  req.Department,
		InstituteID: req.InstituteID,
		Salary:      req.Salary,
		HireDate:    req.HireDate,
		Status:      employee.StatusActive,
		Address:     req.Address,
		CreatedAt:   time.Now().UTC(),
		UpdatedAt:   time.Now().UTC(),
	}

	if err := uc.repo.Create(ctx, emp); err != nil {
		uc.logger.Error(ctx, "failed to create employee", err, map[string]interface{}{
			"email": req.Email,
		})
		return nil, fmt.Errorf("failed to create employee: %w", err)
	}

	uc.logger.Info(ctx, "employee created", map[string]interface{}{
		"employee_id": emp.ID,
		"email":       emp.Email,
	})

	return emp, nil
}

func (uc *EmployeeUseCase) GetByID(ctx context.Context, id uuid.UUID) (*employee.Employee, error) {
	emp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("employee not found")
	}
	return emp, nil
}

func (uc *EmployeeUseCase) GetByEmail(ctx context.Context, email string) (*employee.Employee, error) {
	emp, err := uc.repo.FindByEmail(ctx, email)
	if err != nil {
		return nil, apperrors.NotFound("employee not found")
	}
	return emp, nil
}

func (uc *EmployeeUseCase) Update(ctx context.Context, id uuid.UUID, req *employee.UpdateEmployeeRequest) (*employee.Employee, error) {
	emp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("employee not found")
	}

	if req.FirstName != nil {
		emp.FirstName = *req.FirstName
	}
	if req.LastName != nil {
		emp.LastName = *req.LastName
	}
	if req.Phone != nil {
		emp.Phone = *req.Phone
	}
	if req.Position != nil {
		emp.Position = *req.Position
	}
	if req.Department != nil {
		emp.Department = *req.Department
	}
	if req.Salary != nil {
		emp.Salary = *req.Salary
	}
	if req.Status != nil {
		emp.Status = *req.Status
	}
	if req.Address != nil {
		emp.Address = *req.Address
	}

	emp.UpdatedAt = time.Now().UTC()

	if err := uc.repo.Update(ctx, emp); err != nil {
		uc.logger.Error(ctx, "failed to update employee", err, map[string]interface{}{
			"employee_id": id,
		})
		return nil, fmt.Errorf("failed to update employee: %w", err)
	}

	uc.logger.Info(ctx, "employee updated", map[string]interface{}{
		"employee_id": emp.ID,
	})

	return emp, nil
}

func (uc *EmployeeUseCase) Delete(ctx context.Context, id uuid.UUID) error {
	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete employee", err, map[string]interface{}{
			"employee_id": id,
		})
		return fmt.Errorf("failed to delete employee: %w", err)
	}

	uc.logger.Info(ctx, "employee deleted", map[string]interface{}{
		"employee_id": id,
	})

	return nil
}

func (uc *EmployeeUseCase) List(ctx context.Context, filter employee.EmployeeFilter) ([]*employee.Employee, int64, error) {
	employees, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list employees", err, nil)
		return nil, 0, fmt.Errorf("failed to list employees: %w", err)
	}

	return employees, total, nil
}

func (uc *EmployeeUseCase) Terminate(ctx context.Context, id uuid.UUID) error {
	emp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return apperrors.NotFound("employee not found")
	}

	if emp.Status == employee.StatusTerminated {
		return apperrors.BadRequest("employee is already terminated")
	}

	terminationDate := time.Now().UTC()
	if err := uc.repo.Terminate(ctx, id, terminationDate); err != nil {
		uc.logger.Error(ctx, "failed to terminate employee", err, map[string]interface{}{
			"employee_id": id,
		})
		return fmt.Errorf("failed to terminate employee: %w", err)
	}

	uc.logger.Info(ctx, "employee terminated", map[string]interface{}{
		"employee_id": id,
	})

	return nil
}
package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/student"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type StudentUseCase interface {
	CreateStudent(ctx context.Context, req student.CreateStudentRequest) (*student.Student, error)
	GetStudent(ctx context.Context, id uuid.UUID) (*student.Student, error)
	UpdateStudent(ctx context.Context, id uuid.UUID, req student.UpdateStudentRequest) (*student.Student, error)
	DeleteStudent(ctx context.Context, id uuid.UUID) error
	ListStudents(ctx context.Context, filter student.StudentFilter) ([]*student.Student, int64, error)
}

type studentUseCase struct {
	repo   student.Repository
	logger logger.Logger
}

func NewStudentUseCase(repo student.Repository, log logger.Logger) StudentUseCase {
	return &studentUseCase{
		repo:   repo,
		logger: log,
	}
}

func (uc *studentUseCase) CreateStudent(ctx context.Context, req student.CreateStudentRequest) (*student.Student, error) {
	// Only check email existence if email is provided and not empty
	if req.Email != "" {
		exists, err := uc.repo.ExistsByEmail(ctx, req.Email)
		if err != nil {
			uc.logger.Error(ctx, "failed to check email existence", err, map[string]interface{}{
				"email": req.Email,
			})
			return nil, fmt.Errorf("failed to validate email: %w", err)
		}

		if exists {
			return nil, fmt.Errorf("student with email %s already exists", req.Email)
		}
	}

	s := &student.Student{
		FirstName:   req.FirstName,
		LastName:    req.LastName,
		Email:       req.Email,
		Phone:       req.Phone,
		DateOfBirth: req.DateOfBirth,
		Address:     req.Address,
		InstituteID: req.InstituteID,
		Status:      "active",
		EnrolledAt:  time.Now().UTC(),
	}

	if err := uc.repo.Create(ctx, s); err != nil {
		uc.logger.Error(ctx, "failed to create student", err, map[string]interface{}{
			"email": req.Email,
		})
		return nil, fmt.Errorf("failed to create student: %w", err)
	}

	uc.logger.Info(ctx, "student created successfully", map[string]interface{}{
		"student_id": s.ID,
		"email":      s.Email,
	})

	return s, nil
}

func (uc *studentUseCase) GetStudent(ctx context.Context, id uuid.UUID) (*student.Student, error) {
	s, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		uc.logger.Error(ctx, "failed to get student", err, map[string]interface{}{
			"student_id": id,
		})
		return nil, fmt.Errorf("failed to get student: %w", err)
	}
	return s, nil
}

func (uc *studentUseCase) UpdateStudent(ctx context.Context, id uuid.UUID, req student.UpdateStudentRequest) (*student.Student, error) {
	s, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("student not found: %w", err)
	}

	if req.Email != nil && *req.Email != s.Email {
		exists, err := uc.repo.ExistsByEmail(ctx, *req.Email)
		if err != nil {
			return nil, fmt.Errorf("failed to validate email: %w", err)
		}
		if exists {
			return nil, fmt.Errorf("student with email %s already exists", *req.Email)
		}
		s.Email = *req.Email
	}

	if req.FirstName != nil {
		s.FirstName = *req.FirstName
	}
	if req.LastName != nil {
		s.LastName = *req.LastName
	}
	if req.Phone != nil {
		s.Phone = *req.Phone
	}
	if req.DateOfBirth != nil {
		s.DateOfBirth = *req.DateOfBirth
	}
	if req.Address != nil {
		s.Address = *req.Address
	}
	if req.Status != nil {
		s.Status = *req.Status
	}

	if err := uc.repo.Update(ctx, s); err != nil {
		uc.logger.Error(ctx, "failed to update student", err, map[string]interface{}{
			"student_id": id,
		})
		return nil, fmt.Errorf("failed to update student: %w", err)
	}

	uc.logger.Info(ctx, "student updated successfully", map[string]interface{}{
		"student_id": s.ID,
	})

	return s, nil
}

func (uc *studentUseCase) DeleteStudent(ctx context.Context, id uuid.UUID) error {
	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete student", err, map[string]interface{}{
			"student_id": id,
		})
		return fmt.Errorf("failed to delete student: %w", err)
	}

	uc.logger.Info(ctx, "student deleted successfully", map[string]interface{}{
		"student_id": id,
	})

	return nil
}

func (uc *studentUseCase) ListStudents(ctx context.Context, filter student.StudentFilter) ([]*student.Student, int64, error) {
	students, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list students", err, nil)
		return nil, 0, fmt.Errorf("failed to list students: %w", err)
	}
	return students, total, nil
}
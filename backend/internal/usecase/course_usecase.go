package usecase

import (
	"context"
	"fmt"

	"github.com/chalak/backend/internal/domain/course"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type CourseUseCase interface {
	CreateCourse(ctx context.Context, req course.CreateCourseRequest) (*course.Course, error)
	GetCourse(ctx context.Context, id uuid.UUID) (*course.Course, error)
	GetCourseByCode(ctx context.Context, code string) (*course.Course, error)
	UpdateCourse(ctx context.Context, id uuid.UUID, req course.UpdateCourseRequest) (*course.Course, error)
	DeleteCourse(ctx context.Context, id uuid.UUID) error
	ListCourses(ctx context.Context, filter course.CourseFilter) ([]*course.Course, int, error)
}

type courseUseCase struct {
	repo   course.Repository
	logger logger.Logger
}

func NewCourseUseCase(repo course.Repository, log logger.Logger) CourseUseCase {
	return &courseUseCase{
		repo:   repo,
		logger: log,
	}
}

func (uc *courseUseCase) CreateCourse(ctx context.Context, req course.CreateCourseRequest) (*course.Course, error) {
	// Check if course with same code already exists
	existingCourse, err := uc.repo.GetByCode(ctx, req.Code)
	if err == nil && existingCourse != nil {
		return nil, fmt.Errorf("course with code %s already exists", req.Code)
	}

	// Set default for is_active if not provided
	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	c := &course.Course{
		Name:        req.Name,
		Code:        req.Code,
		Description: req.Description,
		Duration:    req.Duration,
		Fee:         req.Fee,
		IsActive:    isActive,
	}

	if err := uc.repo.Create(ctx, c); err != nil {
		uc.logger.Error(ctx, "failed to create course", err, map[string]interface{}{
			"code": req.Code,
		})
		return nil, fmt.Errorf("failed to create course: %w", err)
	}

	uc.logger.Info(ctx, "course created successfully", map[string]interface{}{
		"course_id": c.ID,
		"code":      c.Code,
	})

	return c, nil
}

func (uc *courseUseCase) GetCourse(ctx context.Context, id uuid.UUID) (*course.Course, error) {
	c, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		uc.logger.Error(ctx, "failed to get course", err, map[string]interface{}{
			"course_id": id,
		})
		return nil, fmt.Errorf("failed to get course: %w", err)
	}
	return c, nil
}

func (uc *courseUseCase) GetCourseByCode(ctx context.Context, code string) (*course.Course, error) {
	c, err := uc.repo.GetByCode(ctx, code)
	if err != nil {
		uc.logger.Error(ctx, "failed to get course by code", err, map[string]interface{}{
			"code": code,
		})
		return nil, fmt.Errorf("failed to get course: %w", err)
	}
	return c, nil
}

func (uc *courseUseCase) UpdateCourse(ctx context.Context, id uuid.UUID, req course.UpdateCourseRequest) (*course.Course, error) {
	c, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("course not found: %w", err)
	}

	// Check if code is being changed and if it already exists
	if req.Code != nil && *req.Code != c.Code {
		existingCourse, err := uc.repo.GetByCode(ctx, *req.Code)
		if err == nil && existingCourse != nil {
			return nil, fmt.Errorf("course with code %s already exists", *req.Code)
		}
		c.Code = *req.Code
	}

	if req.Name != nil {
		c.Name = *req.Name
	}
	if req.Description != nil {
		c.Description = req.Description
	}
	if req.Duration != nil {
		c.Duration = *req.Duration
	}
	if req.Fee != nil {
		c.Fee = *req.Fee
	}
	if req.IsActive != nil {
		c.IsActive = *req.IsActive
	}

	if err := uc.repo.Update(ctx, c); err != nil {
		uc.logger.Error(ctx, "failed to update course", err, map[string]interface{}{
			"course_id": id,
		})
		return nil, fmt.Errorf("failed to update course: %w", err)
	}

	uc.logger.Info(ctx, "course updated successfully", map[string]interface{}{
		"course_id": c.ID,
	})

	return c, nil
}

func (uc *courseUseCase) DeleteCourse(ctx context.Context, id uuid.UUID) error {
	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete course", err, map[string]interface{}{
			"course_id": id,
		})
		return fmt.Errorf("failed to delete course: %w", err)
	}

	uc.logger.Info(ctx, "course deleted successfully", map[string]interface{}{
		"course_id": id,
	})

	return nil
}

func (uc *courseUseCase) ListCourses(ctx context.Context, filter course.CourseFilter) ([]*course.Course, int, error) {
	courses, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list courses", err, nil)
		return nil, 0, fmt.Errorf("failed to list courses: %w", err)
	}
	return courses, total, nil
}

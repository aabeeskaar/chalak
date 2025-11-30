package usecase

import (
	"context"
	"fmt"

	pkg "github.com/chalak/backend/internal/domain/package"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type PackageUseCase interface {
	CreatePackage(ctx context.Context, req pkg.CreatePackageRequest) (*pkg.Package, error)
	GetPackage(ctx context.Context, id uuid.UUID) (*pkg.Package, error)
	GetPackageByCode(ctx context.Context, code string) (*pkg.Package, error)
	UpdatePackage(ctx context.Context, id uuid.UUID, req pkg.UpdatePackageRequest) (*pkg.Package, error)
	DeletePackage(ctx context.Context, id uuid.UUID) error
	ListPackages(ctx context.Context, filter pkg.PackageFilter) ([]*pkg.Package, int, error)
}

type packageUseCase struct {
	repo   pkg.Repository
	logger logger.Logger
}

func NewPackageUseCase(repo pkg.Repository, log logger.Logger) PackageUseCase {
	return &packageUseCase{
		repo:   repo,
		logger: log,
	}
}

func (uc *packageUseCase) CreatePackage(ctx context.Context, req pkg.CreatePackageRequest) (*pkg.Package, error) {
	// Check if package with same code exists
	existing, err := uc.repo.GetByCode(ctx, req.Code)
	if err == nil && existing != nil {
		return nil, fmt.Errorf("package with code %s already exists", req.Code)
	}

	p := &pkg.Package{
		Name:               req.Name,
		Code:               req.Code,
		Description:        req.Description,
		Duration:           req.Duration,
		Price:              req.Price,
		DiscountPercentage: req.DiscountPercentage,
		IsActive:           req.IsActive,
	}

	if err := uc.repo.Create(ctx, p); err != nil {
		uc.logger.Error(ctx, "failed to create package", err, map[string]interface{}{
			"package_code": req.Code,
		})
		return nil, fmt.Errorf("failed to create package: %w", err)
	}

	// Add courses if provided
	if len(req.CourseIDs) > 0 {
		for _, courseIDStr := range req.CourseIDs {
			courseID, err := uuid.Parse(courseIDStr)
			if err != nil {
				uc.logger.Error(ctx, "invalid course ID", err, map[string]interface{}{
					"course_id": courseIDStr,
				})
				continue
			}

			if err := uc.repo.AddCourse(ctx, p.ID, courseID); err != nil {
				uc.logger.Error(ctx, "failed to add course to package", err, map[string]interface{}{
					"package_id": p.ID,
					"course_id":  courseID,
				})
			}
		}

		// Reload package with courses
		p, _ = uc.repo.GetByID(ctx, p.ID)
	}

	uc.logger.Info(ctx, "package created successfully", map[string]interface{}{
		"package_id":   p.ID,
		"package_code": p.Code,
	})

	return p, nil
}

func (uc *packageUseCase) GetPackage(ctx context.Context, id uuid.UUID) (*pkg.Package, error) {
	p, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		uc.logger.Error(ctx, "failed to get package", err, map[string]interface{}{
			"package_id": id,
		})
		return nil, fmt.Errorf("package not found")
	}
	return p, nil
}

func (uc *packageUseCase) GetPackageByCode(ctx context.Context, code string) (*pkg.Package, error) {
	p, err := uc.repo.GetByCode(ctx, code)
	if err != nil {
		uc.logger.Error(ctx, "failed to get package by code", err, map[string]interface{}{
			"code": code,
		})
		return nil, fmt.Errorf("package not found")
	}
	return p, nil
}

func (uc *packageUseCase) UpdatePackage(ctx context.Context, id uuid.UUID, req pkg.UpdatePackageRequest) (*pkg.Package, error) {
	p, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("package not found")
	}

	if req.Name != nil {
		p.Name = *req.Name
	}
	if req.Description != nil {
		p.Description = req.Description
	}
	if req.Duration != nil {
		p.Duration = *req.Duration
	}
	if req.Price != nil {
		p.Price = *req.Price
	}
	if req.DiscountPercentage != nil {
		p.DiscountPercentage = *req.DiscountPercentage
	}
	if req.IsActive != nil {
		p.IsActive = *req.IsActive
	}

	if err := uc.repo.Update(ctx, p); err != nil {
		uc.logger.Error(ctx, "failed to update package", err, map[string]interface{}{
			"package_id": id,
		})
		return nil, fmt.Errorf("failed to update package: %w", err)
	}

	// Update courses if provided
	if req.CourseIDs != nil {
		// Get current courses
		currentCourseIDs, err := uc.repo.GetCourses(ctx, p.ID)
		if err != nil {
			uc.logger.Error(ctx, "failed to get current courses", err, map[string]interface{}{
				"package_id": p.ID,
			})
		}

		// Remove all current courses
		for _, courseID := range currentCourseIDs {
			if err := uc.repo.RemoveCourse(ctx, p.ID, courseID); err != nil {
				uc.logger.Error(ctx, "failed to remove course", err, map[string]interface{}{
					"package_id": p.ID,
					"course_id":  courseID,
				})
			}
		}

		// Add new courses
		for _, courseIDStr := range req.CourseIDs {
			courseID, err := uuid.Parse(courseIDStr)
			if err != nil {
				uc.logger.Error(ctx, "invalid course ID", err, map[string]interface{}{
					"course_id": courseIDStr,
				})
				continue
			}

			if err := uc.repo.AddCourse(ctx, p.ID, courseID); err != nil {
				uc.logger.Error(ctx, "failed to add course to package", err, map[string]interface{}{
					"package_id": p.ID,
					"course_id":  courseID,
				})
			}
		}

		// Reload package with courses
		p, _ = uc.repo.GetByID(ctx, p.ID)
	}

	uc.logger.Info(ctx, "package updated successfully", map[string]interface{}{
		"package_id": p.ID,
	})

	return p, nil
}

func (uc *packageUseCase) DeletePackage(ctx context.Context, id uuid.UUID) error {
	_, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		return fmt.Errorf("package not found")
	}

	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete package", err, map[string]interface{}{
			"package_id": id,
		})
		return fmt.Errorf("failed to delete package: %w", err)
	}

	uc.logger.Info(ctx, "package deleted successfully", map[string]interface{}{
		"package_id": id,
	})

	return nil
}

func (uc *packageUseCase) ListPackages(ctx context.Context, filter pkg.PackageFilter) ([]*pkg.Package, int, error) {
	packages, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list packages", err, nil)
		return nil, 0, fmt.Errorf("failed to list packages: %w", err)
	}
	return packages, total, nil
}

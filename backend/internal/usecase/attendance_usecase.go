package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/attendance"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type AttendanceUseCase struct {
	repo   attendance.Repository
	logger logger.Logger
}

func NewAttendanceUseCase(repo attendance.Repository, logger logger.Logger) *AttendanceUseCase {
	return &AttendanceUseCase{
		repo:   repo,
		logger: logger,
	}
}

func (uc *AttendanceUseCase) MarkAttendance(ctx context.Context, req *attendance.MarkAttendanceRequest, markedBy uuid.UUID) (*attendance.Attendance, error) {
	att := &attendance.Attendance{
		ID:        uuid.New(),
		StudentID: req.StudentID,
		ClassID:   req.ClassID,
		Date:      req.Date,
		Status:    req.Status,
		Notes:     req.Notes,
		MarkedBy:  markedBy,
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}

	if req.Status == attendance.StatusPresent || req.Status == attendance.StatusLate {
		now := time.Now().UTC()
		att.CheckInAt = &now
	}

	if err := uc.repo.Create(ctx, att); err != nil {
		uc.logger.Error(ctx, "failed to mark attendance", err, map[string]interface{}{
			"student_id": req.StudentID,
			"class_id":   req.ClassID,
		})
		return nil, fmt.Errorf("failed to mark attendance: %w", err)
	}

	uc.logger.Info(ctx, "attendance marked", map[string]interface{}{
		"attendance_id": att.ID,
		"student_id":    att.StudentID,
		"status":        att.Status,
	})

	return att, nil
}

func (uc *AttendanceUseCase) GetByID(ctx context.Context, id uuid.UUID) (*attendance.Attendance, error) {
	att, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("attendance not found")
	}
	return att, nil
}

func (uc *AttendanceUseCase) Update(ctx context.Context, id uuid.UUID, req *attendance.MarkAttendanceRequest) (*attendance.Attendance, error) {
	att, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("attendance not found")
	}

	att.Status = req.Status
	att.Notes = req.Notes
	att.UpdatedAt = time.Now().UTC()

	if req.Status == attendance.StatusPresent || req.Status == attendance.StatusLate {
		if att.CheckInAt == nil {
			now := time.Now().UTC()
			att.CheckInAt = &now
		}
	}

	if err := uc.repo.Update(ctx, att); err != nil {
		uc.logger.Error(ctx, "failed to update attendance", err, map[string]interface{}{
			"attendance_id": id,
		})
		return nil, fmt.Errorf("failed to update attendance: %w", err)
	}

	uc.logger.Info(ctx, "attendance updated", map[string]interface{}{
		"attendance_id": att.ID,
	})

	return att, nil
}

func (uc *AttendanceUseCase) Delete(ctx context.Context, id uuid.UUID) error {
	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete attendance", err, map[string]interface{}{
			"attendance_id": id,
		})
		return fmt.Errorf("failed to delete attendance: %w", err)
	}

	uc.logger.Info(ctx, "attendance deleted", map[string]interface{}{
		"attendance_id": id,
	})

	return nil
}

func (uc *AttendanceUseCase) List(ctx context.Context, filter attendance.AttendanceFilter) ([]*attendance.Attendance, int64, error) {
	attendances, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list attendances", err, nil)
		return nil, 0, fmt.Errorf("failed to list attendances: %w", err)
	}

	return attendances, total, nil
}

func (uc *AttendanceUseCase) GetStudentStats(ctx context.Context, studentID uuid.UUID, dateFrom, dateTo time.Time) (map[string]int, error) {
	stats, err := uc.repo.GetStudentAttendanceStats(ctx, studentID, dateFrom, dateTo)
	if err != nil {
		uc.logger.Error(ctx, "failed to get student attendance stats", err, map[string]interface{}{
			"student_id": studentID,
		})
		return nil, fmt.Errorf("failed to get attendance stats: %w", err)
	}

	return stats, nil
}
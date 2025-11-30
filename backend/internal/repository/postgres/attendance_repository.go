package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/attendance"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AttendanceRepository struct {
	db *gorm.DB
}

func NewAttendanceRepository(db *gorm.DB) attendance.Repository {
	return &AttendanceRepository{db: db}
}

func (r *AttendanceRepository) Create(ctx context.Context, att *attendance.Attendance) error {
	if err := r.db.WithContext(ctx).Create(att).Error; err != nil {
		return fmt.Errorf("failed to create attendance: %w", err)
	}
	return nil
}

func (r *AttendanceRepository) FindByID(ctx context.Context, id uuid.UUID) (*attendance.Attendance, error) {
	var att attendance.Attendance
	if err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&att).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("attendance not found")
		}
		return nil, fmt.Errorf("failed to find attendance: %w", err)
	}
	return &att, nil
}

func (r *AttendanceRepository) Update(ctx context.Context, att *attendance.Attendance) error {
	if err := r.db.WithContext(ctx).Save(att).Error; err != nil {
		return fmt.Errorf("failed to update attendance: %w", err)
	}
	return nil
}

func (r *AttendanceRepository) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.db.WithContext(ctx).Model(&attendance.Attendance{}).Where("id = ?", id).Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP")).Error; err != nil {
		return fmt.Errorf("failed to delete attendance: %w", err)
	}
	return nil
}

func (r *AttendanceRepository) List(ctx context.Context, filter attendance.AttendanceFilter) ([]*attendance.Attendance, int64, error) {
	var total int64

	query := r.db.WithContext(ctx).Model(&attendance.Attendance{}).Where("attendances.deleted_at IS NULL")

	if filter.StudentID != nil {
		query = query.Where("attendances.student_id = ?", *filter.StudentID)
	}

	if filter.ClassID != nil {
		query = query.Where("attendances.class_id = ?", *filter.ClassID)
	}

	if filter.Status != nil {
		query = query.Where("attendances.status = ?", *filter.Status)
	}

	if filter.DateFrom != nil {
		query = query.Where("attendances.date >= ?", *filter.DateFrom)
	}

	if filter.DateTo != nil {
		query = query.Where("attendances.date <= ?", *filter.DateTo)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count attendances: %w", err)
	}

	// Use raw SQL query to ensure student names are properly fetched
	var attendances []*attendance.Attendance

	sqlQuery := `
		SELECT
			a.id, a.student_id, a.class_id, a.date, a.status,
			a.check_in_at, a.check_out_at, a.notes, a.marked_by,
			a.created_at, a.updated_at, a.deleted_at,
			s.first_name as student_first_name,
			s.last_name as student_last_name
		FROM attendances a
		LEFT JOIN students s ON s.id = a.student_id AND s.deleted_at IS NULL
		WHERE a.deleted_at IS NULL
	`

	args := []interface{}{}

	if filter.StudentID != nil {
		sqlQuery += " AND a.student_id = ?"
		args = append(args, *filter.StudentID)
	}

	if filter.ClassID != nil {
		sqlQuery += " AND a.class_id = ?"
		args = append(args, *filter.ClassID)
	}

	if filter.Status != nil {
		sqlQuery += " AND a.status = ?"
		args = append(args, *filter.Status)
	}

	if filter.DateFrom != nil {
		sqlQuery += " AND a.date >= ?"
		args = append(args, *filter.DateFrom)
	}

	if filter.DateTo != nil {
		sqlQuery += " AND a.date <= ?"
		args = append(args, *filter.DateTo)
	}

	sqlQuery += " ORDER BY a.date DESC, a.created_at DESC"

	if filter.Limit > 0 {
		sqlQuery += " LIMIT ?"
		args = append(args, filter.Limit)
	}

	if filter.Offset > 0 {
		sqlQuery += " OFFSET ?"
		args = append(args, filter.Offset)
	}

	if err := r.db.WithContext(ctx).Raw(sqlQuery, args...).Scan(&attendances).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to list attendances: %w", err)
	}

	// Populate student names for all attendance records
	for _, att := range attendances {
		var student struct {
			FirstName string `db:"first_name"`
			LastName  string `db:"last_name"`
		}

		if err := r.db.WithContext(ctx).Raw(
			"SELECT first_name, last_name FROM students WHERE id = ? AND deleted_at IS NULL",
			att.StudentID,
		).Scan(&student).Error; err == nil {
			att.StudentFirstName = student.FirstName
			att.StudentLastName = student.LastName
		}
	}

	return attendances, total, nil
}

func (r *AttendanceRepository) GetStudentAttendanceStats(ctx context.Context, studentID uuid.UUID, dateFrom, dateTo time.Time) (map[string]int, error) {
	var results []struct {
		Status string
		Count  int
	}

	if err := r.db.WithContext(ctx).
		Model(&attendance.Attendance{}).
		Select("status, COUNT(*) as count").
		Where("student_id = ? AND date >= ? AND date <= ? AND deleted_at IS NULL", studentID, dateFrom, dateTo).
		Group("status").
		Find(&results).Error; err != nil {
		return nil, fmt.Errorf("failed to get attendance stats: %w", err)
	}

	stats := make(map[string]int)
	for _, result := range results {
		stats[result.Status] = result.Count
	}

	return stats, nil
}
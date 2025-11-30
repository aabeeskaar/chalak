package attendance

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, attendance *Attendance) error
	FindByID(ctx context.Context, id uuid.UUID) (*Attendance, error)
	Update(ctx context.Context, attendance *Attendance) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter AttendanceFilter) ([]*Attendance, int64, error)
	GetStudentAttendanceStats(ctx context.Context, studentID uuid.UUID, dateFrom, dateTo time.Time) (map[string]int, error)
}
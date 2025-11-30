package attendance

import (
	"time"

	"github.com/google/uuid"
)

type Attendance struct {
	ID                 uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	StudentID          uuid.UUID  `json:"student_id" gorm:"type:uuid;not null;index"`
	StudentFirstName   string     `json:"student_first_name" gorm:"-"`
	StudentLastName    string     `json:"student_last_name" gorm:"-"`
	ClassID            uuid.UUID  `json:"class_id" gorm:"type:uuid;not null;index"`
	Date               time.Time  `json:"date" gorm:"type:date;not null;index"`
	Status             string     `json:"status" gorm:"type:varchar(20);not null"`
	CheckInAt          *time.Time `json:"check_in_at,omitempty" gorm:"type:timestamp"`
	CheckOutAt         *time.Time `json:"check_out_at,omitempty" gorm:"type:timestamp"`
	Notes              string     `json:"notes" gorm:"type:text"`
	MarkedBy           uuid.UUID  `json:"marked_by" gorm:"type:uuid;not null"`
	CreatedAt          time.Time  `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt          time.Time  `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt          *time.Time `json:"deleted_at,omitempty" gorm:"type:timestamp;index"`
}

func (Attendance) TableName() string {
	return "attendances"
}

const (
	StatusPresent = "present"
	StatusAbsent  = "absent"
	StatusLate    = "late"
	StatusExcused = "excused"
)

type MarkAttendanceRequest struct {
	StudentID uuid.UUID `json:"student_id" validate:"required"`
	ClassID   uuid.UUID `json:"class_id" validate:"required"`
	Date      time.Time `json:"date" validate:"required"`
	Status    string    `json:"status" validate:"required,oneof=present absent late excused"`
	Notes     string    `json:"notes"`
}

type AttendanceFilter struct {
	StudentID *uuid.UUID
	ClassID   *uuid.UUID
	DateFrom  *time.Time
	DateTo    *time.Time
	Status    *string
	Limit     int
	Offset    int
}
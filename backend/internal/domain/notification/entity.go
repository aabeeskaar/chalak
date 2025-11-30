package notification

import (
	"time"

	"github.com/google/uuid"
)

type Notification struct {
	ID         uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID     uuid.UUID  `json:"user_id" gorm:"type:uuid;not null;index"`
	Type       string     `json:"type" gorm:"type:varchar(50);not null"`
	Title      string     `json:"title" gorm:"type:varchar(255);not null"`
	Message    string     `json:"message" gorm:"type:text;not null"`
	Data       string     `json:"data" gorm:"type:jsonb"`
	IsRead     bool       `json:"is_read" gorm:"type:boolean;default:false"`
	ReadAt     *time.Time `json:"read_at,omitempty" gorm:"type:timestamp"`
	SentVia    string     `json:"sent_via" gorm:"type:varchar(50)"`
	ScheduledAt *time.Time `json:"scheduled_at,omitempty" gorm:"type:timestamp"`
	CreatedAt  time.Time  `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt  time.Time  `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt  *time.Time `json:"deleted_at,omitempty" gorm:"type:timestamp;index"`
}

func (Notification) TableName() string {
	return "notifications"
}

const (
	TypeAttendance = "attendance"
	TypeInvoice    = "invoice"
	TypePayment    = "payment"
	TypeAnnouncement = "announcement"
	TypeReminder   = "reminder"

	SentViaPush  = "push"
	SentViaEmail = "email"
	SentViaSMS   = "sms"
	SentViaInApp = "in_app"
)

type CreateNotificationRequest struct {
	UserID  uuid.UUID `json:"user_id" validate:"required"`
	Type    string    `json:"type" validate:"required"`
	Title   string    `json:"title" validate:"required"`
	Message string    `json:"message" validate:"required"`
	Data    string    `json:"data"`
	SentVia string    `json:"sent_via" validate:"omitempty,oneof=push email sms in_app"`
}

type NotificationFilter struct {
	UserID *uuid.UUID
	Type   *string
	IsRead *bool
	Limit  int
	Offset int
}
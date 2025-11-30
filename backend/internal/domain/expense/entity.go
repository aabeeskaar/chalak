package expense

import (
	"time"

	"github.com/google/uuid"
)

type Expense struct {
	ID          uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	InstituteID uuid.UUID  `json:"institute_id" gorm:"type:uuid;not null;index"`
	Category    string     `json:"category" gorm:"type:varchar(100);not null"`
	Amount      float64    `json:"amount" gorm:"type:decimal(10,2);not null"`
	Description string     `json:"description" gorm:"type:text;not null"`
	Date        time.Time  `json:"date" gorm:"type:date;not null;index"`
	Receipt     string     `json:"receipt" gorm:"type:varchar(255)"`
	Status      string     `json:"status" gorm:"type:varchar(20);not null;default:'pending'"`
	ApprovedBy  *uuid.UUID `json:"approved_by,omitempty" gorm:"type:uuid"`
	ApprovedAt  *time.Time `json:"approved_at,omitempty" gorm:"type:timestamp"`
	CreatedBy   uuid.UUID  `json:"created_by" gorm:"type:uuid;not null"`
	CreatedAt   time.Time  `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt   time.Time  `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty" gorm:"type:timestamp;index"`
}

func (Expense) TableName() string {
	return "expenses"
}

const (
	StatusPending  = "pending"
	StatusApproved = "approved"
	StatusRejected = "rejected"

	CategorySalary      = "salary"
	CategoryRent        = "rent"
	CategoryUtilities   = "utilities"
	CategoryMaintenance = "maintenance"
	CategorySupplies    = "supplies"
	CategoryMarketing   = "marketing"
	CategoryOther       = "other"
)

type CreateExpenseRequest struct {
	InstituteID uuid.UUID `json:"institute_id" validate:"required"`
	Category    string    `json:"category" validate:"required"`
	Amount      float64   `json:"amount" validate:"required,gt=0"`
	Description string    `json:"description" validate:"required"`
	Date        time.Time `json:"date" validate:"required"`
	Receipt     string    `json:"receipt"`
}

type UpdateExpenseRequest struct {
	Category    *string    `json:"category,omitempty"`
	Amount      *float64   `json:"amount,omitempty" validate:"omitempty,gt=0"`
	Description *string    `json:"description,omitempty"`
	Date        *time.Time `json:"date,omitempty"`
	Receipt     *string    `json:"receipt,omitempty"`
}

type ExpenseFilter struct {
	InstituteID *uuid.UUID
	Category    *string
	Status      *string
	DateFrom    *time.Time
	DateTo      *time.Time
	Limit       int
	Offset      int
}
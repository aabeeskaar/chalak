package employee

import (
	"time"

	"github.com/google/uuid"
)

type Employee struct {
	ID           uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	FirstName    string     `json:"first_name" gorm:"type:varchar(100);not null"`
	LastName     string     `json:"last_name" gorm:"type:varchar(100);not null"`
	Email        string     `json:"email" gorm:"type:varchar(255);uniqueIndex;not null"`
	Phone        string     `json:"phone" gorm:"type:varchar(20);not null"`
	Position     string     `json:"position" gorm:"type:varchar(100);not null"`
	Department   string     `json:"department" gorm:"type:varchar(100)"`
	InstituteID  uuid.UUID  `json:"institute_id" gorm:"type:uuid;not null;index"`
	Salary       float64    `json:"salary" gorm:"type:decimal(10,2)"`
	HireDate     time.Time  `json:"hire_date" gorm:"type:date;not null"`
	TerminatedAt *time.Time `json:"terminated_at,omitempty" gorm:"type:date"`
	Status       string     `json:"status" gorm:"type:varchar(20);not null;default:'active'"`
	Address      string     `json:"address" gorm:"type:text"`
	CreatedAt    time.Time  `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt    time.Time  `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt    *time.Time `json:"deleted_at,omitempty" gorm:"type:timestamp;index"`
}

func (Employee) TableName() string {
	return "employees"
}

const (
	StatusActive     = "active"
	StatusInactive   = "inactive"
	StatusTerminated = "terminated"
	StatusOnLeave    = "on_leave"
)

type CreateEmployeeRequest struct {
	FirstName   string    `json:"first_name" validate:"required,min=2,max=100"`
	LastName    string    `json:"last_name" validate:"required,min=2,max=100"`
	Email       string    `json:"email" validate:"required,email"`
	Phone       string    `json:"phone" validate:"required"`
	Position    string    `json:"position" validate:"required"`
	Department  string    `json:"department"`
	InstituteID uuid.UUID `json:"institute_id" validate:"required"`
	Salary      float64   `json:"salary" validate:"gte=0"`
	HireDate    time.Time `json:"hire_date" validate:"required"`
	Address     string    `json:"address"`
}

type UpdateEmployeeRequest struct {
	FirstName  *string    `json:"first_name,omitempty" validate:"omitempty,min=2,max=100"`
	LastName   *string    `json:"last_name,omitempty" validate:"omitempty,min=2,max=100"`
	Phone      *string    `json:"phone,omitempty"`
	Position   *string    `json:"position,omitempty"`
	Department *string    `json:"department,omitempty"`
	Salary     *float64   `json:"salary,omitempty" validate:"omitempty,gte=0"`
	Status     *string    `json:"status,omitempty" validate:"omitempty,oneof=active inactive terminated on_leave"`
	Address    *string    `json:"address,omitempty"`
}

type EmployeeFilter struct {
	InstituteID *uuid.UUID
	Department  *string
	Position    *string
	Status      *string
	Search      *string
	Limit       int
	Offset      int
}
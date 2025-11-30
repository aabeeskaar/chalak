package student

import (
	"time"

	"github.com/google/uuid"
)

type Student struct {
	ID          uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	FirstName   string     `json:"first_name" gorm:"type:varchar(100);not null"`
	LastName    string     `json:"last_name" gorm:"type:varchar(100);not null"`
	Email       string     `json:"email" gorm:"type:varchar(255)"`
	Phone       string     `json:"phone" gorm:"type:varchar(20);not null"`
	DateOfBirth time.Time  `json:"date_of_birth" gorm:"type:date;not null"`
	Address     string     `json:"address" gorm:"type:text"`
	InstituteID uuid.UUID  `json:"institute_id" gorm:"type:uuid;not null;index"`
	Status      string     `json:"status" gorm:"type:varchar(20);default:'active';not null"`
	EnrolledAt  time.Time  `json:"enrolled_at" gorm:"type:timestamp;not null"`
	CreatedAt   time.Time  `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt   time.Time  `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty" gorm:"type:timestamp;index"`
}

func (Student) TableName() string {
	return "students"
}

type CreateStudentRequest struct {
	FirstName   string    `json:"first_name" validate:"required,min=2,max=100"`
	LastName    string    `json:"last_name" validate:"required,min=2,max=100"`
	Email       string    `json:"email" validate:"omitempty,email"`
	Phone       string    `json:"phone" validate:"required"`
	DateOfBirth time.Time `json:"date_of_birth" validate:"required"`
	Address     string    `json:"address"`
	InstituteID uuid.UUID `json:"institute_id" validate:"required"`
}

type UpdateStudentRequest struct {
	FirstName   *string    `json:"first_name,omitempty" validate:"omitempty,min=2,max=100"`
	LastName    *string    `json:"last_name,omitempty" validate:"omitempty,min=2,max=100"`
	Email       *string    `json:"email,omitempty" validate:"omitempty,email"`
	Phone       *string    `json:"phone,omitempty"`
	DateOfBirth *time.Time `json:"date_of_birth,omitempty"`
	Address     *string    `json:"address,omitempty"`
	Status      *string    `json:"status,omitempty" validate:"omitempty,oneof=active inactive suspended"`
}

type StudentFilter struct {
	InstituteID *uuid.UUID
	Status      *string
	Search      *string
	Limit       int
	Offset      int
}
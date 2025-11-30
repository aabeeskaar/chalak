package course

import (
	"time"

	"github.com/google/uuid"
)

type Course struct {
	ID          uuid.UUID  `json:"id"`
	Name        string     `json:"name"`
	Code        string     `json:"code"`
	Description *string    `json:"description,omitempty"`
	Duration    int        `json:"duration"` // Duration in hours
	Fee         float64    `json:"fee"`
	IsActive    bool       `json:"is_active"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty"`
}

type CreateCourseRequest struct {
	Name        string  `json:"name" validate:"required,min=3,max=100"`
	Code        string  `json:"code" validate:"required,min=2,max=20"`
	Description *string `json:"description,omitempty" validate:"omitempty,max=500"`
	Duration    int     `json:"duration" validate:"required,min=1,max=1000"`
	Fee         float64 `json:"fee" validate:"required,min=0"`
	IsActive    *bool   `json:"is_active,omitempty"`
}

type UpdateCourseRequest struct {
	Name        *string  `json:"name,omitempty" validate:"omitempty,min=3,max=100"`
	Code        *string  `json:"code,omitempty" validate:"omitempty,min=2,max=20"`
	Description *string  `json:"description,omitempty" validate:"omitempty,max=500"`
	Duration    *int     `json:"duration,omitempty" validate:"omitempty,min=1,max=1000"`
	Fee         *float64 `json:"fee,omitempty" validate:"omitempty,min=0"`
	IsActive    *bool    `json:"is_active,omitempty"`
}

type CourseFilter struct {
	Search   string
	IsActive *bool
	Limit    int
	Offset   int
}

package pkg

import (
	"time"

	"github.com/google/uuid"
)

type Package struct {
	ID                 uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Name               string     `json:"name" gorm:"type:varchar(255);not null"`
	Code               string     `json:"code" gorm:"type:varchar(100);unique;not null"`
	Description        *string    `json:"description" gorm:"type:text"`
	Duration           int        `json:"duration" gorm:"not null"` // Duration in days
	Price              float64    `json:"price" gorm:"type:decimal(10,2);not null"`
	DiscountPercentage float64    `json:"discount_percentage" gorm:"type:decimal(5,2);default:0"`
	IsActive           bool       `json:"is_active" gorm:"default:true"`
	Courses            []Course   `json:"courses,omitempty" gorm:"many2many:package_courses;"`
	CreatedAt          time.Time  `json:"created_at" gorm:"default:CURRENT_TIMESTAMP"`
	UpdatedAt          time.Time  `json:"updated_at" gorm:"default:CURRENT_TIMESTAMP"`
	DeletedAt          *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}

type Course struct {
	ID uuid.UUID `json:"id"`
}

type PackageCourse struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	PackageID uuid.UUID `json:"package_id" gorm:"type:uuid;not null"`
	CourseID  uuid.UUID `json:"course_id" gorm:"type:uuid;not null"`
	CreatedAt time.Time `json:"created_at" gorm:"default:CURRENT_TIMESTAMP"`
}

type CreatePackageRequest struct {
	Name               string    `json:"name" validate:"required,min=3,max=255"`
	Code               string    `json:"code" validate:"required,min=2,max=100"`
	Description        *string   `json:"description"`
	Duration           int       `json:"duration" validate:"required,min=1"`
	Price              float64   `json:"price" validate:"required,min=0"`
	DiscountPercentage float64   `json:"discount_percentage" validate:"min=0,max=100"`
	IsActive           bool      `json:"is_active"`
	CourseIDs          []string  `json:"course_ids"`
}

type UpdatePackageRequest struct {
	Name               *string   `json:"name" validate:"omitempty,min=3,max=255"`
	Description        *string   `json:"description"`
	Duration           *int      `json:"duration" validate:"omitempty,min=1"`
	Price              *float64  `json:"price" validate:"omitempty,min=0"`
	DiscountPercentage *float64  `json:"discount_percentage" validate:"omitempty,min=0,max=100"`
	IsActive           *bool     `json:"is_active"`
	CourseIDs          []string  `json:"course_ids"`
}

type PackageFilter struct {
	Search   string
	IsActive *bool
	MinPrice *float64
	MaxPrice *float64
	Limit    int
	Offset   int
}

func (Package) TableName() string {
	return "packages"
}

func (PackageCourse) TableName() string {
	return "package_courses"
}

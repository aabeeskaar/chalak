package invoice

import (
	"time"

	"github.com/google/uuid"
)

type Invoice struct {
	ID            uuid.UUID     `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	InvoiceNumber string        `json:"invoice_number" gorm:"type:varchar(50);uniqueIndex;not null"`
	StudentID     uuid.UUID     `json:"student_id" gorm:"type:uuid;not null;index"`
	InstituteID   uuid.UUID     `json:"institute_id" gorm:"type:uuid;not null;index"`
	Amount        float64       `json:"amount" gorm:"type:decimal(10,2);not null"`
	TaxAmount     float64       `json:"tax_amount" gorm:"type:decimal(10,2);default:0"`
	TotalAmount   float64       `json:"total_amount" gorm:"type:decimal(10,2);not null"`
	PaidAmount    float64       `json:"paid_amount" gorm:"type:decimal(10,2);not null;default:0"`
	Status        string        `json:"status" gorm:"type:varchar(20);not null;default:'pending'"`
	DueDate       time.Time     `json:"due_date" gorm:"type:date;not null"`
	PaidAt        *time.Time    `json:"paid_at,omitempty" gorm:"type:timestamp"`
	Notes         string        `json:"notes" gorm:"type:text"`
	Items         []InvoiceItem `json:"items" gorm:"foreignKey:InvoiceID"`
	CreatedBy     uuid.UUID     `json:"created_by" gorm:"type:uuid;not null"`
	CreatedAt     time.Time     `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt     time.Time     `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt     *time.Time    `json:"deleted_at,omitempty" gorm:"type:timestamp;index"`
}

func (Invoice) TableName() string {
	return "invoices"
}

type InvoiceItem struct {
	ID          uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	InvoiceID   uuid.UUID  `json:"invoice_id" gorm:"type:uuid;not null;index"`
	Description string     `json:"description" gorm:"type:varchar(255);not null"`
	Quantity    int        `json:"quantity" gorm:"type:int;not null;default:1"`
	UnitPrice   float64    `json:"unit_price" gorm:"type:decimal(10,2);not null"`
	Amount      float64    `json:"amount" gorm:"type:decimal(10,2);not null"`
	CreatedAt   time.Time  `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt   time.Time  `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty" gorm:"type:timestamp"`
}

func (InvoiceItem) TableName() string {
	return "invoice_items"
}

const (
	StatusPending  = "pending"
	StatusPaid     = "paid"
	StatusOverdue  = "overdue"
	StatusCanceled = "canceled"
)

type CreateInvoiceRequest struct {
	StudentID   uuid.UUID            `json:"student_id" validate:"required"`
	InstituteID uuid.UUID            `json:"institute_id" validate:"required"`
	DueDate     time.Time            `json:"due_date" validate:"required"`
	Notes       string               `json:"notes"`
	Items       []CreateInvoiceItem  `json:"items" validate:"required,min=1,dive"`
}

type CreateInvoiceItem struct {
	Description string  `json:"description" validate:"required"`
	Quantity    int     `json:"quantity" validate:"required,gte=1"`
	UnitPrice   float64 `json:"unit_price" validate:"required,gte=0"`
}

type InvoiceFilter struct {
	StudentID   *uuid.UUID
	InstituteID *uuid.UUID
	Status      *string
	DateFrom    *time.Time
	DateTo      *time.Time
	Limit       int
	Offset      int
}
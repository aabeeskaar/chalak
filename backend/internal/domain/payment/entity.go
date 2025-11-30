package payment

import (
	"time"

	"github.com/google/uuid"
)

type Payment struct {
	ID            uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	InvoiceID     uuid.UUID  `json:"invoice_id" gorm:"type:uuid;not null;index"`
	Amount        float64    `json:"amount" gorm:"type:decimal(10,2);not null"`
	PaymentMethod string     `json:"payment_method" gorm:"type:varchar(50);not null;default:'cash'"`
	PaymentDate   time.Time  `json:"payment_date" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	Notes         string     `json:"notes" gorm:"type:text"`
	CreatedBy     uuid.UUID  `json:"created_by" gorm:"type:uuid;not null"`
	CreatedAt     time.Time  `json:"created_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt     time.Time  `json:"updated_at" gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	DeletedAt     *time.Time `json:"deleted_at,omitempty" gorm:"type:timestamp;index"`
}

func (Payment) TableName() string {
	return "payments"
}

const (
	MethodCash        = "cash"
	MethodCard        = "card"
	MethodBankTransfer = "bank_transfer"
	MethodOnline      = "online"
)

type CreatePaymentRequest struct {
	InvoiceID     uuid.UUID `json:"invoice_id" validate:"required"`
	Amount        float64   `json:"amount" validate:"required,gt=0"`
	PaymentMethod string    `json:"payment_method" validate:"required,oneof=cash card bank_transfer online"`
	PaymentDate   time.Time `json:"payment_date"`
	Notes         string    `json:"notes"`
}

type Repository interface {
	Create(payment *Payment) error
	GetByID(id uuid.UUID) (*Payment, error)
	GetByInvoiceID(invoiceID uuid.UUID) ([]*Payment, error)
	GetAll(limit, offset int) ([]*Payment, error)
	Delete(id uuid.UUID) error
}

package invoice

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, invoice *Invoice) error
	FindByID(ctx context.Context, id uuid.UUID) (*Invoice, error)
	FindByInvoiceNumber(ctx context.Context, invoiceNumber string) (*Invoice, error)
	Update(ctx context.Context, invoice *Invoice) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter InvoiceFilter) ([]*Invoice, int64, error)
	MarkAsPaid(ctx context.Context, id uuid.UUID) error
	GetTotalRevenue(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (float64, error)
}
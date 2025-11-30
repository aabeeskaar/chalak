package expense

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, expense *Expense) error
	FindByID(ctx context.Context, id uuid.UUID) (*Expense, error)
	Update(ctx context.Context, expense *Expense) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter ExpenseFilter) ([]*Expense, int64, error)
	Approve(ctx context.Context, id uuid.UUID, approvedBy uuid.UUID) error
	Reject(ctx context.Context, id uuid.UUID, rejectedBy uuid.UUID) error
	GetTotalExpenses(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (float64, error)
	GetExpensesByCategory(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (map[string]float64, error)
}
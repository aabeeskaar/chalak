package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/expense"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ExpenseRepository struct {
	db *gorm.DB
}

func NewExpenseRepository(db *gorm.DB) expense.Repository {
	return &ExpenseRepository{db: db}
}

func (r *ExpenseRepository) Create(ctx context.Context, exp *expense.Expense) error {
	if err := r.db.WithContext(ctx).Create(exp).Error; err != nil {
		return fmt.Errorf("failed to create expense: %w", err)
	}
	return nil
}

func (r *ExpenseRepository) FindByID(ctx context.Context, id uuid.UUID) (*expense.Expense, error) {
	var exp expense.Expense
	if err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&exp).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("expense not found")
		}
		return nil, fmt.Errorf("failed to find expense: %w", err)
	}
	return &exp, nil
}

func (r *ExpenseRepository) Update(ctx context.Context, exp *expense.Expense) error {
	if err := r.db.WithContext(ctx).Save(exp).Error; err != nil {
		return fmt.Errorf("failed to update expense: %w", err)
	}
	return nil
}

func (r *ExpenseRepository) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.db.WithContext(ctx).Model(&expense.Expense{}).Where("id = ?", id).Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP")).Error; err != nil {
		return fmt.Errorf("failed to delete expense: %w", err)
	}
	return nil
}

func (r *ExpenseRepository) List(ctx context.Context, filter expense.ExpenseFilter) ([]*expense.Expense, int64, error) {
	var expenses []*expense.Expense
	var total int64

	query := r.db.WithContext(ctx).Model(&expense.Expense{}).Where("deleted_at IS NULL")

	if filter.InstituteID != nil {
		query = query.Where("institute_id = ?", *filter.InstituteID)
	}

	if filter.Category != nil {
		query = query.Where("category = ?", *filter.Category)
	}

	if filter.Status != nil {
		query = query.Where("status = ?", *filter.Status)
	}

	if filter.DateFrom != nil {
		query = query.Where("date >= ?", *filter.DateFrom)
	}

	if filter.DateTo != nil {
		query = query.Where("date <= ?", *filter.DateTo)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count expenses: %w", err)
	}

	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}
	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	if err := query.Order("date DESC, created_at DESC").Find(&expenses).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to list expenses: %w", err)
	}

	return expenses, total, nil
}

func (r *ExpenseRepository) Approve(ctx context.Context, id uuid.UUID, approvedBy uuid.UUID) error {
	now := time.Now().UTC()
	if err := r.db.WithContext(ctx).Model(&expense.Expense{}).Where("id = ?", id).Updates(map[string]interface{}{
		"status":      expense.StatusApproved,
		"approved_by": approvedBy,
		"approved_at": now,
	}).Error; err != nil {
		return fmt.Errorf("failed to approve expense: %w", err)
	}
	return nil
}

func (r *ExpenseRepository) Reject(ctx context.Context, id uuid.UUID, rejectedBy uuid.UUID) error {
	now := time.Now().UTC()
	if err := r.db.WithContext(ctx).Model(&expense.Expense{}).Where("id = ?", id).Updates(map[string]interface{}{
		"status":      expense.StatusRejected,
		"approved_by": rejectedBy,
		"approved_at": now,
	}).Error; err != nil {
		return fmt.Errorf("failed to reject expense: %w", err)
	}
	return nil
}

func (r *ExpenseRepository) GetTotalExpenses(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (float64, error) {
	var total float64
	if err := r.db.WithContext(ctx).Model(&expense.Expense{}).
		Where("institute_id = ? AND status = ? AND date >= ? AND date <= ? AND deleted_at IS NULL", instituteID, expense.StatusApproved, dateFrom, dateTo).
		Select("COALESCE(SUM(amount), 0)").
		Scan(&total).Error; err != nil {
		return 0, fmt.Errorf("failed to get total expenses: %w", err)
	}
	return total, nil
}

func (r *ExpenseRepository) GetExpensesByCategory(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (map[string]float64, error) {
	var results []struct {
		Category string
		Total    float64
	}

	if err := r.db.WithContext(ctx).
		Model(&expense.Expense{}).
		Select("category, COALESCE(SUM(amount), 0) as total").
		Where("institute_id = ? AND status = ? AND date >= ? AND date <= ? AND deleted_at IS NULL", instituteID, expense.StatusApproved, dateFrom, dateTo).
		Group("category").
		Find(&results).Error; err != nil {
		return nil, fmt.Errorf("failed to get expenses by category: %w", err)
	}

	expenses := make(map[string]float64)
	for _, result := range results {
		expenses[result.Category] = result.Total
	}

	return expenses, nil
}
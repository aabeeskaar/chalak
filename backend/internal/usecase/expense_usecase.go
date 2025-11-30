package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/expense"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type ExpenseUseCase struct {
	repo   expense.Repository
	logger logger.Logger
}

func NewExpenseUseCase(repo expense.Repository, logger logger.Logger) *ExpenseUseCase {
	return &ExpenseUseCase{
		repo:   repo,
		logger: logger,
	}
}

func (uc *ExpenseUseCase) Create(ctx context.Context, req *expense.CreateExpenseRequest, createdBy uuid.UUID) (*expense.Expense, error) {
	exp := &expense.Expense{
		ID:          uuid.New(),
		InstituteID: req.InstituteID,
		Category:    req.Category,
		Amount:      req.Amount,
		Description: req.Description,
		Date:        req.Date,
		Receipt:     req.Receipt,
		Status:      expense.StatusPending,
		CreatedBy:   createdBy,
		CreatedAt:   time.Now().UTC(),
		UpdatedAt:   time.Now().UTC(),
	}

	if err := uc.repo.Create(ctx, exp); err != nil {
		uc.logger.Error(ctx, "failed to create expense", err, map[string]interface{}{
			"institute_id": req.InstituteID,
			"amount":       req.Amount,
		})
		return nil, fmt.Errorf("failed to create expense: %w", err)
	}

	uc.logger.Info(ctx, "expense created", map[string]interface{}{
		"expense_id": exp.ID,
		"amount":     exp.Amount,
		"category":   exp.Category,
	})

	return exp, nil
}

func (uc *ExpenseUseCase) GetByID(ctx context.Context, id uuid.UUID) (*expense.Expense, error) {
	exp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("expense not found")
	}
	return exp, nil
}

func (uc *ExpenseUseCase) Update(ctx context.Context, id uuid.UUID, req *expense.UpdateExpenseRequest) (*expense.Expense, error) {
	exp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("expense not found")
	}

	if exp.Status != expense.StatusPending {
		return nil, apperrors.BadRequest("only pending expenses can be updated")
	}

	if req.Category != nil {
		exp.Category = *req.Category
	}
	if req.Amount != nil {
		exp.Amount = *req.Amount
	}
	if req.Description != nil {
		exp.Description = *req.Description
	}
	if req.Date != nil {
		exp.Date = *req.Date
	}
	if req.Receipt != nil {
		exp.Receipt = *req.Receipt
	}

	exp.UpdatedAt = time.Now().UTC()

	if err := uc.repo.Update(ctx, exp); err != nil {
		uc.logger.Error(ctx, "failed to update expense", err, map[string]interface{}{
			"expense_id": id,
		})
		return nil, fmt.Errorf("failed to update expense: %w", err)
	}

	uc.logger.Info(ctx, "expense updated", map[string]interface{}{
		"expense_id": exp.ID,
	})

	return exp, nil
}

func (uc *ExpenseUseCase) Delete(ctx context.Context, id uuid.UUID) error {
	exp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return apperrors.NotFound("expense not found")
	}

	if exp.Status == expense.StatusApproved {
		return apperrors.BadRequest("approved expenses cannot be deleted")
	}

	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete expense", err, map[string]interface{}{
			"expense_id": id,
		})
		return fmt.Errorf("failed to delete expense: %w", err)
	}

	uc.logger.Info(ctx, "expense deleted", map[string]interface{}{
		"expense_id": id,
	})

	return nil
}

func (uc *ExpenseUseCase) List(ctx context.Context, filter expense.ExpenseFilter) ([]*expense.Expense, int64, error) {
	expenses, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list expenses", err, nil)
		return nil, 0, fmt.Errorf("failed to list expenses: %w", err)
	}

	return expenses, total, nil
}

func (uc *ExpenseUseCase) Approve(ctx context.Context, id uuid.UUID, approvedBy uuid.UUID) error {
	exp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return apperrors.NotFound("expense not found")
	}

	if exp.Status != expense.StatusPending {
		return apperrors.BadRequest("only pending expenses can be approved")
	}

	if err := uc.repo.Approve(ctx, id, approvedBy); err != nil {
		uc.logger.Error(ctx, "failed to approve expense", err, map[string]interface{}{
			"expense_id": id,
		})
		return fmt.Errorf("failed to approve expense: %w", err)
	}

	uc.logger.Info(ctx, "expense approved", map[string]interface{}{
		"expense_id": id,
	})

	return nil
}

func (uc *ExpenseUseCase) Reject(ctx context.Context, id uuid.UUID, rejectedBy uuid.UUID) error {
	exp, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return apperrors.NotFound("expense not found")
	}

	if exp.Status != expense.StatusPending {
		return apperrors.BadRequest("only pending expenses can be rejected")
	}

	if err := uc.repo.Reject(ctx, id, rejectedBy); err != nil {
		uc.logger.Error(ctx, "failed to reject expense", err, map[string]interface{}{
			"expense_id": id,
		})
		return fmt.Errorf("failed to reject expense: %w", err)
	}

	uc.logger.Info(ctx, "expense rejected", map[string]interface{}{
		"expense_id": id,
	})

	return nil
}

func (uc *ExpenseUseCase) GetTotalExpenses(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (float64, error) {
	total, err := uc.repo.GetTotalExpenses(ctx, instituteID, dateFrom, dateTo)
	if err != nil {
		uc.logger.Error(ctx, "failed to get total expenses", err, map[string]interface{}{
			"institute_id": instituteID,
		})
		return 0, fmt.Errorf("failed to get total expenses: %w", err)
	}

	return total, nil
}

func (uc *ExpenseUseCase) GetExpensesByCategory(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (map[string]float64, error) {
	expenses, err := uc.repo.GetExpensesByCategory(ctx, instituteID, dateFrom, dateTo)
	if err != nil {
		uc.logger.Error(ctx, "failed to get expenses by category", err, map[string]interface{}{
			"institute_id": instituteID,
		})
		return nil, fmt.Errorf("failed to get expenses by category: %w", err)
	}

	return expenses, nil
}
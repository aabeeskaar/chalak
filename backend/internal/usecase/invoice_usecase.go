package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/invoice"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type InvoiceUseCase struct {
	repo   invoice.Repository
	logger logger.Logger
}

func NewInvoiceUseCase(repo invoice.Repository, logger logger.Logger) *InvoiceUseCase {
	return &InvoiceUseCase{
		repo:   repo,
		logger: logger,
	}
}

func (uc *InvoiceUseCase) Create(ctx context.Context, req *invoice.CreateInvoiceRequest, createdBy uuid.UUID) (*invoice.Invoice, error) {
	var amount, taxAmount, totalAmount float64
	items := make([]invoice.InvoiceItem, 0, len(req.Items))

	for _, item := range req.Items {
		itemAmount := float64(item.Quantity) * item.UnitPrice
		amount += itemAmount

		items = append(items, invoice.InvoiceItem{
			ID:          uuid.New(),
			Description: item.Description,
			Quantity:    item.Quantity,
			UnitPrice:   item.UnitPrice,
			Amount:      itemAmount,
			CreatedAt:   time.Now().UTC(),
			UpdatedAt:   time.Now().UTC(),
		})
	}

	taxAmount = amount * 0.0
	totalAmount = amount + taxAmount

	invoiceNumber := fmt.Sprintf("INV-%d-%s", time.Now().Year(), uuid.New().String()[:8])

	inv := &invoice.Invoice{
		ID:            uuid.New(),
		InvoiceNumber: invoiceNumber,
		StudentID:     req.StudentID,
		InstituteID:   req.InstituteID,
		Amount:        amount,
		TaxAmount:     taxAmount,
		TotalAmount:   totalAmount,
		Status:        invoice.StatusPending,
		DueDate:       req.DueDate,
		Notes:         req.Notes,
		Items:         items,
		CreatedBy:     createdBy,
		CreatedAt:     time.Now().UTC(),
		UpdatedAt:     time.Now().UTC(),
	}

	if err := uc.repo.Create(ctx, inv); err != nil {
		uc.logger.Error(ctx, "failed to create invoice", err, map[string]interface{}{
			"student_id": req.StudentID,
		})
		return nil, fmt.Errorf("failed to create invoice: %w", err)
	}

	uc.logger.Info(ctx, "invoice created", map[string]interface{}{
		"invoice_id":     inv.ID,
		"invoice_number": inv.InvoiceNumber,
		"total_amount":   inv.TotalAmount,
	})

	return inv, nil
}

func (uc *InvoiceUseCase) GetByID(ctx context.Context, id uuid.UUID) (*invoice.Invoice, error) {
	inv, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("invoice not found")
	}
	return inv, nil
}

func (uc *InvoiceUseCase) GetByInvoiceNumber(ctx context.Context, invoiceNumber string) (*invoice.Invoice, error) {
	inv, err := uc.repo.FindByInvoiceNumber(ctx, invoiceNumber)
	if err != nil {
		return nil, apperrors.NotFound("invoice not found")
	}
	return inv, nil
}

func (uc *InvoiceUseCase) MarkAsPaid(ctx context.Context, id uuid.UUID) error {
	inv, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return apperrors.NotFound("invoice not found")
	}

	if inv.Status == invoice.StatusPaid {
		return apperrors.BadRequest("invoice already paid")
	}

	if err := uc.repo.MarkAsPaid(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to mark invoice as paid", err, map[string]interface{}{
			"invoice_id": id,
		})
		return fmt.Errorf("failed to mark invoice as paid: %w", err)
	}

	uc.logger.Info(ctx, "invoice marked as paid", map[string]interface{}{
		"invoice_id": id,
	})

	return nil
}

func (uc *InvoiceUseCase) Delete(ctx context.Context, id uuid.UUID) error {
	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete invoice", err, map[string]interface{}{
			"invoice_id": id,
		})
		return fmt.Errorf("failed to delete invoice: %w", err)
	}

	uc.logger.Info(ctx, "invoice deleted", map[string]interface{}{
		"invoice_id": id,
	})

	return nil
}

func (uc *InvoiceUseCase) List(ctx context.Context, filter invoice.InvoiceFilter) ([]*invoice.Invoice, int64, error) {
	invoices, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list invoices", err, nil)
		return nil, 0, fmt.Errorf("failed to list invoices: %w", err)
	}

	return invoices, total, nil
}

func (uc *InvoiceUseCase) GetRevenue(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (float64, error) {
	revenue, err := uc.repo.GetTotalRevenue(ctx, instituteID, dateFrom, dateTo)
	if err != nil {
		uc.logger.Error(ctx, "failed to get revenue", err, map[string]interface{}{
			"institute_id": instituteID,
		})
		return 0, fmt.Errorf("failed to get revenue: %w", err)
	}

	return revenue, nil
}
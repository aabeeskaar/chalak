package usecase

import (
	"context"
	"time"

	"github.com/chalak/backend/internal/domain/invoice"
	"github.com/chalak/backend/internal/domain/payment"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/google/uuid"
)

type PaymentUseCase struct {
	paymentRepo payment.Repository
	invoiceRepo invoice.Repository
}

func NewPaymentUseCase(paymentRepo payment.Repository, invoiceRepo invoice.Repository) *PaymentUseCase {
	return &PaymentUseCase{
		paymentRepo: paymentRepo,
		invoiceRepo: invoiceRepo,
	}
}

func (uc *PaymentUseCase) AddPayment(ctx context.Context, req *payment.CreatePaymentRequest, userID uuid.UUID) (*payment.Payment, error) {
	// Get invoice
	inv, err := uc.invoiceRepo.FindByID(ctx, req.InvoiceID)
	if err != nil {
		return nil, apperrors.NotFound("invoice not found")
	}

	// Check if invoice is already paid or canceled
	if inv.Status == invoice.StatusPaid {
		return nil, apperrors.BadRequest("invoice is already fully paid")
	}
	if inv.Status == invoice.StatusCanceled {
		return nil, apperrors.BadRequest("cannot add payment to canceled invoice")
	}

	// Check if payment amount is valid
	remainingAmount := inv.TotalAmount - inv.PaidAmount
	if req.Amount > remainingAmount {
		return nil, apperrors.BadRequest("payment amount exceeds remaining balance")
	}

	// Create payment
	p := &payment.Payment{
		InvoiceID:     req.InvoiceID,
		Amount:        req.Amount,
		PaymentMethod: req.PaymentMethod,
		PaymentDate:   req.PaymentDate,
		Notes:         req.Notes,
		CreatedBy:     userID,
	}

	if p.PaymentDate.IsZero() {
		p.PaymentDate = time.Now()
	}

	if err := uc.paymentRepo.Create(p); err != nil {
		return nil, apperrors.New(err, "failed to create payment")
	}

	// Update invoice paid amount
	inv.PaidAmount += req.Amount

	// Update status based on paid amount
	if inv.PaidAmount >= inv.TotalAmount {
		inv.Status = invoice.StatusPaid
		now := time.Now()
		inv.PaidAt = &now
	} else if inv.PaidAmount > 0 {
		// Partial payment - keep as pending or check if overdue
		if time.Now().After(inv.DueDate) {
			inv.Status = invoice.StatusOverdue
		} else {
			inv.Status = invoice.StatusPending
		}
	}

	if err := uc.invoiceRepo.Update(ctx, inv); err != nil {
		return nil, apperrors.New(err, "failed to update invoice")
	}

	return p, nil
}

func (uc *PaymentUseCase) GetPaymentsByInvoice(ctx context.Context, invoiceID uuid.UUID) ([]*payment.Payment, error) {
	// Verify invoice exists
	_, err := uc.invoiceRepo.FindByID(ctx, invoiceID)
	if err != nil {
		return nil, apperrors.NotFound("invoice not found")
	}

	payments, err := uc.paymentRepo.GetByInvoiceID(invoiceID)
	if err != nil {
		return nil, apperrors.New(err, "failed to get payments")
	}

	return payments, nil
}

func (uc *PaymentUseCase) GetPaymentByID(ctx context.Context, id uuid.UUID) (*payment.Payment, error) {
	p, err := uc.paymentRepo.GetByID(id)
	if err != nil {
		return nil, apperrors.NotFound("payment not found")
	}
	return p, nil
}

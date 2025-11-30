package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/invoice"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type InvoiceRepository struct {
	db *gorm.DB
}

func NewInvoiceRepository(db *gorm.DB) invoice.Repository {
	return &InvoiceRepository{db: db}
}

func (r *InvoiceRepository) Create(ctx context.Context, inv *invoice.Invoice) error {
	if err := r.db.WithContext(ctx).Create(inv).Error; err != nil {
		return fmt.Errorf("failed to create invoice: %w", err)
	}
	return nil
}

func (r *InvoiceRepository) FindByID(ctx context.Context, id uuid.UUID) (*invoice.Invoice, error) {
	var inv invoice.Invoice
	if err := r.db.WithContext(ctx).Preload("Items").Where("invoices.id = ? AND invoices.deleted_at IS NULL", id).First(&inv).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("invoice not found")
		}
		return nil, fmt.Errorf("failed to find invoice: %w", err)
	}
	return &inv, nil
}

func (r *InvoiceRepository) FindByInvoiceNumber(ctx context.Context, invoiceNumber string) (*invoice.Invoice, error) {
	var inv invoice.Invoice
	if err := r.db.WithContext(ctx).Preload("Items").Where("invoice_number = ? AND deleted_at IS NULL", invoiceNumber).First(&inv).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("invoice not found")
		}
		return nil, fmt.Errorf("failed to find invoice: %w", err)
	}
	return &inv, nil
}

func (r *InvoiceRepository) Update(ctx context.Context, inv *invoice.Invoice) error {
	if err := r.db.WithContext(ctx).Save(inv).Error; err != nil {
		return fmt.Errorf("failed to update invoice: %w", err)
	}
	return nil
}

func (r *InvoiceRepository) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.db.WithContext(ctx).Model(&invoice.Invoice{}).Where("id = ?", id).Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP")).Error; err != nil {
		return fmt.Errorf("failed to delete invoice: %w", err)
	}
	return nil
}

func (r *InvoiceRepository) List(ctx context.Context, filter invoice.InvoiceFilter) ([]*invoice.Invoice, int64, error) {
	var invoices []*invoice.Invoice
	var total int64

	query := r.db.WithContext(ctx).Model(&invoice.Invoice{}).Where("deleted_at IS NULL")

	if filter.StudentID != nil {
		query = query.Where("student_id = ?", *filter.StudentID)
	}

	if filter.InstituteID != nil {
		query = query.Where("institute_id = ?", *filter.InstituteID)
	}

	if filter.Status != nil {
		query = query.Where("status = ?", *filter.Status)
	}

	if filter.DateFrom != nil {
		query = query.Where("created_at >= ?", *filter.DateFrom)
	}

	if filter.DateTo != nil {
		query = query.Where("created_at <= ?", *filter.DateTo)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count invoices: %w", err)
	}

	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}
	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	if err := query.Preload("Items").Order("created_at DESC").Find(&invoices).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to list invoices: %w", err)
	}

	return invoices, total, nil
}

func (r *InvoiceRepository) MarkAsPaid(ctx context.Context, id uuid.UUID) error {
	now := time.Now().UTC()
	if err := r.db.WithContext(ctx).Model(&invoice.Invoice{}).Where("id = ?", id).Updates(map[string]interface{}{
		"status":  invoice.StatusPaid,
		"paid_at": now,
	}).Error; err != nil {
		return fmt.Errorf("failed to mark invoice as paid: %w", err)
	}
	return nil
}

func (r *InvoiceRepository) GetTotalRevenue(ctx context.Context, instituteID uuid.UUID, dateFrom, dateTo time.Time) (float64, error) {
	var total float64
	if err := r.db.WithContext(ctx).Model(&invoice.Invoice{}).
		Where("institute_id = ? AND status = ? AND created_at >= ? AND created_at <= ? AND deleted_at IS NULL", instituteID, invoice.StatusPaid, dateFrom, dateTo).
		Select("COALESCE(SUM(total_amount), 0)").
		Scan(&total).Error; err != nil {
		return 0, fmt.Errorf("failed to get total revenue: %w", err)
	}
	return total, nil
}
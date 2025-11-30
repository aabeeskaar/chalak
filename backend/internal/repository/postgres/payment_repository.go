package postgres

import (
	"github.com/chalak/backend/internal/domain/payment"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type paymentRepository struct {
	db *gorm.DB
}

func NewPaymentRepository(db *gorm.DB) payment.Repository {
	return &paymentRepository{db: db}
}

func (r *paymentRepository) Create(p *payment.Payment) error {
	return r.db.Create(p).Error
}

func (r *paymentRepository) GetByID(id uuid.UUID) (*payment.Payment, error) {
	var p payment.Payment
	err := r.db.Where("id = ? AND deleted_at IS NULL", id).First(&p).Error
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *paymentRepository) GetByInvoiceID(invoiceID uuid.UUID) ([]*payment.Payment, error) {
	var payments []*payment.Payment
	err := r.db.Where("invoice_id = ? AND deleted_at IS NULL", invoiceID).
		Order("payment_date DESC").
		Find(&payments).Error
	if err != nil {
		return nil, err
	}
	return payments, nil
}

func (r *paymentRepository) GetAll(limit, offset int) ([]*payment.Payment, error) {
	var payments []*payment.Payment
	err := r.db.Where("deleted_at IS NULL").
		Order("payment_date DESC").
		Limit(limit).
		Offset(offset).
		Find(&payments).Error
	if err != nil {
		return nil, err
	}
	return payments, nil
}

func (r *paymentRepository) Delete(id uuid.UUID) error {
	return r.db.Model(&payment.Payment{}).
		Where("id = ?", id).
		Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP")).Error
}

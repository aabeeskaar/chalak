package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/notification"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationRepository struct {
	db *gorm.DB
}

func NewNotificationRepository(db *gorm.DB) notification.Repository {
	return &NotificationRepository{db: db}
}

func (r *NotificationRepository) Create(ctx context.Context, notif *notification.Notification) error {
	if err := r.db.WithContext(ctx).Create(notif).Error; err != nil {
		return fmt.Errorf("failed to create notification: %w", err)
	}
	return nil
}

func (r *NotificationRepository) FindByID(ctx context.Context, id uuid.UUID) (*notification.Notification, error) {
	var notif notification.Notification
	if err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&notif).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("notification not found")
		}
		return nil, fmt.Errorf("failed to find notification: %w", err)
	}
	return &notif, nil
}

func (r *NotificationRepository) Update(ctx context.Context, notif *notification.Notification) error {
	if err := r.db.WithContext(ctx).Save(notif).Error; err != nil {
		return fmt.Errorf("failed to update notification: %w", err)
	}
	return nil
}

func (r *NotificationRepository) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.db.WithContext(ctx).Model(&notification.Notification{}).Where("id = ?", id).Update("deleted_at", gorm.Expr("CURRENT_TIMESTAMP")).Error; err != nil {
		return fmt.Errorf("failed to delete notification: %w", err)
	}
	return nil
}

func (r *NotificationRepository) List(ctx context.Context, filter notification.NotificationFilter) ([]*notification.Notification, int64, error) {
	var notifications []*notification.Notification
	var total int64

	query := r.db.WithContext(ctx).Model(&notification.Notification{}).Where("deleted_at IS NULL")

	if filter.UserID != nil {
		query = query.Where("user_id = ?", *filter.UserID)
	}

	if filter.Type != nil {
		query = query.Where("type = ?", *filter.Type)
	}

	if filter.IsRead != nil {
		query = query.Where("is_read = ?", *filter.IsRead)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count notifications: %w", err)
	}

	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}
	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	if err := query.Order("created_at DESC").Find(&notifications).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to list notifications: %w", err)
	}

	return notifications, total, nil
}

func (r *NotificationRepository) MarkAsRead(ctx context.Context, id uuid.UUID) error {
	now := time.Now().UTC()
	if err := r.db.WithContext(ctx).Model(&notification.Notification{}).Where("id = ?", id).Updates(map[string]interface{}{
		"is_read": true,
		"read_at": now,
	}).Error; err != nil {
		return fmt.Errorf("failed to mark notification as read: %w", err)
	}
	return nil
}

func (r *NotificationRepository) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	now := time.Now().UTC()
	if err := r.db.WithContext(ctx).Model(&notification.Notification{}).Where("user_id = ? AND is_read = false", userID).Updates(map[string]interface{}{
		"is_read": true,
		"read_at": now,
	}).Error; err != nil {
		return fmt.Errorf("failed to mark all notifications as read: %w", err)
	}
	return nil
}

func (r *NotificationRepository) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error) {
	var count int64
	if err := r.db.WithContext(ctx).Model(&notification.Notification{}).
		Where("user_id = ? AND is_read = false AND deleted_at IS NULL", userID).
		Count(&count).Error; err != nil {
		return 0, fmt.Errorf("failed to get unread notification count: %w", err)
	}
	return count, nil
}
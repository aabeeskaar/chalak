package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/notification"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
)

type NotificationUseCase struct {
	repo   notification.Repository
	logger logger.Logger
}

func NewNotificationUseCase(repo notification.Repository, logger logger.Logger) *NotificationUseCase {
	return &NotificationUseCase{
		repo:   repo,
		logger: logger,
	}
}

func (uc *NotificationUseCase) Create(ctx context.Context, req *notification.CreateNotificationRequest) (*notification.Notification, error) {
	notif := &notification.Notification{
		ID:        uuid.New(),
		UserID:    req.UserID,
		Type:      req.Type,
		Title:     req.Title,
		Message:   req.Message,
		Data:      req.Data,
		IsRead:    false,
		SentVia:   req.SentVia,
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}

	if err := uc.repo.Create(ctx, notif); err != nil {
		uc.logger.Error(ctx, "failed to create notification", err, map[string]interface{}{
			"user_id": req.UserID,
			"type":    req.Type,
		})
		return nil, fmt.Errorf("failed to create notification: %w", err)
	}

	uc.logger.Info(ctx, "notification created", map[string]interface{}{
		"notification_id": notif.ID,
		"user_id":         notif.UserID,
		"type":            notif.Type,
	})

	return notif, nil
}

func (uc *NotificationUseCase) GetByID(ctx context.Context, id uuid.UUID) (*notification.Notification, error) {
	notif, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.NotFound("notification not found")
	}
	return notif, nil
}

func (uc *NotificationUseCase) Delete(ctx context.Context, id uuid.UUID) error {
	if err := uc.repo.Delete(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to delete notification", err, map[string]interface{}{
			"notification_id": id,
		})
		return fmt.Errorf("failed to delete notification: %w", err)
	}

	uc.logger.Info(ctx, "notification deleted", map[string]interface{}{
		"notification_id": id,
	})

	return nil
}

func (uc *NotificationUseCase) List(ctx context.Context, filter notification.NotificationFilter) ([]*notification.Notification, int64, error) {
	notifications, total, err := uc.repo.List(ctx, filter)
	if err != nil {
		uc.logger.Error(ctx, "failed to list notifications", err, nil)
		return nil, 0, fmt.Errorf("failed to list notifications: %w", err)
	}

	return notifications, total, nil
}

func (uc *NotificationUseCase) MarkAsRead(ctx context.Context, id uuid.UUID) error {
	notif, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return apperrors.NotFound("notification not found")
	}

	if notif.IsRead {
		return apperrors.BadRequest("notification is already read")
	}

	if err := uc.repo.MarkAsRead(ctx, id); err != nil {
		uc.logger.Error(ctx, "failed to mark notification as read", err, map[string]interface{}{
			"notification_id": id,
		})
		return fmt.Errorf("failed to mark notification as read: %w", err)
	}

	uc.logger.Info(ctx, "notification marked as read", map[string]interface{}{
		"notification_id": id,
	})

	return nil
}

func (uc *NotificationUseCase) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	if err := uc.repo.MarkAllAsRead(ctx, userID); err != nil {
		uc.logger.Error(ctx, "failed to mark all notifications as read", err, map[string]interface{}{
			"user_id": userID,
		})
		return fmt.Errorf("failed to mark all notifications as read: %w", err)
	}

	uc.logger.Info(ctx, "all notifications marked as read", map[string]interface{}{
		"user_id": userID,
	})

	return nil
}

func (uc *NotificationUseCase) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error) {
	count, err := uc.repo.GetUnreadCount(ctx, userID)
	if err != nil {
		uc.logger.Error(ctx, "failed to get unread notification count", err, map[string]interface{}{
			"user_id": userID,
		})
		return 0, fmt.Errorf("failed to get unread notification count: %w", err)
	}

	return count, nil
}

// SendNotification is a helper method to create and send notifications to users
func (uc *NotificationUseCase) SendNotification(ctx context.Context, userID uuid.UUID, notificationType, title, message string, data string, sentVia string) error {
	req := &notification.CreateNotificationRequest{
		UserID:  userID,
		Type:    notificationType,
		Title:   title,
		Message: message,
		Data:    data,
		SentVia: sentVia,
	}

	_, err := uc.Create(ctx, req)
	return err
}

// SendBulkNotifications sends notifications to multiple users
func (uc *NotificationUseCase) SendBulkNotifications(ctx context.Context, userIDs []uuid.UUID, notificationType, title, message string, data string, sentVia string) error {
	for _, userID := range userIDs {
		if err := uc.SendNotification(ctx, userID, notificationType, title, message, data, sentVia); err != nil {
			uc.logger.Error(ctx, "failed to send notification to user", err, map[string]interface{}{
				"user_id": userID,
				"type":    notificationType,
			})
			// Continue with other users even if one fails
			continue
		}
	}

	uc.logger.Info(ctx, "bulk notifications sent", map[string]interface{}{
		"user_count": len(userIDs),
		"type":       notificationType,
	})

	return nil
}
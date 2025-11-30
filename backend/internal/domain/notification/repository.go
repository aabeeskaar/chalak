package notification

import (
	"context"

	"github.com/google/uuid"
)

type Repository interface {
	Create(ctx context.Context, notification *Notification) error
	FindByID(ctx context.Context, id uuid.UUID) (*Notification, error)
	Update(ctx context.Context, notification *Notification) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, filter NotificationFilter) ([]*Notification, int64, error)
	MarkAsRead(ctx context.Context, id uuid.UUID) error
	MarkAllAsRead(ctx context.Context, userID uuid.UUID) error
	GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error)
}
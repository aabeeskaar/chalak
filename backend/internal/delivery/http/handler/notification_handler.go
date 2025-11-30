package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/chalak/backend/internal/domain/notification"
	"github.com/chalak/backend/internal/usecase"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type NotificationHandler struct {
	useCase   *usecase.NotificationUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewNotificationHandler(useCase *usecase.NotificationUseCase, validator *validator.Validator, logger logger.Logger) *NotificationHandler {
	return &NotificationHandler{
		useCase:   useCase,
		validator: validator,
		logger:    logger,
	}
}

func (h *NotificationHandler) Create(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req notification.CreateNotificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	notif, err := h.useCase.Create(ctx, &req)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusCreated, notif)
}

func (h *NotificationHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid notification ID"))
		return
	}

	notif, err := h.useCase.GetByID(ctx, id)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, notif)
}

func (h *NotificationHandler) Delete(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid notification ID"))
		return
	}

	if err := h.useCase.Delete(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "notification deleted successfully",
	})
}

func (h *NotificationHandler) List(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	filter := notification.NotificationFilter{
		Limit:  10,
		Offset: 0,
	}

	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 {
			filter.Limit = limit
		}
	}

	if offsetStr := r.URL.Query().Get("offset"); offsetStr != "" {
		if offset, err := strconv.Atoi(offsetStr); err == nil && offset >= 0 {
			filter.Offset = offset
		}
	}

	if userIDStr := r.URL.Query().Get("user_id"); userIDStr != "" {
		userID, err := uuid.Parse(userIDStr)
		if err == nil {
			filter.UserID = &userID
		}
	}

	if notifType := r.URL.Query().Get("type"); notifType != "" {
		filter.Type = &notifType
	}

	if isReadStr := r.URL.Query().Get("is_read"); isReadStr != "" {
		if isRead, err := strconv.ParseBool(isReadStr); err == nil {
			filter.IsRead = &isRead
		}
	}

	notifications, total, err := h.useCase.List(ctx, filter)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"data":  notifications,
		"total": total,
	})
}

func (h *NotificationHandler) MarkAsRead(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid notification ID"))
		return
	}

	if err := h.useCase.MarkAsRead(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "notification marked as read",
	})
}

func (h *NotificationHandler) MarkAllAsRead(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userIDStr := chi.URLParam(r, "user_id")

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid user ID"))
		return
	}

	if err := h.useCase.MarkAllAsRead(ctx, userID); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "all notifications marked as read",
	})
}

func (h *NotificationHandler) GetUnreadCount(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userIDStr := chi.URLParam(r, "user_id")

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid user ID"))
		return
	}

	count, err := h.useCase.GetUnreadCount(ctx, userID)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"user_id":      userID,
		"unread_count": count,
	})
}

func (h *NotificationHandler) GetMyNotifications(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// Get user ID from context (set by auth middleware)
	userID := ctx.Value("user_id").(uuid.UUID)

	filter := notification.NotificationFilter{
		UserID: &userID,
		Limit:  20,
		Offset: 0,
	}

	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 {
			filter.Limit = limit
		}
	}

	if offsetStr := r.URL.Query().Get("offset"); offsetStr != "" {
		if offset, err := strconv.Atoi(offsetStr); err == nil && offset >= 0 {
			filter.Offset = offset
		}
	}

	if notifType := r.URL.Query().Get("type"); notifType != "" {
		filter.Type = &notifType
	}

	if isReadStr := r.URL.Query().Get("is_read"); isReadStr != "" {
		if isRead, err := strconv.ParseBool(isReadStr); err == nil {
			filter.IsRead = &isRead
		}
	}

	notifications, total, err := h.useCase.List(ctx, filter)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"data":  notifications,
		"total": total,
	})
}

func (h *NotificationHandler) GetMyUnreadCount(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// Get user ID from context (set by auth middleware)
	userID := ctx.Value("user_id").(uuid.UUID)

	count, err := h.useCase.GetUnreadCount(ctx, userID)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"user_id":      userID,
		"unread_count": count,
	})
}

func (h *NotificationHandler) respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func (h *NotificationHandler) respondError(w http.ResponseWriter, r *http.Request, err error) {
	statusCode := apperrors.GetStatusCode(err)

	var appErr *apperrors.AppError
	response := map[string]interface{}{
		"error": err.Error(),
	}

	if errors, ok := err.(*apperrors.AppError); ok {
		appErr = errors
		if appErr.Details != nil {
			response["details"] = appErr.Details
		}
	}

	h.logger.Error(r.Context(), "request error", err, map[string]interface{}{
		"method":      r.Method,
		"path":        r.URL.Path,
		"status_code": statusCode,
	})

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}
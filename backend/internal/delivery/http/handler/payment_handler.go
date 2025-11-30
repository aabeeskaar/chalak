package handler

import (
	"encoding/json"
	"net/http"

	"github.com/chalak/backend/internal/delivery/http/middleware"
	"github.com/chalak/backend/internal/domain/payment"
	"github.com/chalak/backend/internal/usecase"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type PaymentHandler struct {
	useCase   *usecase.PaymentUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewPaymentHandler(useCase *usecase.PaymentUseCase, validator *validator.Validator, logger logger.Logger) *PaymentHandler {
	return &PaymentHandler{
		useCase:   useCase,
		validator: validator,
		logger:    logger,
	}
}

func (h *PaymentHandler) AddPayment(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req payment.CreatePaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	userIDValue := ctx.Value(middleware.UserIDKey)
	if userIDValue == nil {
		h.respondError(w, r, apperrors.Unauthorized("user not authenticated"))
		return
	}

	userID, ok := userIDValue.(uuid.UUID)
	if !ok {
		h.respondError(w, r, apperrors.Unauthorized("invalid user id"))
		return
	}

	p, err := h.useCase.AddPayment(ctx, &req, userID)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusCreated, p)
}

func (h *PaymentHandler) GetPaymentsByInvoice(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	invoiceIDStr := chi.URLParam(r, "invoice_id")

	invoiceID, err := uuid.Parse(invoiceIDStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid invoice ID"))
		return
	}

	payments, err := h.useCase.GetPaymentsByInvoice(ctx, invoiceID)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": payments,
	})
}

func (h *PaymentHandler) GetPaymentByID(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid payment ID"))
		return
	}

	p, err := h.useCase.GetPaymentByID(ctx, id)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, p)
}

func (h *PaymentHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *PaymentHandler) respondError(w http.ResponseWriter, r *http.Request, err error) {
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

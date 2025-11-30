package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/chalak/backend/internal/delivery/http/middleware"
	"github.com/chalak/backend/internal/domain/invoice"
	"github.com/chalak/backend/internal/usecase"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type InvoiceHandler struct {
	useCase   *usecase.InvoiceUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewInvoiceHandler(useCase *usecase.InvoiceUseCase, validator *validator.Validator, logger logger.Logger) *InvoiceHandler {
	return &InvoiceHandler{
		useCase:   useCase,
		validator: validator,
		logger:    logger,
	}
}

func (h *InvoiceHandler) Create(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req invoice.CreateInvoiceRequest
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

	inv, err := h.useCase.Create(ctx, &req, userID)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusCreated, inv)
}

func (h *InvoiceHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid invoice ID"))
		return
	}

	inv, err := h.useCase.GetByID(ctx, id)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, inv)
}

func (h *InvoiceHandler) MarkAsPaid(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid invoice ID"))
		return
	}

	if err := h.useCase.MarkAsPaid(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "invoice marked as paid",
	})
}

func (h *InvoiceHandler) Delete(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid invoice ID"))
		return
	}

	if err := h.useCase.Delete(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "invoice deleted successfully",
	})
}

func (h *InvoiceHandler) List(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	filter := invoice.InvoiceFilter{
		Limit:  10,
		Offset: 0,
	}

	if studentIDStr := r.URL.Query().Get("student_id"); studentIDStr != "" {
		studentID, err := uuid.Parse(studentIDStr)
		if err == nil {
			filter.StudentID = &studentID
		}
	}

	if instituteIDStr := r.URL.Query().Get("institute_id"); instituteIDStr != "" {
		instituteID, err := uuid.Parse(instituteIDStr)
		if err == nil {
			filter.InstituteID = &instituteID
		}
	}

	if status := r.URL.Query().Get("status"); status != "" {
		filter.Status = &status
	}

	invoices, total, err := h.useCase.List(ctx, filter)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"data":  invoices,
		"total": total,
	})
}

func (h *InvoiceHandler) GetRevenue(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	instituteIDStr := chi.URLParam(r, "institute_id")

	instituteID, err := uuid.Parse(instituteIDStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid institute ID"))
		return
	}

	dateFrom := time.Now().AddDate(0, -1, 0)
	dateTo := time.Now()

	if dateFromStr := r.URL.Query().Get("date_from"); dateFromStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateFromStr); err == nil {
			dateFrom = parsed
		}
	}

	if dateToStr := r.URL.Query().Get("date_to"); dateToStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateToStr); err == nil {
			dateTo = parsed
		}
	}

	revenue, err := h.useCase.GetRevenue(ctx, instituteID, dateFrom, dateTo)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"institute_id": instituteID,
		"date_from":    dateFrom,
		"date_to":      dateTo,
		"revenue":      revenue,
	})
}

func (h *InvoiceHandler) respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func (h *InvoiceHandler) respondError(w http.ResponseWriter, r *http.Request, err error) {
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
package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/chalak/backend/internal/domain/expense"
	"github.com/chalak/backend/internal/usecase"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type ExpenseHandler struct {
	useCase   *usecase.ExpenseUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewExpenseHandler(useCase *usecase.ExpenseUseCase, validator *validator.Validator, logger logger.Logger) *ExpenseHandler {
	return &ExpenseHandler{
		useCase:   useCase,
		validator: validator,
		logger:    logger,
	}
}

func (h *ExpenseHandler) Create(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req expense.CreateExpenseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	userID := ctx.Value("user_id").(uuid.UUID)

	exp, err := h.useCase.Create(ctx, &req, userID)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusCreated, exp)
}

func (h *ExpenseHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid expense ID"))
		return
	}

	exp, err := h.useCase.GetByID(ctx, id)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, exp)
}

func (h *ExpenseHandler) Update(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid expense ID"))
		return
	}

	var req expense.UpdateExpenseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	exp, err := h.useCase.Update(ctx, id, &req)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, exp)
}

func (h *ExpenseHandler) Delete(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid expense ID"))
		return
	}

	if err := h.useCase.Delete(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "expense deleted successfully",
	})
}

func (h *ExpenseHandler) List(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	filter := expense.ExpenseFilter{
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

	if instituteIDStr := r.URL.Query().Get("institute_id"); instituteIDStr != "" {
		instituteID, err := uuid.Parse(instituteIDStr)
		if err == nil {
			filter.InstituteID = &instituteID
		}
	}

	if category := r.URL.Query().Get("category"); category != "" {
		filter.Category = &category
	}

	if status := r.URL.Query().Get("status"); status != "" {
		filter.Status = &status
	}

	if dateFromStr := r.URL.Query().Get("date_from"); dateFromStr != "" {
		if dateFrom, err := time.Parse("2006-01-02", dateFromStr); err == nil {
			filter.DateFrom = &dateFrom
		}
	}

	if dateToStr := r.URL.Query().Get("date_to"); dateToStr != "" {
		if dateTo, err := time.Parse("2006-01-02", dateToStr); err == nil {
			filter.DateTo = &dateTo
		}
	}

	expenses, total, err := h.useCase.List(ctx, filter)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"data":  expenses,
		"total": total,
	})
}

func (h *ExpenseHandler) Approve(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid expense ID"))
		return
	}

	userID := ctx.Value("user_id").(uuid.UUID)

	if err := h.useCase.Approve(ctx, id, userID); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "expense approved successfully",
	})
}

func (h *ExpenseHandler) Reject(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid expense ID"))
		return
	}

	userID := ctx.Value("user_id").(uuid.UUID)

	if err := h.useCase.Reject(ctx, id, userID); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "expense rejected successfully",
	})
}

func (h *ExpenseHandler) GetTotalExpenses(w http.ResponseWriter, r *http.Request) {
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

	total, err := h.useCase.GetTotalExpenses(ctx, instituteID, dateFrom, dateTo)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"institute_id": instituteID,
		"date_from":    dateFrom,
		"date_to":      dateTo,
		"total":        total,
	})
}

func (h *ExpenseHandler) GetExpensesByCategory(w http.ResponseWriter, r *http.Request) {
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

	expenses, err := h.useCase.GetExpensesByCategory(ctx, instituteID, dateFrom, dateTo)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"institute_id": instituteID,
		"date_from":    dateFrom,
		"date_to":      dateTo,
		"expenses":     expenses,
	})
}

func (h *ExpenseHandler) respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func (h *ExpenseHandler) respondError(w http.ResponseWriter, r *http.Request, err error) {
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
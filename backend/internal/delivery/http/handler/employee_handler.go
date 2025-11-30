package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/chalak/backend/internal/domain/employee"
	"github.com/chalak/backend/internal/usecase"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type EmployeeHandler struct {
	useCase   *usecase.EmployeeUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewEmployeeHandler(useCase *usecase.EmployeeUseCase, validator *validator.Validator, logger logger.Logger) *EmployeeHandler {
	return &EmployeeHandler{
		useCase:   useCase,
		validator: validator,
		logger:    logger,
	}
}

func (h *EmployeeHandler) Create(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req employee.CreateEmployeeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	emp, err := h.useCase.Create(ctx, &req)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusCreated, emp)
}

func (h *EmployeeHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid employee ID"))
		return
	}

	emp, err := h.useCase.GetByID(ctx, id)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, emp)
}

func (h *EmployeeHandler) Update(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid employee ID"))
		return
	}

	var req employee.UpdateEmployeeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	emp, err := h.useCase.Update(ctx, id, &req)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, emp)
}

func (h *EmployeeHandler) Delete(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid employee ID"))
		return
	}

	if err := h.useCase.Delete(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "employee deleted successfully",
	})
}

func (h *EmployeeHandler) List(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	filter := employee.EmployeeFilter{
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

	if department := r.URL.Query().Get("department"); department != "" {
		filter.Department = &department
	}

	if position := r.URL.Query().Get("position"); position != "" {
		filter.Position = &position
	}

	if status := r.URL.Query().Get("status"); status != "" {
		filter.Status = &status
	}

	if search := r.URL.Query().Get("search"); search != "" {
		filter.Search = &search
	}

	employees, total, err := h.useCase.List(ctx, filter)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"data":  employees,
		"total": total,
	})
}

func (h *EmployeeHandler) Terminate(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid employee ID"))
		return
	}

	if err := h.useCase.Terminate(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "employee terminated successfully",
	})
}

func (h *EmployeeHandler) respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func (h *EmployeeHandler) respondError(w http.ResponseWriter, r *http.Request, err error) {
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
package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/chalak/backend/internal/delivery/http/middleware"
	"github.com/chalak/backend/internal/domain/attendance"
	"github.com/chalak/backend/internal/usecase"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type AttendanceHandler struct {
	useCase   *usecase.AttendanceUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewAttendanceHandler(useCase *usecase.AttendanceUseCase, validator *validator.Validator, logger logger.Logger) *AttendanceHandler {
	return &AttendanceHandler{
		useCase:   useCase,
		validator: validator,
		logger:    logger,
	}
}

func (h *AttendanceHandler) MarkAttendance(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req attendance.MarkAttendanceRequest
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
		h.respondError(w, r, apperrors.Unauthorized("invalid user ID"))
		return
	}

	att, err := h.useCase.MarkAttendance(ctx, &req, userID)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusCreated, att)
}

func (h *AttendanceHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid attendance ID"))
		return
	}

	att, err := h.useCase.GetByID(ctx, id)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, att)
}

func (h *AttendanceHandler) Update(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid attendance ID"))
		return
	}

	var req attendance.MarkAttendanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	att, err := h.useCase.Update(ctx, id, &req)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, att)
}

func (h *AttendanceHandler) Delete(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idStr := chi.URLParam(r, "id")

	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid attendance ID"))
		return
	}

	if err := h.useCase.Delete(ctx, id); err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "attendance deleted successfully",
	})
}

func (h *AttendanceHandler) List(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	filter := attendance.AttendanceFilter{
		Limit:  20, // Default 20 records per page
		Offset: 0,
	}

	// Parse limit from query parameters
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 {
			filter.Limit = limit
		}
	}

	// Parse page from query parameters and calculate offset
	if pageStr := r.URL.Query().Get("page"); pageStr != "" {
		if page, err := strconv.Atoi(pageStr); err == nil && page > 0 {
			filter.Offset = (page - 1) * filter.Limit
		}
	}

	if studentIDStr := r.URL.Query().Get("student_id"); studentIDStr != "" {
		studentID, err := uuid.Parse(studentIDStr)
		if err == nil {
			filter.StudentID = &studentID
		}
	}

	if classIDStr := r.URL.Query().Get("class_id"); classIDStr != "" {
		classID, err := uuid.Parse(classIDStr)
		if err == nil {
			filter.ClassID = &classID
		}
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

	attendances, total, err := h.useCase.List(ctx, filter)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"data":  attendances,
		"total": total,
	})
}

func (h *AttendanceHandler) GetStudentStats(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	studentIDStr := chi.URLParam(r, "student_id")

	studentID, err := uuid.Parse(studentIDStr)
	if err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid student ID"))
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

	stats, err := h.useCase.GetStudentStats(ctx, studentID, dateFrom, dateTo)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"student_id": studentID,
		"date_from":  dateFrom,
		"date_to":    dateTo,
		"stats":      stats,
	})
}

func (h *AttendanceHandler) respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func (h *AttendanceHandler) respondError(w http.ResponseWriter, r *http.Request, err error) {
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
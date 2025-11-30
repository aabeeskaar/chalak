package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/chalak/backend/internal/domain/course"
	"github.com/chalak/backend/internal/usecase"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type CourseHandler struct {
	useCase   usecase.CourseUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewCourseHandler(uc usecase.CourseUseCase, val *validator.Validator, log logger.Logger) *CourseHandler {
	return &CourseHandler{
		useCase:   uc,
		validator: val,
		logger:    log,
	}
}

func (h *CourseHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req course.CreateCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid request payload", err)
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondJSON(w, http.StatusBadRequest, ErrorResponse{
			Error:   "validation failed",
			Message: "Invalid request data",
		})
		return
	}

	c, err := h.useCase.CreateCourse(r.Context(), req)
	if err != nil {
		h.logger.Error(r.Context(), "failed to create course", err, nil)
		h.respondError(w, http.StatusInternalServerError, "failed to create course", err)
		return
	}

	h.respondJSON(w, http.StatusCreated, SuccessResponse{
		Data:    c,
		Message: "course created successfully",
	})
}

func (h *CourseHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid course id", err)
		return
	}

	c, err := h.useCase.GetCourse(r.Context(), id)
	if err != nil {
		h.logger.Error(r.Context(), "failed to get course", err, map[string]interface{}{
			"course_id": id,
		})
		h.respondError(w, http.StatusNotFound, "course not found", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{Data: c})
}

func (h *CourseHandler) GetByCode(w http.ResponseWriter, r *http.Request) {
	code := chi.URLParam(r, "code")
	if code == "" {
		h.respondError(w, http.StatusBadRequest, "course code is required", nil)
		return
	}

	c, err := h.useCase.GetCourseByCode(r.Context(), code)
	if err != nil {
		h.logger.Error(r.Context(), "failed to get course by code", err, map[string]interface{}{
			"code": code,
		})
		h.respondError(w, http.StatusNotFound, "course not found", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{Data: c})
}

func (h *CourseHandler) Update(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid course id", err)
		return
	}

	var req course.UpdateCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid request payload", err)
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondJSON(w, http.StatusBadRequest, ErrorResponse{
			Error:   "validation failed",
			Message: "Invalid request data",
		})
		return
	}

	c, err := h.useCase.UpdateCourse(r.Context(), id, req)
	if err != nil {
		h.logger.Error(r.Context(), "failed to update course", err, map[string]interface{}{
			"course_id": id,
		})
		h.respondError(w, http.StatusInternalServerError, "failed to update course", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{
		Data:    c,
		Message: "course updated successfully",
	})
}

func (h *CourseHandler) Delete(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid course id", err)
		return
	}

	if err := h.useCase.DeleteCourse(r.Context(), id); err != nil {
		h.logger.Error(r.Context(), "failed to delete course", err, map[string]interface{}{
			"course_id": id,
		})
		h.respondError(w, http.StatusInternalServerError, "failed to delete course", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{
		Message: "course deleted successfully",
	})
}

func (h *CourseHandler) List(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()

	var filter course.CourseFilter

	if search := query.Get("search"); search != "" {
		filter.Search = search
	}

	if isActiveStr := query.Get("is_active"); isActiveStr != "" {
		isActive := isActiveStr == "true"
		filter.IsActive = &isActive
	}

	limit := 20
	if limitStr := query.Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}
	filter.Limit = limit

	page := 1
	if pageStr := query.Get("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}
	filter.Offset = (page - 1) * limit

	courses, total, err := h.useCase.ListCourses(r.Context(), filter)
	if err != nil {
		h.logger.Error(r.Context(), "failed to list courses", err, nil)
		h.respondError(w, http.StatusInternalServerError, "failed to list courses", err)
		return
	}

	h.respondJSON(w, http.StatusOK, PaginatedResponse{
		Data:  courses,
		Total: int64(total),
		Limit: limit,
		Page:  page,
	})
}

func (h *CourseHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *CourseHandler) respondError(w http.ResponseWriter, status int, message string, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	errResp := ErrorResponse{
		Error: message,
	}
	if err != nil {
		errResp.Message = err.Error()
	}
	json.NewEncoder(w).Encode(errResp)
}

package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/chalak/backend/internal/domain/student"
	"github.com/chalak/backend/internal/usecase"
	"github.com/chalak/backend/pkg/logger"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type StudentHandler struct {
	useCase usecase.StudentUseCase
	logger  logger.Logger
}

func NewStudentHandler(uc usecase.StudentUseCase, log logger.Logger) *StudentHandler {
	return &StudentHandler{
		useCase: uc,
		logger:  log,
	}
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message,omitempty"`
}

type SuccessResponse struct {
	Data    interface{} `json:"data"`
	Message string      `json:"message,omitempty"`
}

type PaginatedResponse struct {
	Data  interface{} `json:"data"`
	Total int64       `json:"total"`
	Limit int         `json:"limit"`
	Page  int         `json:"page"`
}

func (h *StudentHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req student.CreateStudentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid request payload", err)
		return
	}

	s, err := h.useCase.CreateStudent(r.Context(), req)
	if err != nil {
		h.logger.Error(r.Context(), "failed to create student", err, nil)
		h.respondError(w, http.StatusInternalServerError, "failed to create student", err)
		return
	}

	h.respondJSON(w, http.StatusCreated, SuccessResponse{
		Data:    s,
		Message: "student created successfully",
	})
}

func (h *StudentHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid student id", err)
		return
	}

	s, err := h.useCase.GetStudent(r.Context(), id)
	if err != nil {
		h.logger.Error(r.Context(), "failed to get student", err, map[string]interface{}{
			"student_id": id,
		})
		h.respondError(w, http.StatusNotFound, "student not found", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{Data: s})
}

func (h *StudentHandler) Update(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid student id", err)
		return
	}

	var req student.UpdateStudentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid request payload", err)
		return
	}

	s, err := h.useCase.UpdateStudent(r.Context(), id, req)
	if err != nil {
		h.logger.Error(r.Context(), "failed to update student", err, map[string]interface{}{
			"student_id": id,
		})
		h.respondError(w, http.StatusInternalServerError, "failed to update student", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{
		Data:    s,
		Message: "student updated successfully",
	})
}

func (h *StudentHandler) Delete(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid student id", err)
		return
	}

	if err := h.useCase.DeleteStudent(r.Context(), id); err != nil {
		h.logger.Error(r.Context(), "failed to delete student", err, map[string]interface{}{
			"student_id": id,
		})
		h.respondError(w, http.StatusInternalServerError, "failed to delete student", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{
		Message: "student deleted successfully",
	})
}

func (h *StudentHandler) List(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()

	var filter student.StudentFilter

	if instituteIDStr := query.Get("institute_id"); instituteIDStr != "" {
		instituteID, err := uuid.Parse(instituteIDStr)
		if err == nil {
			filter.InstituteID = &instituteID
		}
	}

	if status := query.Get("status"); status != "" {
		filter.Status = &status
	}

	if search := query.Get("search"); search != "" {
		filter.Search = &search
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

	students, total, err := h.useCase.ListStudents(r.Context(), filter)
	if err != nil {
		h.logger.Error(r.Context(), "failed to list students", err, nil)
		h.respondError(w, http.StatusInternalServerError, "failed to list students", err)
		return
	}

	h.respondJSON(w, http.StatusOK, PaginatedResponse{
		Data:  students,
		Total: total,
		Limit: limit,
		Page:  page,
	})
}

func (h *StudentHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *StudentHandler) respondError(w http.ResponseWriter, status int, message string, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(ErrorResponse{
		Error:   message,
		Message: err.Error(),
	})
}
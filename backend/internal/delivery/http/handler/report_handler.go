package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/chalak/backend/internal/usecase"
	"github.com/go-chi/chi/v5"
)

type ReportHandler struct {
	reportUseCase *usecase.ReportUseCase
}

func NewReportHandler(reportUseCase *usecase.ReportUseCase) *ReportHandler {
	return &ReportHandler{
		reportUseCase: reportUseCase,
	}
}

func (h *ReportHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    data,
	})
}

func (h *ReportHandler) respondError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": false,
		"message": message,
	})
}

// GetQuickStats retrieves quick overview statistics for dashboard
func (h *ReportHandler) GetQuickStats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.reportUseCase.GetQuickStats(r.Context())
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, stats)
}

// GetAttendanceReport retrieves attendance statistics for a date range
func (h *ReportHandler) GetAttendanceReport(w http.ResponseWriter, r *http.Request) {
	startDateStr := r.URL.Query().Get("start_date")
	endDateStr := r.URL.Query().Get("end_date")

	if startDateStr == "" || endDateStr == "" {
		h.respondError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD")
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD")
		return
	}

	report, err := h.reportUseCase.GetAttendanceReport(r.Context(), startDate, endDate)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, report)
}

// GetStudentAttendanceReport retrieves attendance report for a specific student
func (h *ReportHandler) GetStudentAttendanceReport(w http.ResponseWriter, r *http.Request) {
	studentID := chi.URLParam(r, "student_id")
	startDateStr := r.URL.Query().Get("start_date")
	endDateStr := r.URL.Query().Get("end_date")

	if startDateStr == "" || endDateStr == "" {
		h.respondError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD")
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD")
		return
	}

	report, err := h.reportUseCase.GetStudentAttendanceReport(r.Context(), studentID, startDate, endDate)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, report)
}

// GetFinancialReport retrieves comprehensive financial report
func (h *ReportHandler) GetFinancialReport(w http.ResponseWriter, r *http.Request) {
	startDateStr := r.URL.Query().Get("start_date")
	endDateStr := r.URL.Query().Get("end_date")

	if startDateStr == "" || endDateStr == "" {
		h.respondError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD")
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD")
		return
	}

	report, err := h.reportUseCase.GetFinancialReport(r.Context(), startDate, endDate)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, report)
}

// GetStudentReport retrieves student enrollment and distribution statistics
func (h *ReportHandler) GetStudentReport(w http.ResponseWriter, r *http.Request) {
	startDateStr := r.URL.Query().Get("start_date")
	endDateStr := r.URL.Query().Get("end_date")

	if startDateStr == "" || endDateStr == "" {
		h.respondError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD")
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD")
		return
	}

	report, err := h.reportUseCase.GetStudentReport(r.Context(), startDate, endDate)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, report)
}

// GetRevenueReport retrieves detailed revenue analysis
func (h *ReportHandler) GetRevenueReport(w http.ResponseWriter, r *http.Request) {
	startDateStr := r.URL.Query().Get("start_date")
	endDateStr := r.URL.Query().Get("end_date")

	if startDateStr == "" || endDateStr == "" {
		h.respondError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD")
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD")
		return
	}

	report, err := h.reportUseCase.GetRevenueReport(r.Context(), startDate, endDate)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, report)
}

// GetExpenseReport retrieves detailed expense analysis
func (h *ReportHandler) GetExpenseReport(w http.ResponseWriter, r *http.Request) {
	startDateStr := r.URL.Query().Get("start_date")
	endDateStr := r.URL.Query().Get("end_date")

	if startDateStr == "" || endDateStr == "" {
		h.respondError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD")
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD")
		return
	}

	report, err := h.reportUseCase.GetExpenseReport(r.Context(), startDate, endDate)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, report)
}

// GetDashboardStats retrieves dashboard statistics for today
func (h *ReportHandler) GetDashboardStats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.reportUseCase.GetDashboardStats(r.Context())
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.respondJSON(w, http.StatusOK, stats)
}

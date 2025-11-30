package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	pkg "github.com/chalak/backend/internal/domain/package"
	"github.com/chalak/backend/internal/usecase"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type PackageHandler struct {
	useCase   usecase.PackageUseCase
	validator *validator.Validator
	logger    logger.Logger
}

func NewPackageHandler(uc usecase.PackageUseCase, val *validator.Validator, log logger.Logger) *PackageHandler {
	return &PackageHandler{
		useCase:   uc,
		validator: val,
		logger:    log,
	}
}

func (h *PackageHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req pkg.CreatePackageRequest
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

	p, err := h.useCase.CreatePackage(r.Context(), req)
	if err != nil {
		h.logger.Error(r.Context(), "failed to create package", err, nil)
		h.respondError(w, http.StatusInternalServerError, "failed to create package", err)
		return
	}

	h.respondJSON(w, http.StatusCreated, SuccessResponse{
		Data:    p,
		Message: "package created successfully",
	})
}

func (h *PackageHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid package id", err)
		return
	}

	p, err := h.useCase.GetPackage(r.Context(), id)
	if err != nil {
		h.logger.Error(r.Context(), "failed to get package", err, map[string]interface{}{
			"package_id": id,
		})
		h.respondError(w, http.StatusNotFound, "package not found", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{Data: p})
}

func (h *PackageHandler) GetByCode(w http.ResponseWriter, r *http.Request) {
	code := chi.URLParam(r, "code")
	if code == "" {
		h.respondError(w, http.StatusBadRequest, "package code is required", nil)
		return
	}

	p, err := h.useCase.GetPackageByCode(r.Context(), code)
	if err != nil {
		h.logger.Error(r.Context(), "failed to get package by code", err, map[string]interface{}{
			"code": code,
		})
		h.respondError(w, http.StatusNotFound, "package not found", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{Data: p})
}

func (h *PackageHandler) Update(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid package id", err)
		return
	}

	var req pkg.UpdatePackageRequest
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

	p, err := h.useCase.UpdatePackage(r.Context(), id, req)
	if err != nil {
		h.logger.Error(r.Context(), "failed to update package", err, map[string]interface{}{
			"package_id": id,
		})
		h.respondError(w, http.StatusInternalServerError, "failed to update package", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{
		Data:    p,
		Message: "package updated successfully",
	})
}

func (h *PackageHandler) Delete(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, http.StatusBadRequest, "invalid package id", err)
		return
	}

	if err := h.useCase.DeletePackage(r.Context(), id); err != nil {
		h.logger.Error(r.Context(), "failed to delete package", err, map[string]interface{}{
			"package_id": id,
		})
		h.respondError(w, http.StatusInternalServerError, "failed to delete package", err)
		return
	}

	h.respondJSON(w, http.StatusOK, SuccessResponse{
		Message: "package deleted successfully",
	})
}

func (h *PackageHandler) List(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()

	var filter pkg.PackageFilter

	if search := query.Get("search"); search != "" {
		filter.Search = search
	}

	if isActiveStr := query.Get("is_active"); isActiveStr != "" {
		isActive := isActiveStr == "true"
		filter.IsActive = &isActive
	}

	if minPriceStr := query.Get("min_price"); minPriceStr != "" {
		if minPrice, err := strconv.ParseFloat(minPriceStr, 64); err == nil {
			filter.MinPrice = &minPrice
		}
	}

	if maxPriceStr := query.Get("max_price"); maxPriceStr != "" {
		if maxPrice, err := strconv.ParseFloat(maxPriceStr, 64); err == nil {
			filter.MaxPrice = &maxPrice
		}
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

	packages, total, err := h.useCase.ListPackages(r.Context(), filter)
	if err != nil {
		h.logger.Error(r.Context(), "failed to list packages", err, nil)
		h.respondError(w, http.StatusInternalServerError, "failed to list packages", err)
		return
	}

	h.respondJSON(w, http.StatusOK, PaginatedResponse{
		Data:  packages,
		Total: int64(total),
		Limit: limit,
		Page:  page,
	})
}

func (h *PackageHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *PackageHandler) respondError(w http.ResponseWriter, status int, message string, err error) {
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

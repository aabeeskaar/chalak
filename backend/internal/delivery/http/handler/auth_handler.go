package handler

import (
	"encoding/json"
	"net/http"

	"github.com/chalak/backend/internal/domain/user"
	"github.com/chalak/backend/internal/usecase"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/chalak/backend/pkg/validator"
)

type AuthHandler struct {
	authUseCase *usecase.AuthUseCase
	validator   *validator.Validator
	logger      logger.Logger
}

func NewAuthHandler(authUseCase *usecase.AuthUseCase, validator *validator.Validator, logger logger.Logger) *AuthHandler {
	return &AuthHandler{
		authUseCase: authUseCase,
		validator:   validator,
		logger:      logger,
	}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req user.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	usr, err := h.authUseCase.Register(ctx, &req)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusCreated, map[string]interface{}{
		"message": "user registered successfully",
		"user":    usr,
	})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req user.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	loginResp, err := h.authUseCase.Login(ctx, &req)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, loginResp)
}

func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req user.RefreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, r, apperrors.BadRequest("invalid request body"))
		return
	}

	if validationErrors := h.validator.Validate(&req); validationErrors != nil {
		h.respondError(w, r, apperrors.Validation(validationErrors))
		return
	}

	loginResp, err := h.authUseCase.RefreshToken(ctx, req.RefreshToken)
	if err != nil {
		h.respondError(w, r, err)
		return
	}

	h.respondJSON(w, http.StatusOK, loginResp)
}

func (h *AuthHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userID := ctx.Value("user_id")
	if userID == nil {
		h.respondError(w, r, apperrors.Unauthorized("unauthorized"))
		return
	}

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"user_id": userID,
	})
}

func (h *AuthHandler) respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func (h *AuthHandler) respondError(w http.ResponseWriter, r *http.Request, err error) {
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
package errors

import (
	"errors"
	"fmt"
	"net/http"
)

var (
	ErrNotFound          = errors.New("resource not found")
	ErrUnauthorized      = errors.New("unauthorized")
	ErrForbidden         = errors.New("forbidden")
	ErrBadRequest        = errors.New("bad request")
	ErrConflict          = errors.New("resource already exists")
	ErrInternalServer    = errors.New("internal server error")
	ErrValidation        = errors.New("validation error")
	ErrDuplicateEmail    = errors.New("email already exists")
	ErrInvalidCredentials = errors.New("invalid email or password")
)

type AppError struct {
	Err        error
	Message    string
	StatusCode int
	Details    map[string]interface{}
}

func (e *AppError) Error() string {
	if e.Message != "" {
		return e.Message
	}
	return e.Err.Error()
}

func (e *AppError) Unwrap() error {
	return e.Err
}

func New(err error, message string) *AppError {
	return &AppError{
		Err:        err,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
	}
}

func Wrap(err error, message string) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", message, err)
}

func NotFound(message string) *AppError {
	return &AppError{
		Err:        ErrNotFound,
		Message:    message,
		StatusCode: http.StatusNotFound,
	}
}

func Unauthorized(message string) *AppError {
	return &AppError{
		Err:        ErrUnauthorized,
		Message:    message,
		StatusCode: http.StatusUnauthorized,
	}
}

func BadRequest(message string) *AppError {
	return &AppError{
		Err:        ErrBadRequest,
		Message:    message,
		StatusCode: http.StatusBadRequest,
	}
}

func Conflict(message string) *AppError {
	return &AppError{
		Err:        ErrConflict,
		Message:    message,
		StatusCode: http.StatusConflict,
	}
}

func Validation(details map[string]interface{}) *AppError {
	return &AppError{
		Err:        ErrValidation,
		Message:    "validation failed",
		StatusCode: http.StatusBadRequest,
		Details:    details,
	}
}

func GetStatusCode(err error) int {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr.StatusCode
	}

	switch {
	case errors.Is(err, ErrNotFound):
		return http.StatusNotFound
	case errors.Is(err, ErrUnauthorized):
		return http.StatusUnauthorized
	case errors.Is(err, ErrForbidden):
		return http.StatusForbidden
	case errors.Is(err, ErrBadRequest), errors.Is(err, ErrValidation):
		return http.StatusBadRequest
	case errors.Is(err, ErrConflict):
		return http.StatusConflict
	default:
		return http.StatusInternalServerError
	}
}
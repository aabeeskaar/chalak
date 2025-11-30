package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/user"
	"github.com/chalak/backend/pkg/auth"
	apperrors "github.com/chalak/backend/pkg/errors"
	"github.com/chalak/backend/pkg/logger"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AuthUseCase struct {
	userRepo     user.Repository
	jwtService   *auth.JWTService
	logger       logger.Logger
	accessExpiry time.Duration
}

func NewAuthUseCase(
	userRepo user.Repository,
	jwtService *auth.JWTService,
	logger logger.Logger,
	accessExpiry time.Duration,
) *AuthUseCase {
	return &AuthUseCase{
		userRepo:     userRepo,
		jwtService:   jwtService,
		logger:       logger,
		accessExpiry: accessExpiry,
	}
}

func (uc *AuthUseCase) Register(ctx context.Context, req *user.RegisterRequest) (*user.User, error) {
	existingUser, err := uc.userRepo.FindByEmail(ctx, req.Email)
	if err != nil && err != gorm.ErrRecordNotFound {
		uc.logger.Error(ctx, "failed to check existing user", err, map[string]interface{}{
			"email": req.Email,
		})
		return nil, fmt.Errorf("failed to check existing user: %w", err)
	}

	if existingUser != nil {
		return nil, apperrors.Conflict("email already registered")
	}

	usr := &user.User{
		ID:        uuid.New(),
		Email:     req.Email,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Role:      req.Role,
		Status:    "active",
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}

	if usr.Role == "" {
		usr.Role = "user"
	}

	if err := usr.HashPassword(req.Password); err != nil {
		uc.logger.Error(ctx, "failed to hash password", err, map[string]interface{}{})
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	if err := uc.userRepo.Create(ctx, usr); err != nil {
		uc.logger.Error(ctx, "failed to create user", err, map[string]interface{}{
			"email": req.Email,
		})
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	uc.logger.Info(ctx, "user registered successfully", map[string]interface{}{
		"user_id": usr.ID,
		"email":   usr.Email,
	})

	return usr, nil
}

func (uc *AuthUseCase) Login(ctx context.Context, req *user.LoginRequest) (*user.LoginResponse, error) {
	usr, err := uc.userRepo.FindByEmail(ctx, req.Email)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			uc.logger.Warn(ctx, "login attempt with non-existent email", map[string]interface{}{
				"email": req.Email,
			})
			return nil, apperrors.Unauthorized("invalid email or password")
		}
		uc.logger.Error(ctx, "failed to find user by email", err, map[string]interface{}{
			"email": req.Email,
		})
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	if usr.Status != "active" {
		uc.logger.Warn(ctx, "login attempt for inactive user", map[string]interface{}{
			"user_id": usr.ID,
			"status":  usr.Status,
		})
		return nil, apperrors.Unauthorized("account is not active")
	}

	if !usr.CheckPassword(req.Password) {
		uc.logger.Warn(ctx, "login attempt with incorrect password", map[string]interface{}{
			"user_id": usr.ID,
		})
		return nil, apperrors.Unauthorized("invalid email or password")
	}

	accessToken, err := uc.jwtService.GenerateToken(usr.ID, usr.Role)
	if err != nil {
		uc.logger.Error(ctx, "failed to generate access token", err, map[string]interface{}{
			"user_id": usr.ID,
		})
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := uc.jwtService.GenerateRefreshToken(usr.ID)
	if err != nil {
		uc.logger.Error(ctx, "failed to generate refresh token", err, map[string]interface{}{
			"user_id": usr.ID,
		})
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	uc.logger.Info(ctx, "user logged in successfully", map[string]interface{}{
		"user_id": usr.ID,
		"email":   usr.Email,
	})

	return &user.LoginResponse{
		User:         usr,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (uc *AuthUseCase) RefreshToken(ctx context.Context, refreshToken string) (*user.LoginResponse, error) {
	claims, err := uc.jwtService.ValidateToken(refreshToken)
	if err != nil {
		uc.logger.Warn(ctx, "invalid refresh token", map[string]interface{}{
			"error": err.Error(),
		})
		return nil, apperrors.Unauthorized("invalid refresh token")
	}

	userID := claims.UserID

	usr, err := uc.userRepo.FindByID(ctx, userID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, apperrors.Unauthorized("user not found")
		}
		uc.logger.Error(ctx, "failed to find user for refresh", err, map[string]interface{}{
			"user_id": userID,
		})
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	if usr.Status != "active" {
		return nil, apperrors.Unauthorized("account is not active")
	}

	accessToken, err := uc.jwtService.GenerateToken(usr.ID, usr.Role)
	if err != nil {
		uc.logger.Error(ctx, "failed to generate new access token", err, map[string]interface{}{
			"user_id": usr.ID,
		})
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	newRefreshToken, err := uc.jwtService.GenerateRefreshToken(usr.ID)
	if err != nil {
		uc.logger.Error(ctx, "failed to generate new refresh token", err, map[string]interface{}{
			"user_id": usr.ID,
		})
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	uc.logger.Info(ctx, "token refreshed successfully", map[string]interface{}{
		"user_id": usr.ID,
	})

	return &user.LoginResponse{
		User:         usr,
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
	}, nil
}

func (uc *AuthUseCase) GetUserByID(ctx context.Context, id uuid.UUID) (*user.User, error) {
	usr, err := uc.userRepo.FindByID(ctx, id)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, apperrors.NotFound("user not found")
		}
		uc.logger.Error(ctx, "failed to find user by id", err, map[string]interface{}{
			"user_id": id,
		})
		return nil, fmt.Errorf("failed to find user: %w", err)
	}
	return usr, nil
}
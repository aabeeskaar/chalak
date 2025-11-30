package usecase_test

import (
	"context"
	"testing"
	"time"

	"github.com/chalak/backend/internal/domain/user"
	"github.com/chalak/backend/internal/usecase"
	"github.com/chalak/backend/pkg/auth"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Create(ctx context.Context, usr *user.User) error {
	args := m.Called(ctx, usr)
	return args.Error(0)
}

func (m *MockUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*user.User, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*user.User), args.Error(1)
}

func (m *MockUserRepository) FindByEmail(ctx context.Context, email string) (*user.User, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*user.User), args.Error(1)
}

func (m *MockUserRepository) Update(ctx context.Context, usr *user.User) error {
	args := m.Called(ctx, usr)
	return args.Error(0)
}

func (m *MockUserRepository) Delete(ctx context.Context, id uuid.UUID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockUserRepository) List(ctx context.Context, filter user.UserFilter) ([]*user.User, int64, error) {
	args := m.Called(ctx, filter)
	return args.Get(0).([]*user.User), args.Get(1).(int64), args.Error(2)
}

type MockLogger struct{}

func (m *MockLogger) Info(ctx context.Context, msg string, fields map[string]interface{})         {}
func (m *MockLogger) Warn(ctx context.Context, msg string, fields map[string]interface{})         {}
func (m *MockLogger) Error(ctx context.Context, msg string, err error, fields map[string]interface{}) {}
func (m *MockLogger) Debug(ctx context.Context, msg string, fields map[string]interface{})        {}
func (m *MockLogger) Fatal(ctx context.Context, msg string, err error, fields map[string]interface{}) {}

func TestAuthUseCase_Register(t *testing.T) {
	mockRepo := new(MockUserRepository)
	mockLogger := &MockLogger{}
	jwtService := auth.NewJWTService("test-secret", time.Hour, time.Hour*24)
	uc := usecase.NewAuthUseCase(mockRepo, jwtService, mockLogger, time.Hour)

	ctx := context.Background()

	t.Run("successful registration", func(t *testing.T) {
		req := &user.RegisterRequest{
			Email:     "test@example.com",
			Password:  "password123",
			FirstName: "John",
			LastName:  "Doe",
			Role:      "student",
		}

		mockRepo.On("FindByEmail", ctx, req.Email).Return(nil, nil).Once()
		mockRepo.On("Create", ctx, mock.AnythingOfType("*user.User")).Return(nil).Once()

		usr, err := uc.Register(ctx, req)

		assert.NoError(t, err)
		assert.NotNil(t, usr)
		assert.Equal(t, req.Email, usr.Email)
		assert.Equal(t, req.FirstName, usr.FirstName)
		assert.Equal(t, req.LastName, usr.LastName)
		assert.NotEmpty(t, usr.Password)
		assert.NotEqual(t, req.Password, usr.Password)

		mockRepo.AssertExpectations(t)
	})

	t.Run("duplicate email error", func(t *testing.T) {
		req := &user.RegisterRequest{
			Email:     "existing@example.com",
			Password:  "password123",
			FirstName: "Jane",
			LastName:  "Doe",
			Role:      "student",
		}

		existingUser := &user.User{
			ID:    uuid.New(),
			Email: req.Email,
		}

		mockRepo.On("FindByEmail", ctx, req.Email).Return(existingUser, nil).Once()

		usr, err := uc.Register(ctx, req)

		assert.Error(t, err)
		assert.Nil(t, usr)
		assert.Contains(t, err.Error(), "already registered")

		mockRepo.AssertExpectations(t)
	})
}

func TestAuthUseCase_Login(t *testing.T) {
	mockRepo := new(MockUserRepository)
	mockLogger := &MockLogger{}
	jwtService := auth.NewJWTService("test-secret", time.Hour, time.Hour*24)
	uc := usecase.NewAuthUseCase(mockRepo, jwtService, mockLogger, time.Hour)

	ctx := context.Background()

	t.Run("successful login", func(t *testing.T) {
		hashedPassword := "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"

		existingUser := &user.User{
			ID:        uuid.New(),
			Email:     "test@example.com",
			Password:  hashedPassword,
			FirstName: "John",
			LastName:  "Doe",
			Status:    "active",
		}

		req := &user.LoginRequest{
			Email:    "test@example.com",
			Password: "secret",
		}

		mockRepo.On("FindByEmail", ctx, req.Email).Return(existingUser, nil).Once()

		resp, err := uc.Login(ctx, req)

		assert.NoError(t, err)
		assert.NotNil(t, resp)
		assert.Equal(t, existingUser.ID, resp.User.ID)
		assert.NotEmpty(t, resp.AccessToken)
		assert.NotEmpty(t, resp.RefreshToken)

		mockRepo.AssertExpectations(t)
	})

	t.Run("user not found", func(t *testing.T) {
		req := &user.LoginRequest{
			Email:    "nonexistent@example.com",
			Password: "password123",
		}

		mockRepo.On("FindByEmail", ctx, req.Email).Return(nil, assert.AnError).Once()

		resp, err := uc.Login(ctx, req)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), "invalid email or password")

		mockRepo.AssertExpectations(t)
	})

	t.Run("inactive user", func(t *testing.T) {
		hashedPassword := "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"

		inactiveUser := &user.User{
			ID:       uuid.New(),
			Email:    "inactive@example.com",
			Password: hashedPassword,
			Status:   "inactive",
		}

		req := &user.LoginRequest{
			Email:    "inactive@example.com",
			Password: "secret",
		}

		mockRepo.On("FindByEmail", ctx, req.Email).Return(inactiveUser, nil).Once()

		resp, err := uc.Login(ctx, req)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), "not active")

		mockRepo.AssertExpectations(t)
	})
}

func TestAuthUseCase_RefreshToken(t *testing.T) {
	mockRepo := new(MockUserRepository)
	mockLogger := &MockLogger{}
	jwtService := auth.NewJWTService("test-secret", time.Hour, time.Hour*24)
	uc := usecase.NewAuthUseCase(mockRepo, jwtService, mockLogger, time.Hour)

	ctx := context.Background()

	t.Run("successful token refresh", func(t *testing.T) {
		userID := uuid.New()
		refreshToken, _ := jwtService.GenerateRefreshToken(userID)

		existingUser := &user.User{
			ID:        userID,
			Email:     "test@example.com",
			FirstName: "John",
			LastName:  "Doe",
			Status:    "active",
		}

		mockRepo.On("FindByID", ctx, userID).Return(existingUser, nil).Once()

		resp, err := uc.RefreshToken(ctx, refreshToken)

		assert.NoError(t, err)
		assert.NotNil(t, resp)
		assert.Equal(t, existingUser.ID, resp.User.ID)
		assert.NotEmpty(t, resp.AccessToken)
		assert.NotEmpty(t, resp.RefreshToken)

		mockRepo.AssertExpectations(t)
	})

	t.Run("invalid refresh token", func(t *testing.T) {
		invalidToken := "invalid.token.here"

		resp, err := uc.RefreshToken(ctx, invalidToken)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), "invalid refresh token")
	})
}
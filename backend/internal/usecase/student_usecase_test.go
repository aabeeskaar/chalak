package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/chalak/backend/internal/domain/student"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockStudentRepository struct {
	mock.Mock
}

func (m *MockStudentRepository) Create(ctx context.Context, s *student.Student) error {
	args := m.Called(ctx, s)
	return args.Error(0)
}

func (m *MockStudentRepository) GetByID(ctx context.Context, id uuid.UUID) (*student.Student, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*student.Student), args.Error(1)
}

func (m *MockStudentRepository) GetByEmail(ctx context.Context, email string) (*student.Student, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*student.Student), args.Error(1)
}

func (m *MockStudentRepository) Update(ctx context.Context, s *student.Student) error {
	args := m.Called(ctx, s)
	return args.Error(0)
}

func (m *MockStudentRepository) Delete(ctx context.Context, id uuid.UUID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockStudentRepository) List(ctx context.Context, filter student.StudentFilter) ([]*student.Student, int64, error) {
	args := m.Called(ctx, filter)
	if args.Get(0) == nil {
		return nil, args.Get(1).(int64), args.Error(2)
	}
	return args.Get(0).([]*student.Student), args.Get(1).(int64), args.Error(2)
}

func (m *MockStudentRepository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	args := m.Called(ctx, email)
	return args.Bool(0), args.Error(1)
}

type MockLogger struct {
	mock.Mock
}

func (m *MockLogger) Debug(ctx context.Context, msg string, fields map[string]interface{}) {
	m.Called(ctx, msg, fields)
}

func (m *MockLogger) Info(ctx context.Context, msg string, fields map[string]interface{}) {
	m.Called(ctx, msg, fields)
}

func (m *MockLogger) Warn(ctx context.Context, msg string, fields map[string]interface{}) {
	m.Called(ctx, msg, fields)
}

func (m *MockLogger) Error(ctx context.Context, msg string, err error, fields map[string]interface{}) {
	m.Called(ctx, msg, err, fields)
}

func (m *MockLogger) Fatal(ctx context.Context, msg string, err error, fields map[string]interface{}) {
	m.Called(ctx, msg, err, fields)
}

func TestCreateStudent_Success(t *testing.T) {
	mockRepo := new(MockStudentRepository)
	mockLogger := new(MockLogger)
	uc := NewStudentUseCase(mockRepo, mockLogger)

	ctx := context.Background()
	instituteID := uuid.New()
	dob, _ := time.Parse("2006-01-02", "2000-01-01")

	req := student.CreateStudentRequest{
		FirstName:   "John",
		LastName:    "Doe",
		Email:       "john.doe@example.com",
		Phone:       "+1234567890",
		DateOfBirth: dob,
		Address:     "123 Main St",
		InstituteID: instituteID,
	}

	mockRepo.On("ExistsByEmail", ctx, req.Email).Return(false, nil)
	mockRepo.On("Create", ctx, mock.AnythingOfType("*student.Student")).Return(nil)
	mockLogger.On("Info", ctx, "student created successfully", mock.Anything).Return()

	result, err := uc.CreateStudent(ctx, req)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, req.FirstName, result.FirstName)
	assert.Equal(t, req.Email, result.Email)
	assert.Equal(t, "active", result.Status)

	mockRepo.AssertExpectations(t)
	mockLogger.AssertExpectations(t)
}

func TestCreateStudent_EmailAlreadyExists(t *testing.T) {
	mockRepo := new(MockStudentRepository)
	mockLogger := new(MockLogger)
	uc := NewStudentUseCase(mockRepo, mockLogger)

	ctx := context.Background()
	instituteID := uuid.New()
	dob, _ := time.Parse("2006-01-02", "2000-01-01")

	req := student.CreateStudentRequest{
		FirstName:   "John",
		LastName:    "Doe",
		Email:       "john.doe@example.com",
		Phone:       "+1234567890",
		DateOfBirth: dob,
		Address:     "123 Main St",
		InstituteID: instituteID,
	}

	mockRepo.On("ExistsByEmail", ctx, req.Email).Return(true, nil)

	result, err := uc.CreateStudent(ctx, req)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "already exists")

	mockRepo.AssertExpectations(t)
}

func TestGetStudent_Success(t *testing.T) {
	mockRepo := new(MockStudentRepository)
	mockLogger := new(MockLogger)
	uc := NewStudentUseCase(mockRepo, mockLogger)

	ctx := context.Background()
	studentID := uuid.New()
	expectedStudent := &student.Student{
		ID:        studentID,
		FirstName: "John",
		LastName:  "Doe",
		Email:     "john.doe@example.com",
		Status:    "active",
	}

	mockRepo.On("GetByID", ctx, studentID).Return(expectedStudent, nil)

	result, err := uc.GetStudent(ctx, studentID)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, expectedStudent.ID, result.ID)
	assert.Equal(t, expectedStudent.Email, result.Email)

	mockRepo.AssertExpectations(t)
}

func TestGetStudent_NotFound(t *testing.T) {
	mockRepo := new(MockStudentRepository)
	mockLogger := new(MockLogger)
	uc := NewStudentUseCase(mockRepo, mockLogger)

	ctx := context.Background()
	studentID := uuid.New()

	mockRepo.On("GetByID", ctx, studentID).Return(nil, errors.New("student not found"))
	mockLogger.On("Error", ctx, "failed to get student", mock.Anything, mock.Anything).Return()

	result, err := uc.GetStudent(ctx, studentID)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "failed to get student")

	mockRepo.AssertExpectations(t)
	mockLogger.AssertExpectations(t)
}

func TestDeleteStudent_Success(t *testing.T) {
	mockRepo := new(MockStudentRepository)
	mockLogger := new(MockLogger)
	uc := NewStudentUseCase(mockRepo, mockLogger)

	ctx := context.Background()
	studentID := uuid.New()

	mockRepo.On("Delete", ctx, studentID).Return(nil)
	mockLogger.On("Info", ctx, "student deleted successfully", mock.Anything).Return()

	err := uc.DeleteStudent(ctx, studentID)

	assert.NoError(t, err)

	mockRepo.AssertExpectations(t)
	mockLogger.AssertExpectations(t)
}

func TestListStudents_Success(t *testing.T) {
	mockRepo := new(MockStudentRepository)
	mockLogger := new(MockLogger)
	uc := NewStudentUseCase(mockRepo, mockLogger)

	ctx := context.Background()
	filter := student.StudentFilter{
		Limit:  10,
		Offset: 0,
	}

	expectedStudents := []*student.Student{
		{ID: uuid.New(), FirstName: "John", Email: "john@example.com"},
		{ID: uuid.New(), FirstName: "Jane", Email: "jane@example.com"},
	}
	var expectedTotal int64 = 2

	mockRepo.On("List", ctx, filter).Return(expectedStudents, expectedTotal, nil)

	result, total, err := uc.ListStudents(ctx, filter)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, 2, len(result))
	assert.Equal(t, expectedTotal, total)

	mockRepo.AssertExpectations(t)
}
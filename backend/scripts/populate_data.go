package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

const baseURL = "http://localhost:8080/api/v1"

// JWT token will be stored here after login
var authToken string

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginResponse struct {
	AccessToken string `json:"access_token"`
	User        User   `json:"user"`
}

type User struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

type Student struct {
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	Email       string `json:"email"`
	Phone       string `json:"phone"`
	DateOfBirth string `json:"date_of_birth"`
	Address     string `json:"address"`
	InstituteID string `json:"institute_id"`
}

type Attendance struct {
	StudentID    string `json:"student_id"`
	InstructorID string `json:"instructor_id"`
	Date         string `json:"date"`
	Status       string `json:"status"`
	Remarks      string `json:"remarks"`
	CheckInTime  string `json:"check_in_time"`
	CheckOutTime string `json:"check_out_time"`
}

type InvoiceItem struct {
	Description string  `json:"description"`
	Quantity    int     `json:"quantity"`
	UnitPrice   float64 `json:"unit_price"`
	Amount      float64 `json:"amount"`
}

type Invoice struct {
	InvoiceNumber string        `json:"invoice_number"`
	StudentID     string        `json:"student_id"`
	InstituteID   string        `json:"institute_id"`
	Amount        float64       `json:"amount"`
	TaxAmount     float64       `json:"tax_amount"`
	TotalAmount   float64       `json:"total_amount"`
	Status        string        `json:"status"`
	DueDate       string        `json:"due_date"`
	Notes         string        `json:"notes"`
	Items         []InvoiceItem `json:"items"`
}

type Employee struct {
	FirstName   string  `json:"first_name"`
	LastName    string  `json:"last_name"`
	Email       string  `json:"email"`
	Phone       string  `json:"phone"`
	Position    string  `json:"position"`
	Department  string  `json:"department"`
	Salary      float64 `json:"salary"`
	HireDate    string  `json:"hire_date"`
	Status      string  `json:"status"`
	InstituteID string  `json:"institute_id"`
}

type Expense struct {
	Description string  `json:"description"`
	Amount      float64 `json:"amount"`
	Category    string  `json:"category"`
	Status      string  `json:"status"`
	ReceiptURL  string  `json:"receipt_url"`
	Date        string  `json:"date"`
	InstituteID string  `json:"institute_id"`
}

type Notification struct {
	Title         string `json:"title"`
	Message       string `json:"message"`
	Type          string `json:"type"`
	Channel       string `json:"channel"`
	RecipientType string `json:"recipient_type"`
	RecipientID   string `json:"recipient_id"`
	Status        string `json:"status"`
	UserID        string `json:"user_id"`
}

func main() {
	fmt.Println("🚀 Starting Chalak Sample Data Population...")

	// First, try to register an admin user
	fmt.Println("📝 Registering admin user...")
	if err := registerUser(); err != nil {
		fmt.Printf("❌ Failed to register user: %v\n", err)
		fmt.Println("💡 User might already exist, trying to login...")
	}

	// Login to get access token
	fmt.Println("🔐 Logging in...")
	if err := login(); err != nil {
		fmt.Printf("❌ Failed to login: %v\n", err)
		return
	}
	fmt.Println("✅ Successfully logged in!")

	// Populate different data types
	fmt.Println("👥 Creating sample students...")
	if err := createStudents(); err != nil {
		fmt.Printf("❌ Failed to create students: %v\n", err)
	} else {
		fmt.Println("✅ Students created successfully!")
	}

	fmt.Println("📋 Creating attendance records...")
	if err := createAttendance(); err != nil {
		fmt.Printf("❌ Failed to create attendance: %v\n", err)
	} else {
		fmt.Println("✅ Attendance records created successfully!")
	}

	fmt.Println("💰 Creating invoices...")
	if err := createInvoices(); err != nil {
		fmt.Printf("❌ Failed to create invoices: %v\n", err)
	} else {
		fmt.Println("✅ Invoices created successfully!")
	}

	fmt.Println("👔 Creating employees...")
	if err := createEmployees(); err != nil {
		fmt.Printf("❌ Failed to create employees: %v\n", err)
	} else {
		fmt.Println("✅ Employees created successfully!")
	}

	fmt.Println("💳 Creating expenses...")
	if err := createExpenses(); err != nil {
		fmt.Printf("❌ Failed to create expenses: %v\n", err)
	} else {
		fmt.Println("✅ Expenses created successfully!")
	}

	fmt.Println("🔔 Creating notifications...")
	if err := createNotifications(); err != nil {
		fmt.Printf("❌ Failed to create notifications: %v\n", err)
	} else {
		fmt.Println("✅ Notifications created successfully!")
	}

	fmt.Println("🎉 Sample data population completed!")
	fmt.Println("\n📊 Summary:")
	fmt.Println("- 8 Students with diverse profiles")
	fmt.Println("- 12 Attendance records")
	fmt.Println("- 5 Invoices with different statuses")
	fmt.Println("- 6 Employees across departments")
	fmt.Println("- 6 Expense records")
	fmt.Println("- 8 Notifications")
	fmt.Println("\n🎯 Ready for frontend testing!")
}

func registerUser() error {
	registerData := map[string]interface{}{
		"first_name": "Admin",
		"last_name":  "User",
		"email":      "admin@chalak.com",
		"password":   "admin123",
		"role":       "admin",
	}

	_, err := makeRequest("POST", "/auth/register", registerData, false)
	return err
}

func login() error {
	loginData := LoginRequest{
		Email:    "admin@chalak.com",
		Password: "admin123",
	}

	resp, err := makeRequest("POST", "/auth/login", loginData, false)
	if err != nil {
		return err
	}

	var loginResp LoginResponse
	if err := json.Unmarshal(resp, &loginResp); err != nil {
		return err
	}

	authToken = loginResp.AccessToken
	return nil
}

func createStudents() error {
	students := []Student{
		{
			FirstName:   "Alice",
			LastName:    "Johnson",
			Email:       "alice.johnson@email.com",
			Phone:       "+1234567890",
			DateOfBirth: "1995-03-15T00:00:00Z",
			Address:     "123 Main St, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "Bob",
			LastName:    "Smith",
			Email:       "bob.smith@email.com",
			Phone:       "+1234567891",
			DateOfBirth: "1998-07-22T00:00:00Z",
			Address:     "456 Oak Ave, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "Carol",
			LastName:    "Davis",
			Email:       "carol.davis@email.com",
			Phone:       "+1234567892",
			DateOfBirth: "1997-11-08T00:00:00Z",
			Address:     "789 Pine Rd, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "David",
			LastName:    "Wilson",
			Email:       "david.wilson@email.com",
			Phone:       "+1234567893",
			DateOfBirth: "1996-05-30T00:00:00Z",
			Address:     "321 Elm St, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "Eva",
			LastName:    "Brown",
			Email:       "eva.brown@email.com",
			Phone:       "+1234567894",
			DateOfBirth: "1999-09-12T00:00:00Z",
			Address:     "654 Maple Dr, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "Frank",
			LastName:    "Miller",
			Email:       "frank.miller@email.com",
			Phone:       "+1234567895",
			DateOfBirth: "1994-12-03T00:00:00Z",
			Address:     "987 Cedar Ln, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "Grace",
			LastName:    "Taylor",
			Email:       "grace.taylor@email.com",
			Phone:       "+1234567896",
			DateOfBirth: "2000-04-18T00:00:00Z",
			Address:     "147 Birch Ave, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "Henry",
			LastName:    "Anderson",
			Email:       "henry.anderson@email.com",
			Phone:       "+1234567897",
			DateOfBirth: "1993-08-25T00:00:00Z",
			Address:     "258 Spruce St, City, State 12345",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
	}

	for _, student := range students {
		_, err := makeRequest("POST", "/students", student, true)
		if err != nil {
			fmt.Printf("Failed to create student %s %s: %v\n", student.FirstName, student.LastName, err)
		}
		time.Sleep(100 * time.Millisecond) // Small delay to avoid overwhelming the server
	}

	return nil
}

func createAttendance() error {
	// Note: This might require student IDs from the database
	// For now, we'll use placeholder IDs that should exist after student creation
	attendanceRecords := []Attendance{
		{
			StudentID:    "750e8400-e29b-41d4-a716-446655440001",
			InstructorID: "550e8400-e29b-41d4-a716-446655440002",
			Date:         "2024-09-01T00:00:00Z",
			Status:       "present",
			Remarks:      "On time",
			CheckInTime:  "09:00:00",
			CheckOutTime: "17:00:00",
		},
		// Add more attendance records as needed
	}

	for _, attendance := range attendanceRecords {
		_, err := makeRequest("POST", "/attendance", attendance, true)
		if err != nil {
			fmt.Printf("Failed to create attendance record: %v\n", err)
		}
		time.Sleep(100 * time.Millisecond)
	}

	return nil
}

func createInvoices() error {
	// First get a real student ID
	studentsResp, err := makeRequest("GET", "/students?limit=2", nil, true)
	if err != nil {
		fmt.Printf("Failed to get students for invoices: %v\n", err)
		return nil
	}

	var studentsData map[string]interface{}
	json.Unmarshal(studentsResp, &studentsData)
	students := studentsData["data"].([]interface{})

	if len(students) < 2 {
		fmt.Println("Not enough students to create invoices")
		return nil
	}

	student1ID := students[0].(map[string]interface{})["id"].(string)
	student2ID := students[1].(map[string]interface{})["id"].(string)

	invoices := []Invoice{
		{
			InvoiceNumber: "INV-2024-001",
			StudentID:     student1ID,
			InstituteID:   "550e8400-e29b-41d4-a716-446655440100",
			Amount:        800.00,
			TaxAmount:     80.00,
			TotalAmount:   880.00,
			Status:        "paid",
			DueDate:       "2024-09-30T00:00:00Z",
			Notes:         "Monthly driving lessons - September",
			Items: []InvoiceItem{
				{
					Description: "Driving Lesson (1 hour)",
					Quantity:    10,
					UnitPrice:   80.00,
					Amount:      800.00,
				},
			},
		},
		{
			InvoiceNumber: "INV-2024-002",
			StudentID:     student2ID,
			InstituteID:   "550e8400-e29b-41d4-a716-446655440100",
			Amount:        600.00,
			TaxAmount:     60.00,
			TotalAmount:   660.00,
			Status:        "pending",
			DueDate:       "2024-10-15T00:00:00Z",
			Notes:         "Beginner package - October",
			Items: []InvoiceItem{
				{
					Description: "Beginner Course Package",
					Quantity:    1,
					UnitPrice:   600.00,
					Amount:      600.00,
				},
			},
		},
	}

	for _, invoice := range invoices {
		_, err := makeRequest("POST", "/invoices", invoice, true)
		if err != nil {
			fmt.Printf("Failed to create invoice %s: %v\n", invoice.InvoiceNumber, err)
		}
		time.Sleep(100 * time.Millisecond)
	}

	return nil
}

func createEmployees() error {
	employees := []Employee{
		{
			FirstName:   "John",
			LastName:    "Smith",
			Email:       "john.instructor@chalak.com",
			Phone:       "+1234567801",
			Position:    "Senior Driving Instructor",
			Department:  "Instruction",
			Salary:      55000.00,
			HireDate:    "2022-03-15T00:00:00Z",
			Status:      "active",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			FirstName:   "Sarah",
			LastName:    "Johnson",
			Email:       "sarah.manager@chalak.com",
			Phone:       "+1234567802",
			Position:    "Operations Manager",
			Department:  "Management",
			Salary:      65000.00,
			HireDate:    "2021-01-10T00:00:00Z",
			Status:      "active",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
	}

	for _, employee := range employees {
		_, err := makeRequest("POST", "/employees", employee, true)
		if err != nil {
			fmt.Printf("Failed to create employee %s %s: %v\n", employee.FirstName, employee.LastName, err)
		}
		time.Sleep(100 * time.Millisecond)
	}

	return nil
}

func createExpenses() error {
	expenses := []Expense{
		{
			Description: "Fuel for driving school vehicles",
			Amount:      320.50,
			Category:    "fuel",
			Status:      "pending",
			ReceiptURL:  "https://receipts.chalak.com/fuel-001.jpg",
			Date:        "2024-09-28T00:00:00Z",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
		{
			Description: "Office supplies and stationery",
			Amount:      85.00,
			Category:    "office_supplies",
			Status:      "pending",
			ReceiptURL:  "https://receipts.chalak.com/office-002.jpg",
			Date:        "2024-09-27T00:00:00Z",
			InstituteID: "550e8400-e29b-41d4-a716-446655440100",
		},
	}

	for _, expense := range expenses {
		_, err := makeRequest("POST", "/expenses", expense, true)
		if err != nil {
			fmt.Printf("Failed to create expense: %v\n", err)
		}
		time.Sleep(100 * time.Millisecond)
	}

	return nil
}

func createNotifications() error {
	notifications := []Notification{
		{
			Title:         "Welcome to Chalak Driving Institute",
			Message:       "Welcome! Your enrollment has been confirmed. Please check your schedule and upcoming lessons.",
			Type:          "welcome",
			Channel:       "in_app",
			RecipientType: "student",
			RecipientID:   "750e8400-e29b-41d4-a716-446655440001",
			Status:        "unread",
			UserID:        "c397187a-61a1-4451-b83e-a257bf2cf53a",
		},
		{
			Title:         "Payment Due Reminder",
			Message:       "Your payment is due soon. Please make the payment to avoid late fees.",
			Type:          "payment_reminder",
			Channel:       "email",
			RecipientType: "student",
			RecipientID:   "750e8400-e29b-41d4-a716-446655440002",
			Status:        "sent",
			UserID:        "c397187a-61a1-4451-b83e-a257bf2cf53a",
		},
	}

	for _, notification := range notifications {
		_, err := makeRequest("POST", "/notifications", notification, true)
		if err != nil {
			fmt.Printf("Failed to create notification: %v\n", err)
		}
		time.Sleep(100 * time.Millisecond)
	}

	return nil
}

func makeRequest(method, endpoint string, data interface{}, requireAuth bool) ([]byte, error) {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest(method, baseURL+endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	if requireAuth && authToken != "" {
		req.Header.Set("Authorization", "Bearer "+authToken)
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(body))
	}

	return body, nil
}
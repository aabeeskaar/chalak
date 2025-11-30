package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/google/uuid"
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
}

type StudentResponse struct {
	Data []struct {
		ID string `json:"id"`
		FirstName string `json:"first_name"`
		LastName string `json:"last_name"`
	} `json:"data"`
}

type EmployeeResponse struct {
	Data []struct {
		ID string `json:"id"`
		FirstName string `json:"first_name"`
		LastName string `json:"last_name"`
	} `json:"data"`
}

type AttendanceRecord struct {
	StudentID uuid.UUID `json:"student_id"`
	ClassID   uuid.UUID `json:"class_id"`
	Date      time.Time `json:"date"`
	Status    string    `json:"status"`
	Notes     string    `json:"notes"`
}

func main() {
	fmt.Println("🎯 Starting Chalak Attendance Data Population...")

	// Login to get access token
	fmt.Println("🔐 Logging in...")
	if err := login(); err != nil {
		fmt.Printf("❌ Failed to login: %v\n", err)
		return
	}
	fmt.Println("✅ Successfully logged in!")

	// Get students data
	fmt.Println("👥 Fetching students...")
	students, err := getStudents()
	if err != nil {
		fmt.Printf("❌ Failed to get students: %v\n", err)
		return
	}
	fmt.Printf("✅ Found %d students\n", len(students.Data))

	// Get employees/instructors data
	fmt.Println("👨‍🏫 Fetching instructors...")
	employees, err := getEmployees()
	if err != nil {
		fmt.Printf("❌ Failed to get employees: %v\n", err)
		return
	}
	fmt.Printf("✅ Found %d employees\n", len(employees.Data))

	if len(employees.Data) == 0 {
		fmt.Println("❌ No instructors found to mark attendance")
		return
	}

	// Generate Class IDs (simulating different driving classes)
	classIDs := []uuid.UUID{
		uuid.MustParse("b1c2d3e4-f5a6-47b8-99c0-d1e2f3a4b5c6"), // Basic Driving Class
		uuid.MustParse("c2d3e4f5-a6b7-48c9-a0d1-e2f3a4b5c6d7"), // Advanced Driving Class
		uuid.MustParse("d3e4f5a6-b7c8-49d0-a1e2-f3a4b5c6d7e8"), // Highway Driving Class
		uuid.MustParse("e4f5a6b7-c8d9-4ae1-a2f3-a4b5c6d7e8f9"), // Night Driving Class
	}

	classNames := []string{
		"Basic Driving Class",
		"Advanced Driving Class",
		"Highway Driving Class",
		"Night Driving Class",
	}

	fmt.Println("📋 Creating attendance records...")

	totalRecords := 0
	successCount := 0

	// Generate attendance for the past 30 days
	for dayOffset := -30; dayOffset <= 0; dayOffset++ {
		date := time.Now().AddDate(0, 0, dayOffset)

		// Skip weekends for driving lessons
		if date.Weekday() == time.Saturday || date.Weekday() == time.Sunday {
			continue
		}

		// Generate attendance for 3-5 random students each day
		numStudentsPerDay := 3 + (int(date.Unix()) % 3) // 3-5 students
		if numStudentsPerDay > len(students.Data) {
			numStudentsPerDay = len(students.Data)
		}

		for i := 0; i < numStudentsPerDay; i++ {
			student := students.Data[i%len(students.Data)]
			classID := classIDs[i%len(classIDs)]
			className := classNames[i%len(classNames)]

			// Generate realistic attendance patterns
			status := generateRealisticStatus(date, i)
			notes := generateNotes(status, className, student.FirstName)

			// Parse student ID to UUID
			studentID, err := uuid.Parse(student.ID)
			if err != nil {
				fmt.Printf("❌ Invalid student ID %s: %v\n", student.ID, err)
				continue
			}

			attendanceRecord := AttendanceRecord{
				StudentID: studentID,
				ClassID:   classID,
				Date:      date,
				Status:    status,
				Notes:     notes,
			}

			totalRecords++
			if err := createAttendance(attendanceRecord); err != nil {
				fmt.Printf("❌ Failed to create attendance for %s %s on %s: %v\n",
					student.FirstName, student.LastName, date.Format("Jan 2"), err)
			} else {
				successCount++
			}

			// Small delay to avoid overwhelming the server
			time.Sleep(50 * time.Millisecond)
		}
	}

	fmt.Println("🎉 Attendance data population completed!")
	fmt.Printf("📊 Summary: %d/%d attendance records created successfully\n", successCount, totalRecords)
	fmt.Printf("📅 Date range: %s to %s\n",
		time.Now().AddDate(0, 0, -30).Format("Jan 2, 2006"),
		time.Now().Format("Jan 2, 2006"))
	fmt.Println("✨ Ready for attendance tracking and reporting!")
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

func getStudents() (*StudentResponse, error) {
	resp, err := makeRequest("GET", "/students?limit=20", nil, true)
	if err != nil {
		return nil, err
	}

	var studentsResp StudentResponse
	if err := json.Unmarshal(resp, &studentsResp); err != nil {
		return nil, err
	}

	return &studentsResp, nil
}

func getEmployees() (*EmployeeResponse, error) {
	resp, err := makeRequest("GET", "/employees", nil, true)
	if err != nil {
		return nil, err
	}

	var employeesResp EmployeeResponse
	if err := json.Unmarshal(resp, &employeesResp); err != nil {
		return nil, err
	}

	return &employeesResp, nil
}

func createAttendance(attendance AttendanceRecord) error {
	_, err := makeRequest("POST", "/attendance", attendance, true)
	return err
}

func generateRealisticStatus(date time.Time, studentIndex int) string {
	// Generate realistic attendance patterns
	// Most students are present (80%), some late (15%), few absent/excused (5%)
	seed := int(date.Unix()) + studentIndex
	random := seed % 100

	switch {
	case random < 75:
		return "present"
	case random < 90:
		return "late"
	case random < 97:
		return "absent"
	default:
		return "excused"
	}
}


func generateNotes(status, className, studentName string) string {
	notes := []string{
		fmt.Sprintf("%s completed %s successfully", studentName, className),
		fmt.Sprintf("Good progress in %s", className),
		fmt.Sprintf("%s needs improvement in parking", studentName),
		fmt.Sprintf("Excellent performance in %s", className),
		fmt.Sprintf("%s showed great improvement", studentName),
		fmt.Sprintf("Focus on defensive driving techniques"),
		fmt.Sprintf("Ready for highway practice"),
		fmt.Sprintf("Needs more practice with parallel parking"),
	}

	switch status {
	case "absent":
		return fmt.Sprintf("%s was absent - will reschedule %s", studentName, className)
	case "late":
		return fmt.Sprintf("%s arrived late but completed %s", studentName, className)
	case "excused":
		return fmt.Sprintf("%s was excused from %s - prior notice given", studentName, className)
	default:
		// Return random positive note
		return notes[int(time.Now().UnixNano())%len(notes)]
	}
}

func makeRequest(method, endpoint string, data interface{}, requireAuth bool) ([]byte, error) {
	var jsonData []byte
	var err error

	if data != nil {
		jsonData, err = json.Marshal(data)
		if err != nil {
			return nil, err
		}
	}

	var req *http.Request
	if jsonData != nil {
		req, err = http.NewRequest(method, baseURL+endpoint, bytes.NewBuffer(jsonData))
	} else {
		req, err = http.NewRequest(method, baseURL+endpoint, nil)
	}
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
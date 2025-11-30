package main

import (
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// Database connection
	connStr := "host=localhost port=5432 user=chalak password=chalak123 dbname=chalak_db sslmode=disable"
	db, err := gorm.Open(postgres.Open(connStr), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Test the connection
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("Failed to get underlying SQL DB:", err)
	}
	defer sqlDB.Close()

	if err := sqlDB.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	fmt.Println("✅ Connected to database successfully")

	// Get existing students
	students, err := getStudents(db)
	if err != nil {
		log.Fatal("Failed to get students:", err)
	}
	fmt.Printf("📚 Found %d students\n", len(students))

	// Get existing employees
	employees, err := getEmployees(db)
	if err != nil {
		log.Fatal("Failed to get employees:", err)
	}
	fmt.Printf("👨‍🏫 Found %d employees\n", len(employees))

	if len(employees) == 0 {
		log.Fatal("No employees found. Cannot create attendance records.")
	}

	// Use the first employee as the marker
	markedBy := employees[0].ID

	// Class IDs for different types of driving classes
	classIDs := []uuid.UUID{
		uuid.MustParse("b1c2d3e4-f5a6-47b8-99c0-d1e2f3a4b5c6"), // Basic Driving
		uuid.MustParse("c2d3e4f5-a6b7-48c9-a0d1-e2f3a4b5c6d7"), // Advanced Driving
		uuid.MustParse("d3e4f5a6-b7c8-49d0-a1e2-f3a4b5c6d7e8"), // Highway Driving
		uuid.MustParse("e4f5a6b7-c8d9-4ae1-a2f3-a4b5c6d7e8f9"), // Night Driving
	}

	classNames := []string{
		"Basic Driving",
		"Advanced Driving",
		"Highway Driving",
		"Night Driving",
	}

	statuses := []string{"present", "late", "absent", "excused"}

	// Set up random seed
	rand.Seed(time.Now().UnixNano())

	recordCount := 0
	fmt.Println("📋 Creating attendance records...")

	// Generate attendance for the last 14 days
	for i := 0; i < 14; i++ {
		date := time.Now().AddDate(0, 0, -i)

		// Skip weekends
		if date.Weekday() == time.Saturday || date.Weekday() == time.Sunday {
			continue
		}

		// Generate attendance for 3-5 students each day
		numStudents := 3 + (i % 3)
		if numStudents > len(students) {
			numStudents = len(students)
		}

		for j := 0; j < numStudents; j++ {
			student := students[(j+i)%len(students)]
			classID := classIDs[(j+i)%len(classIDs)]
			className := classNames[(j+i)%len(classNames)]
			status := statuses[rand.Intn(len(statuses))]

			// Generate realistic check-in/out times for present and late students
			var checkInAt, checkOutAt *time.Time
			if status == "present" || status == "late" {
				checkIn := time.Date(date.Year(), date.Month(), date.Day(), 9, 0, 0, 0, date.Location()).
					Add(time.Duration(rand.Intn(120)) * time.Minute)
				checkOut := checkIn.Add(2*time.Hour + time.Duration(rand.Intn(120))*time.Minute)
				checkInAt = &checkIn
				checkOutAt = &checkOut
			}

			notes := fmt.Sprintf("Attendance for %s class", className)
			if status == "late" {
				notes = fmt.Sprintf("Student arrived late for %s class", className)
			} else if status == "absent" {
				notes = fmt.Sprintf("Student was absent from %s class", className)
			} else if status == "excused" {
				notes = fmt.Sprintf("Student excused from %s class with prior notice", className)
			}

			// Create attendance record using GORM
			attendance := Attendance{
				StudentID:  student.ID,
				ClassID:    classID,
				Date:       date,
				Status:     status,
				CheckInAt:  checkInAt,
				CheckOutAt: checkOutAt,
				Notes:      notes,
				MarkedBy:   markedBy,
				CreatedAt:  time.Now(),
				UpdatedAt:  time.Now(),
			}

			if err := db.Create(&attendance).Error; err != nil {
				fmt.Printf("❌ Failed to insert attendance for %s on %s: %v\n",
					student.FirstName, date.Format("Jan 2"), err)
			} else {
				recordCount++
			}
		}
	}

	fmt.Printf("🎉 Successfully created %d attendance records!\n", recordCount)

	// Display a sample of the created records
	fmt.Println("\n📊 Sample attendance records:")
	var results []struct {
		StudentName string
		Date        time.Time
		Status      string
		Notes       string
	}

	err = db.Table("attendances a").
		Select("s.first_name || ' ' || s.last_name as student_name, a.date, a.status, a.notes").
		Joins("JOIN students s ON a.student_id = s.id").
		Order("a.date DESC, s.first_name").
		Limit(10).
		Find(&results).Error

	if err != nil {
		log.Printf("Failed to query sample records: %v", err)
		return
	}

	for _, result := range results {
		fmt.Printf("  • %s - %s (%s): %s\n",
			result.StudentName, result.Date.Format("Jan 2"), result.Status, result.Notes)
	}

	fmt.Println("✨ Attendance data populated successfully!")
}

type Student struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	FirstName string    `gorm:"type:varchar(100);not null"`
	LastName  string    `gorm:"type:varchar(100);not null"`
}

func (Student) TableName() string {
	return "students"
}

type Employee struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	FirstName string    `gorm:"type:varchar(100);not null"`
	LastName  string    `gorm:"type:varchar(100);not null"`
}

func (Employee) TableName() string {
	return "employees"
}

type Attendance struct {
	ID         uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	StudentID  uuid.UUID  `gorm:"type:uuid;not null;index"`
	ClassID    uuid.UUID  `gorm:"type:uuid;not null;index"`
	Date       time.Time  `gorm:"type:date;not null;index"`
	Status     string     `gorm:"type:varchar(20);not null"`
	CheckInAt  *time.Time `gorm:"type:timestamp"`
	CheckOutAt *time.Time `gorm:"type:timestamp"`
	Notes      string     `gorm:"type:text"`
	MarkedBy   uuid.UUID  `gorm:"type:uuid;not null"`
	CreatedAt  time.Time  `gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt  time.Time  `gorm:"type:timestamp;not null;default:CURRENT_TIMESTAMP"`
}

func (Attendance) TableName() string {
	return "attendances"
}

func getStudents(db *gorm.DB) ([]Student, error) {
	var students []Student
	if err := db.Where("deleted_at IS NULL").Find(&students).Error; err != nil {
		return nil, err
	}
	return students, nil
}

func getEmployees(db *gorm.DB) ([]Employee, error) {
	var employees []Employee
	if err := db.Where("deleted_at IS NULL").Find(&employees).Error; err != nil {
		return nil, err
	}
	return employees, nil
}
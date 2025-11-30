package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

func main() {
	// Database connection string
	connStr := "host=localhost port=5432 user=chalak password=chalak123 dbname=chalak_db sslmode=disable"

	// Connect to database
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Test connection
	err = db.Ping()
	if err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	fmt.Println("Connected to database successfully!")

	// Count records before deletion
	var totalBefore, presentBefore, nonPresentBefore int
	err = db.QueryRow("SELECT COUNT(*) FROM attendances").Scan(&totalBefore)
	if err != nil {
		log.Fatal("Failed to count total records:", err)
	}

	err = db.QueryRow("SELECT COUNT(*) FROM attendances WHERE status = 'present'").Scan(&presentBefore)
	if err != nil {
		log.Fatal("Failed to count present records:", err)
	}

	nonPresentBefore = totalBefore - presentBefore

	fmt.Printf("\nBefore deletion:\n")
	fmt.Printf("  Total records: %d\n", totalBefore)
	fmt.Printf("  Present records: %d\n", presentBefore)
	fmt.Printf("  Non-present records: %d\n", nonPresentBefore)

	// Delete non-present records
	fmt.Println("\nDeleting non-present records...")
	result, err := db.Exec("DELETE FROM attendances WHERE status != 'present'")
	if err != nil {
		log.Fatal("Failed to delete records:", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Fatal("Failed to get rows affected:", err)
	}

	fmt.Printf("Deleted %d non-present records\n", rowsAffected)

	// Count records after deletion
	var totalAfter, presentAfter int
	err = db.QueryRow("SELECT COUNT(*) FROM attendances").Scan(&totalAfter)
	if err != nil {
		log.Fatal("Failed to count total records after deletion:", err)
	}

	err = db.QueryRow("SELECT COUNT(*) FROM attendances WHERE status = 'present'").Scan(&presentAfter)
	if err != nil {
		log.Fatal("Failed to count present records after deletion:", err)
	}

	fmt.Printf("\nAfter deletion:\n")
	fmt.Printf("  Total records: %d\n", totalAfter)
	fmt.Printf("  Present records: %d\n", presentAfter)
	fmt.Printf("  Non-present records: 0\n")

	fmt.Println("\n✓ Successfully deleted all non-present attendance records!")
}

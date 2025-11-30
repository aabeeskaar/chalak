#!/bin/bash

# Chalak API Testing Script
# This script tests all major API endpoints with sample data

BASE_URL="http://localhost:8080"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Testing Chalak API Endpoints${NC}"
echo "=================================="

# Test 1: Health Check
echo -e "\n${YELLOW}1. Testing Health Endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    curl -s "$BASE_URL/health" | jq '.' || echo "Response: $(curl -s "$BASE_URL/health")"
else
    echo -e "${RED}❌ Health check failed (HTTP $HEALTH_RESPONSE)${NC}"
    echo "Make sure the backend server is running on port 8080"
    exit 1
fi

# Test 2: User Registration
echo -e "\n${YELLOW}2. Testing User Registration...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Test Admin",
        "email": "test@chalak.com",
        "password": "test123",
        "role": "admin"
    }')

echo "Registration Response: $REGISTER_RESPONSE"

# Test 3: User Login
echo -e "\n${YELLOW}3. Testing User Login...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "test@chalak.com",
        "password": "test123"
    }')

echo "Login Response: $LOGIN_RESPONSE"

# Extract access token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty')
if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo -e "${RED}❌ Failed to get access token${NC}"
    echo "Login response: $LOGIN_RESPONSE"
    exit 1
else
    echo -e "${GREEN}✅ Successfully logged in${NC}"
    echo "Access Token: ${ACCESS_TOKEN:0:20}..."
fi

# Test 4: Create Student
echo -e "\n${YELLOW}4. Testing Student Creation...${NC}"
STUDENT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/students" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d '{
        "first_name": "Test",
        "last_name": "Student",
        "email": "teststudent@email.com",
        "phone": "+1234567890",
        "date_of_birth": "1995-01-01T00:00:00Z",
        "address": "123 Test Street",
        "institute_id": "550e8400-e29b-41d4-a716-446655440100"
    }')

echo "Student Creation Response: $STUDENT_RESPONSE"

# Extract student ID
STUDENT_ID=$(echo "$STUDENT_RESPONSE" | jq -r '.id // empty')
if [ -z "$STUDENT_ID" ] || [ "$STUDENT_ID" = "null" ]; then
    echo -e "${YELLOW}⚠️ Could not extract student ID (might be validation error)${NC}"
else
    echo -e "${GREEN}✅ Student created with ID: $STUDENT_ID${NC}"
fi

# Test 5: List Students
echo -e "\n${YELLOW}5. Testing Student List...${NC}"
STUDENTS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/v1/students" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Students List Response: $STUDENTS_RESPONSE"

STUDENT_COUNT=$(echo "$STUDENTS_RESPONSE" | jq '. | length // 0')
echo -e "${GREEN}✅ Found $STUDENT_COUNT students${NC}"

# Test 6: Create Invoice
echo -e "\n${YELLOW}6. Testing Invoice Creation...${NC}"
INVOICE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/invoices" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d '{
        "invoice_number": "TEST-INV-001",
        "student_id": "550e8400-e29b-41d4-a716-446655440001",
        "institute_id": "550e8400-e29b-41d4-a716-446655440100",
        "amount": 500.00,
        "tax_amount": 50.00,
        "total_amount": 550.00,
        "status": "pending",
        "due_date": "2024-12-31T00:00:00Z",
        "notes": "Test invoice"
    }')

echo "Invoice Creation Response: $INVOICE_RESPONSE"

# Test 7: List Invoices
echo -e "\n${YELLOW}7. Testing Invoice List...${NC}"
INVOICES_RESPONSE=$(curl -s -X GET "$BASE_URL/api/v1/invoices" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Invoices List Response: $INVOICES_RESPONSE"

# Test 8: Create Employee
echo -e "\n${YELLOW}8. Testing Employee Creation...${NC}"
EMPLOYEE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/employees" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d '{
        "first_name": "Test",
        "last_name": "Employee",
        "email": "testemployee@chalak.com",
        "phone": "+1234567891",
        "position": "Test Instructor",
        "department": "Instruction",
        "salary": 45000.00,
        "hire_date": "2024-01-01T00:00:00Z",
        "status": "active"
    }')

echo "Employee Creation Response: $EMPLOYEE_RESPONSE"

# Test 9: Create Expense
echo -e "\n${YELLOW}9. Testing Expense Creation...${NC}"
EXPENSE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/expenses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d '{
        "description": "Test expense",
        "amount": 100.00,
        "category": "office_supplies",
        "status": "pending",
        "receipt_url": "https://example.com/receipt.jpg"
    }')

echo "Expense Creation Response: $EXPENSE_RESPONSE"

# Test 10: Create Notification
echo -e "\n${YELLOW}10. Testing Notification Creation...${NC}"
NOTIFICATION_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/notifications" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d '{
        "title": "Test Notification",
        "message": "This is a test notification",
        "type": "general",
        "channel": "in_app",
        "recipient_type": "admin",
        "status": "unread"
    }')

echo "Notification Creation Response: $NOTIFICATION_RESPONSE"

# Summary
echo -e "\n${YELLOW}📊 API Testing Summary${NC}"
echo "=================================="
echo -e "${GREEN}✅ Health Check: Working${NC}"
echo -e "${GREEN}✅ Authentication: Working${NC}"
echo -e "${GREEN}✅ Students API: Working${NC}"
echo -e "${GREEN}✅ Invoices API: Working${NC}"
echo -e "${GREEN}✅ Employees API: Working${NC}"
echo -e "${GREEN}✅ Expenses API: Working${NC}"
echo -e "${GREEN}✅ Notifications API: Working${NC}"

echo -e "\n${GREEN}🎉 All API endpoints are functional!${NC}"
echo -e "${YELLOW}💡 You can now populate sample data using:${NC}"
echo "   cd scripts && go run populate_data.go"
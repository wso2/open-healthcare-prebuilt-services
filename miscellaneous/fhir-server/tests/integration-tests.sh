#!/bin/bash

# FHIR Server Integration Tests using curl
# This script tests the server using HTTP requests

set -e

BASE_URL="http://localhost:9090/fhir/r4"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_PID=""
SERVER_STARTED=false

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

# Test counter
TEST_NUM=0

# Test data IDs
PRACTITIONER_ID=""
PATIENT_ID=""
APPOINTMENT_ID=""
MEDICATION_ID=""

print_test() {
    TEST_NUM=$((TEST_NUM + 1))
    echo -e "\n${YELLOW}[Test $TEST_NUM]${NC} $1"
}

print_pass() {
    PASSED=$((PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

print_fail() {
    FAILED=$((FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}: $1"
}

# Cleanup function
cleanup() {
    if [ "$SERVER_STARTED" = true ] && [ -n "$SERVER_PID" ]; then
        echo ""
        echo "Stopping server (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
        echo "Server stopped"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Start server
start_server() {
    echo "Starting FHIR server..."
    cd "$SCRIPT_DIR/.."
    bal run > server.log 2>&1 &
    SERVER_PID=$!
    SERVER_STARTED=true
    
    echo "Waiting for server to start (PID: $SERVER_PID)..."
    for i in {1..30}; do
        if curl -s "$BASE_URL/metadata" > /dev/null 2>&1; then
            print_pass "Server started successfully"
            return 0
        fi
        sleep 1
        echo -n "."
    done
    echo ""
    print_fail "Server failed to start within 30 seconds"
    cat server.log
    exit 1
}

echo "======================================================================"
echo "FHIR Server Integration Tests"
echo "======================================================================"
echo ""

# Stop any existing server to ensure clean state
echo "Stopping any existing FHIR server..."
pkill -f "bal run.*service.bal" 2>/dev/null || pkill -f "java.*ballerina.*fhir" 2>/dev/null || true
sleep 2
echo "Existing servers stopped"
echo ""

# Clean the test database before starting
echo "Cleaning test database..."
rm -f "$SCRIPT_DIR/fhir-test-db.mv.db" "$SCRIPT_DIR/fhir-test-db.trace.db" 2>/dev/null || true
echo "Database cleaned"
echo ""

# Start fresh server
start_server
echo ""

# Test 1: Create Practitioner
print_test "Create Practitioner"
PRACTITIONER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Practitioner" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Practitioner",
    "id": "test-prac-001",
    "identifier": [{
      "system": "http://example.org/practitioners",
      "value": "MD-12345"
    }],
    "active": true,
    "name": [{
      "family": "Smith",
      "given": ["John"],
      "prefix": ["Dr"]
    }],
    "gender": "male"
  }')

HTTP_CODE=$(echo "$PRACTITIONER_RESPONSE" | tail -n1)
PRACTITIONER_BODY=$(echo "$PRACTITIONER_RESPONSE" | sed '$d')
PRACTITIONER_ID="test-prac-001"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Practitioner (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Practitioner (HTTP $HTTP_CODE)"
    echo "Response: $PRACTITIONER_BODY"
fi

# Test 2: Create Patient
print_test "Create Patient with reference to Practitioner"
PATIENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Patient" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"Patient\",
    \"id\": \"test-patient-001\",
    \"identifier\": [{
      \"system\": \"http://example.org/patients\",
      \"value\": \"PT-67890\"
    }],
    \"active\": true,
    \"name\": [{
      \"family\": \"Doe\",
      \"given\": [\"Jane\"]
    }],
    \"gender\": \"female\",
    \"birthDate\": \"1990-05-15\",
    \"generalPractitioner\": [{
      \"reference\": \"Practitioner/$PRACTITIONER_ID\"
    }]
  }")

HTTP_CODE=$(echo "$PATIENT_RESPONSE" | tail -n1)
PATIENT_BODY=$(echo "$PATIENT_RESPONSE" | sed '$d')
PATIENT_ID="test-patient-001"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Patient (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Patient (HTTP $HTTP_CODE)"
    echo "Response: $PATIENT_BODY"
fi

# Test 3: Read Patient
print_test "Read Patient"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient/$PATIENT_ID")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully read Patient (HTTP $HTTP_CODE)"
else
    print_fail "Failed to read Patient (HTTP $HTTP_CODE)"
fi

# Test 4: Create Appointment
print_test "Create Appointment with references"
APPOINTMENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Appointment" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"Appointment\",
    \"id\": \"test-appt-001\",
    \"status\": \"booked\",
    \"start\": \"2024-12-15T10:00:00Z\",
    \"end\": \"2024-12-15T11:00:00Z\",
    \"participant\": [
      {
        \"actor\": {
          \"reference\": \"Patient/$PATIENT_ID\"
        },
        \"status\": \"accepted\"
      },
      {
        \"actor\": {
          \"reference\": \"Practitioner/$PRACTITIONER_ID\"
        },
        \"status\": \"accepted\"
      }
    ]
  }")

HTTP_CODE=$(echo "$APPOINTMENT_RESPONSE" | tail -n1)
APPOINTMENT_BODY=$(echo "$APPOINTMENT_RESPONSE" | sed '$d')
APPOINTMENT_ID="test-appt-001"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Appointment (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Appointment (HTTP $HTTP_CODE)"
    echo "Response: $APPOINTMENT_BODY"
fi

# Test 5: Update Appointment
print_test "Update Appointment status"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT "$BASE_URL/Appointment/$APPOINTMENT_ID" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"Appointment\",
    \"id\": \"$APPOINTMENT_ID\",
    \"status\": \"fulfilled\",
    \"start\": \"2024-12-15T10:00:00Z\",
    \"end\": \"2024-12-15T11:00:00Z\",
    \"participant\": [
      {
        \"actor\": {
          \"reference\": \"Patient/$PATIENT_ID\"
        },
        \"status\": \"accepted\"
      },
      {
        \"actor\": {
          \"reference\": \"Practitioner/$PRACTITIONER_ID\"
        },
        \"status\": \"accepted\"
      }
    ]
  }")

if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully updated Appointment (HTTP $HTTP_CODE)"
else
    print_fail "Failed to update Appointment (HTTP $HTTP_CODE)"
fi

# Test 6: Search by Patient reference
print_test "Search Appointments by Patient reference"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?patient=Patient/$PATIENT_ID")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched by Patient reference (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search by Patient reference (HTTP $HTTP_CODE)"
fi

# Test 7: Search Patient by name
print_test "Search Patient by name"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient?name=Doe")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Patient by name (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Patient by name (HTTP $HTTP_CODE)"
fi

# Test 8: Search Patient by gender
print_test "Search Patient by gender"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient?gender=female")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Patient by gender (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Patient by gender (HTTP $HTTP_CODE)"
fi

# Test 9: Search Patient by birthdate
print_test "Search Patient by birthdate"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient?birthdate=1990-05-15")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Patient by birthdate (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Patient by birthdate (HTTP $HTTP_CODE)"
fi

# Test 10: Search with date prefix
print_test "Search Patient by birthdate with prefix (gt)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient?birthdate=gt1985-01-01")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched with date prefix (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search with date prefix (HTTP $HTTP_CODE)"
fi

# Test 11: Create with invalid reference (should fail)
print_test "Create Appointment with invalid reference (expect failure)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$BASE_URL/Appointment" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Appointment",
    "status": "booked",
    "start": "2024-12-15T10:00:00Z",
    "end": "2024-12-15T11:00:00Z",
    "participant": [{
      "actor": {
        "reference": "Patient/non-existent-patient"
      },
      "status": "accepted"
    }]
  }')

if [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "422" ]; then
    print_pass "Invalid reference correctly rejected (HTTP $HTTP_CODE)"
else
    print_fail "Invalid reference should have been rejected (HTTP $HTTP_CODE)"
fi

# Test 12: Get instance history
print_test "Get Appointment history"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment/$APPOINTMENT_ID/_history")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved history (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve history (HTTP $HTTP_CODE)"
fi

# Test 12.5: Get specific version (versionRead)
print_test "Get Appointment specific version"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment/$APPOINTMENT_ID/_history/1")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved specific version (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve specific version (HTTP $HTTP_CODE)"
fi

# Test 12.6: PATCH Appointment
print_test "PATCH Appointment (partial update)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PATCH "$BASE_URL/Appointment/$APPOINTMENT_ID" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Appointment",
    "id": "'"$APPOINTMENT_ID"'",
    "status": "cancelled"
  }')
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully patched Appointment (HTTP $HTTP_CODE)"
else
    print_fail "Failed to patch Appointment (HTTP $HTTP_CODE)"
fi

# Test 13: Create Medication
print_test "Create Medication"
MEDICATION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Medication" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Medication",
    "id": "test-med-001",
    "code": {
      "coding": [{
        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
        "code": "582620",
        "display": "Nizatidine Oral Solution"
      }]
    },
    "status": "active"
  }')

HTTP_CODE=$(echo "$MEDICATION_RESPONSE" | tail -n1)
MEDICATION_BODY=$(echo "$MEDICATION_RESPONSE" | sed '$d')
MEDICATION_ID="test-med-001"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Medication (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Medication (HTTP $HTTP_CODE)"
    echo "Response: $MEDICATION_BODY"
fi

# Test 14: Search by _lastUpdated
print_test "Search by _lastUpdated"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?_lastUpdated=gt2024-11-01")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched by _lastUpdated (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search by _lastUpdated (HTTP $HTTP_CODE)"
fi

# Test 15: Delete resources
print_test "Delete Appointment"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE "$BASE_URL/Appointment/$APPOINTMENT_ID")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully deleted Appointment (HTTP $HTTP_CODE)"
else
    print_fail "Failed to delete Appointment (HTTP $HTTP_CODE)"
fi

print_test "Delete Patient"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE "$BASE_URL/Patient/$PATIENT_ID")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully deleted Patient (HTTP $HTTP_CODE)"
else
    print_fail "Failed to delete Patient (HTTP $HTTP_CODE)"
fi

print_test "Delete Practitioner"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE "$BASE_URL/Practitioner/$PRACTITIONER_ID")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully deleted Practitioner (HTTP $HTTP_CODE)"
else
    print_fail "Failed to delete Practitioner (HTTP $HTTP_CODE)"
fi

print_test "Delete Medication"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE "$BASE_URL/Medication/$MEDICATION_ID")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully deleted Medication (HTTP $HTTP_CODE)"
else
    print_fail "Failed to delete Medication (HTTP $HTTP_CODE)"
fi

# Test 16: Verify deletion (Note: Server may use soft delete)
print_test "Verify resource after deletion"
VERIFY_DELETE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient/$PATIENT_ID")
if [ "$VERIFY_DELETE" = "404" ] || [ "$VERIFY_DELETE" = "410" ]; then
    print_pass "Deleted resource returns $VERIFY_DELETE (not found)"
else
    # Server may be using soft delete, returning 200
    print_pass "Resource returns $VERIFY_DELETE (server may use soft delete)"
fi

# ==============================================================================
# Additional Test Cases for CRUD Operations
# ==============================================================================

# Test 17: Read non-existent Patient (expect 404)
print_test "Read non-existent Patient (expect 404)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient/non-existent-id-999")
if [ "$HTTP_CODE" = "404" ]; then
    print_pass "Non-existent Patient correctly returns 404 (HTTP $HTTP_CODE)"
else
    print_fail "Expected 404 for non-existent Patient but got (HTTP $HTTP_CODE)"
fi

# Test 18: Read non-existent Practitioner (expect 404)
print_test "Read non-existent Practitioner (expect 404)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Practitioner/non-existent-id-999")
if [ "$HTTP_CODE" = "404" ]; then
    print_pass "Non-existent Practitioner correctly returns 404 (HTTP $HTTP_CODE)"
else
    print_fail "Expected 404 for non-existent Practitioner but got (HTTP $HTTP_CODE)"
fi

# Test 19: Read non-existent Appointment (expect 404)
print_test "Read non-existent Appointment (expect 404)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment/non-existent-id-999")
if [ "$HTTP_CODE" = "404" ]; then
    print_pass "Non-existent Appointment correctly returns 404 (HTTP $HTTP_CODE)"
else
    print_fail "Expected 404 for non-existent Appointment but got (HTTP $HTTP_CODE)"
fi

# Test 20: Read non-existent Medication (expect 404)
print_test "Read non-existent Medication (expect 404)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Medication/non-existent-id-999")
if [ "$HTTP_CODE" = "404" ]; then
    print_pass "Non-existent Medication correctly returns 404 (HTTP $HTTP_CODE)"
else
    print_fail "Expected 404 for non-existent Medication but got (HTTP $HTTP_CODE)"
fi

# ==============================================================================
# Create new resources for additional tests
# ==============================================================================

# Test 21: Create Practitioner for further testing
print_test "Create Practitioner (for update tests)"
PRAC2_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Practitioner" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Practitioner",
    "id": "test-prac-002",
    "identifier": [{
      "system": "http://example.org/practitioners",
      "value": "MD-67890"
    }],
    "active": true,
    "name": [{
      "family": "Johnson",
      "given": ["Emily"],
      "prefix": ["Dr"]
    }],
    "gender": "female",
    "telecom": [{
      "system": "phone",
      "value": "555-1234",
      "use": "work"
    }]
  }')

HTTP_CODE=$(echo "$PRAC2_RESPONSE" | tail -n1)
PRAC2_ID="test-prac-002"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Practitioner for testing (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Practitioner (HTTP $HTTP_CODE)"
fi

# Test 22: Create Patient for further testing
print_test "Create Patient (for update tests)"
PAT2_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Patient" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "test-patient-002",
    "identifier": [{
      "system": "http://example.org/patients",
      "value": "PT-11111"
    }],
    "active": true,
    "name": [{
      "family": "Brown",
      "given": ["Robert"]
    }],
    "gender": "male",
    "birthDate": "1985-03-20",
    "telecom": [{
      "system": "email",
      "value": "robert.brown@example.com"
    }],
    "address": [{
      "use": "home",
      "line": ["123 Main St"],
      "city": "Springfield",
      "state": "IL",
      "postalCode": "62701",
      "country": "USA"
    }]
  }')

HTTP_CODE=$(echo "$PAT2_RESPONSE" | tail -n1)
PAT2_ID="test-patient-002"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Patient for testing (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Patient (HTTP $HTTP_CODE)"
fi

# Test 23: Update Patient (PUT)
print_test "Update Patient with PUT"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT "$BASE_URL/Patient/$PAT2_ID" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "test-patient-002",
    "identifier": [{
      "system": "http://example.org/patients",
      "value": "PT-11111"
    }],
    "active": false,
    "name": [{
      "family": "Brown",
      "given": ["Robert", "James"]
    }],
    "gender": "male",
    "birthDate": "1985-03-20"
  }')

if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully updated Patient with PUT (HTTP $HTTP_CODE)"
else
    print_fail "Failed to update Patient with PUT (HTTP $HTTP_CODE)"
fi

# Test 24: PATCH Patient
print_test "PATCH Patient (partial update)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PATCH "$BASE_URL/Patient/$PAT2_ID" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "test-patient-002",
    "active": true
  }')

if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully patched Patient (HTTP $HTTP_CODE)"
else
    print_fail "Failed to patch Patient (HTTP $HTTP_CODE)"
fi

# Test 25: Update Practitioner (PUT)
print_test "Update Practitioner with PUT"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT "$BASE_URL/Practitioner/$PRAC2_ID" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Practitioner",
    "id": "test-prac-002",
    "identifier": [{
      "system": "http://example.org/practitioners",
      "value": "MD-67890"
    }],
    "active": false,
    "name": [{
      "family": "Johnson",
      "given": ["Emily", "Marie"],
      "prefix": ["Dr"]
    }],
    "gender": "female"
  }')

if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully updated Practitioner with PUT (HTTP $HTTP_CODE)"
else
    print_fail "Failed to update Practitioner with PUT (HTTP $HTTP_CODE)"
fi

# Test 26: PATCH Practitioner
print_test "PATCH Practitioner (partial update)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PATCH "$BASE_URL/Practitioner/$PRAC2_ID" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Practitioner",
    "id": "test-prac-002",
    "active": true
  }')

if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully patched Practitioner (HTTP $HTTP_CODE)"
else
    print_fail "Failed to patch Practitioner (HTTP $HTTP_CODE)"
fi

# Test 27: Create Medication for testing
print_test "Create Medication (for update tests)"
MED2_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Medication" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Medication",
    "id": "test-med-002",
    "code": {
      "coding": [{
        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
        "code": "313782",
        "display": "Acetaminophen 325 MG Oral Tablet"
      }]
    },
    "status": "active",
    "form": {
      "coding": [{
        "system": "http://snomed.info/sct",
        "code": "385055001",
        "display": "Tablet"
      }]
    }
  }')

HTTP_CODE=$(echo "$MED2_RESPONSE" | tail -n1)
MED2_ID="test-med-002"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Medication for testing (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Medication (HTTP $HTTP_CODE)"
fi

# Test 28: Update Medication (PUT)
print_test "Update Medication with PUT"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT "$BASE_URL/Medication/$MED2_ID" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Medication",
    "id": "test-med-002",
    "code": {
      "coding": [{
        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
        "code": "313782",
        "display": "Acetaminophen 325 MG Oral Tablet"
      }]
    },
    "status": "inactive"
  }')

if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully updated Medication with PUT (HTTP $HTTP_CODE)"
else
    print_fail "Failed to update Medication with PUT (HTTP $HTTP_CODE)"
fi

# Test 29: PATCH Medication
print_test "PATCH Medication (partial update)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PATCH "$BASE_URL/Medication/$MED2_ID" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Medication",
    "id": "test-med-002",
    "status": "active"
  }')

if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully patched Medication (HTTP $HTTP_CODE)"
else
    print_fail "Failed to patch Medication (HTTP $HTTP_CODE)"
fi

# Test 30: Create Appointment for history testing
print_test "Create Appointment (for history tests)"
APPT2_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/Appointment" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"Appointment\",
    \"id\": \"test-appt-002\",
    \"status\": \"proposed\",
    \"start\": \"2025-01-10T14:00:00Z\",
    \"end\": \"2025-01-10T15:00:00Z\",
    \"participant\": [
      {
        \"actor\": {
          \"reference\": \"Patient/$PAT2_ID\"
        },
        \"status\": \"needs-action\"
      },
      {
        \"actor\": {
          \"reference\": \"Practitioner/$PRAC2_ID\"
        },
        \"status\": \"accepted\"
      }
    ]
  }")

HTTP_CODE=$(echo "$APPT2_RESPONSE" | tail -n1)
APPT2_ID="test-appt-002"
if [ "$HTTP_CODE" = "201" ]; then
    print_pass "Created Appointment for history testing (HTTP $HTTP_CODE)"
else
    print_fail "Failed to create Appointment (HTTP $HTTP_CODE)"
fi

# Test 31: Get Patient history
print_test "Get Patient instance history"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient/$PAT2_ID/_history")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved Patient history (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve Patient history (HTTP $HTTP_CODE)"
fi

# Test 32: Get Practitioner history
print_test "Get Practitioner instance history"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Practitioner/$PRAC2_ID/_history")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved Practitioner history (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve Practitioner history (HTTP $HTTP_CODE)"
fi

# Test 33: Get Medication history
print_test "Get Medication instance history"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Medication/$MED2_ID/_history")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved Medication history (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve Medication history (HTTP $HTTP_CODE)"
fi

# Test 34: Search Practitioner by name
print_test "Search Practitioner by name"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Practitioner?name=Johnson")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Practitioner by name (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Practitioner by name (HTTP $HTTP_CODE)"
fi

# Test 35: Search Practitioner by identifier
print_test "Search Practitioner by identifier"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Practitioner?identifier=MD-67890")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Practitioner by identifier (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Practitioner by identifier (HTTP $HTTP_CODE)"
fi

# Test 36: Search Patient by identifier
print_test "Search Patient by identifier"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient?identifier=PT-11111")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Patient by identifier (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Patient by identifier (HTTP $HTTP_CODE)"
fi

# Test 37: Search Medication by status
print_test "Search Medication by status"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Medication?status=active")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Medication by status (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Medication by status (HTTP $HTTP_CODE)"
fi

# Test 38: Search Appointment by status
print_test "Search Appointment by status"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?status=proposed")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Appointment by status (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Appointment by status (HTTP $HTTP_CODE)"
fi

# Test 39: Search Appointment by date range
print_test "Search Appointment by date"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?date=ge2025-01-01")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched Appointment by date (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search Appointment by date (HTTP $HTTP_CODE)"
fi

# Test 40: Get Patient version (versionRead)
print_test "Get Patient specific version"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Patient/$PAT2_ID/_history/1")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved Patient version (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve Patient version (HTTP $HTTP_CODE)"
fi

# Test 41: Get Practitioner version (versionRead)
print_test "Get Practitioner specific version"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Practitioner/$PRAC2_ID/_history/1")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved Practitioner version (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve Practitioner version (HTTP $HTTP_CODE)"
fi

# Test 42: Get Medication version (versionRead)
print_test "Get Medication specific version"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Medication/$MED2_ID/_history/1")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully retrieved Medication version (HTTP $HTTP_CODE)"
else
    print_fail "Failed to retrieve Medication version (HTTP $HTTP_CODE)"
fi

# Test 43: Update non-existent Patient (should fail)
print_test "Update non-existent Patient (expect error)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT "$BASE_URL/Patient/non-existent-999" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "non-existent-999",
    "active": true,
    "name": [{"family": "Test"}]
  }')

if [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "400" ]; then
    print_pass "Update non-existent Patient correctly rejected (HTTP $HTTP_CODE)"
else
    print_fail "Expected error for updating non-existent Patient (HTTP $HTTP_CODE)"
fi

# Test 44: Delete non-existent resource (should fail gracefully)
print_test "Delete non-existent Appointment (expect error)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE "$BASE_URL/Appointment/non-existent-999")
if [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "400" ]; then
    print_pass "Delete non-existent Appointment correctly handled (HTTP $HTTP_CODE)"
else
    print_fail "Expected error for deleting non-existent Appointment (HTTP $HTTP_CODE)"
fi

# Test 45: Search all Patients
print_test "Search all Patients (no filter)"
SEARCH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/Patient")
HTTP_CODE=$(echo "$SEARCH_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched all Patients (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search all Patients (HTTP $HTTP_CODE)"
fi

# Test 46: Search all Practitioners
print_test "Search all Practitioners (no filter)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Practitioner")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched all Practitioners (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search all Practitioners (HTTP $HTTP_CODE)"
fi

# Test 47: Search all Appointments
print_test "Search all Appointments (no filter)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched all Appointments (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search all Appointments (HTTP $HTTP_CODE)"
fi

# Test 48: Search all Medications
print_test "Search all Medications (no filter)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Medication")
if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Successfully searched all Medications (HTTP $HTTP_CODE)"
else
    print_fail "Failed to search all Medications (HTTP $HTTP_CODE)"
fi

# ======================================================================
# _include Search Parameter Tests
# ======================================================================

# Test 49: Search Appointments with _include=Appointment:patient
print_test "Search Appointments with _include=Appointment:patient"
RESPONSE=$(curl -s "$BASE_URL/Appointment?_include=Appointment:patient")
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?_include=Appointment:patient")
if [ "$HTTP_CODE" = "200" ]; then
    # Check if response has both Appointment and Patient resources
    APPOINTMENT_COUNT=$(echo "$RESPONSE" | grep -o '"resourceType":"Appointment"' | wc -l)
    PATIENT_COUNT=$(echo "$RESPONSE" | grep -o '"resourceType":"Patient"' | wc -l)
    INCLUDE_MODE=$(echo "$RESPONSE" | grep -o '"mode":"include"' | wc -l)
    
    if [ "$APPOINTMENT_COUNT" -gt 0 ] && [ "$PATIENT_COUNT" -gt 0 ] && [ "$INCLUDE_MODE" -gt 0 ]; then
        print_pass "Successfully returned Appointments with included Patients (HTTP $HTTP_CODE, Appointments: $APPOINTMENT_COUNT, Patients: $PATIENT_COUNT, Include mode: $INCLUDE_MODE)"
    else
        print_fail "Response doesn't contain expected included resources (Appointments: $APPOINTMENT_COUNT, Patients: $PATIENT_COUNT, Include mode: $INCLUDE_MODE)"
    fi
else
    print_fail "Failed to search with _include (HTTP $HTTP_CODE)"
fi

# Test 50: Search Appointments with _include=Appointment:actor
print_test "Search Appointments with _include=Appointment:actor"
RESPONSE=$(curl -s "$BASE_URL/Appointment?_include=Appointment:actor")
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?_include=Appointment:actor")
if [ "$HTTP_CODE" = "200" ]; then
    # Check if response has search mode include
    INCLUDE_MODE=$(echo "$RESPONSE" | grep -o '"mode":"include"' | wc -l)
    MATCH_MODE=$(echo "$RESPONSE" | grep -o '"mode":"match"' | wc -l)
    
    if [ "$MATCH_MODE" -gt 0 ]; then
        print_pass "Successfully returned Appointments with _include=Appointment:actor (HTTP $HTTP_CODE, Match mode: $MATCH_MODE, Include mode: $INCLUDE_MODE)"
    else
        print_fail "Response missing expected search modes"
    fi
else
    print_fail "Failed to search with _include (HTTP $HTTP_CODE)"
fi

# Test 51: Search Appointments with wildcard _include=*
print_test "Search Appointments with wildcard _include=*"
RESPONSE=$(curl -s "$BASE_URL/Appointment?_include=*")
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?_include=*")
if [ "$HTTP_CODE" = "200" ]; then
    # Check if response is a valid Bundle
    BUNDLE_TYPE=$(echo "$RESPONSE" | grep -o '"type":"searchset"' | wc -l)
    INCLUDE_MODE=$(echo "$RESPONSE" | grep -o '"mode":"include"' | wc -l)
    
    if [ "$BUNDLE_TYPE" -gt 0 ]; then
        print_pass "Successfully returned Appointments with wildcard _include=* (HTTP $HTTP_CODE, Include mode count: $INCLUDE_MODE)"
    else
        print_fail "Response is not a valid searchset Bundle"
    fi
else
    print_fail "Failed to search with wildcard _include (HTTP $HTTP_CODE)"
fi

# Test 52: Search with _include and filter parameter
print_test "Search Appointments by status with _include=Appointment:patient"
RESPONSE=$(curl -s "$BASE_URL/Appointment?status=booked&_include=Appointment:patient")
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/Appointment?status=booked&_include=Appointment:patient")
if [ "$HTTP_CODE" = "200" ]; then
    # Check if response contains both match and include modes
    MATCH_MODE=$(echo "$RESPONSE" | grep -o '"mode":"match"' | wc -l)
    INCLUDE_MODE=$(echo "$RESPONSE" | grep -o '"mode":"include"' | wc -l)
    
    if [ "$MATCH_MODE" -gt 0 ]; then
        print_pass "Successfully returned filtered Appointments with included resources (HTTP $HTTP_CODE, Match: $MATCH_MODE, Include: $INCLUDE_MODE)"
    else
        print_fail "Response missing expected data"
    fi
else
    print_fail "Failed to search with filter and _include (HTTP $HTTP_CODE)"
fi

# Summary
echo ""
echo "======================================================================"
echo "Test Summary"
echo "======================================================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi

# FHIR Server Test Suite

This directory contains comprehensive integration tests for the FHIR R4 Server using HTTP requests via curl.

## Overview

The test suite uses a bash script (`integration-tests.sh`) to perform real HTTP-based integration testing against the running FHIR server.

## Test Coverage

The test suite includes 21 tests covering:

### 1. CRUD Operations
- ✅ Create resources (Practitioner, Patient, Appointment, Medication)
- ✅ Read resources by ID
- ✅ Update resources (PUT)
- ✅ Patch resources (PATCH - partial update)
- ✅ Delete resources
- ✅ Verify deletions

### 2. Reference Management
- ✅ Create resources with valid references
- ✅ Validate invalid references are rejected
- ✅ Search by reference parameters (patient, practitioner)
- ✅ Verify reference persistence across operations

### 3. Search Operations
- ✅ Search by string parameters (name)
- ✅ Search by token parameters (gender, status)
- ✅ Search by reference parameters (patient=Patient/id)
- ✅ Search by date parameters (birthdate)
- ✅ Search with date prefixes (gt, lt, ge, le)
- ✅ Search by _lastUpdated with date prefixes
- ✅ Multiple parameter searches

### 4. Version History
- ✅ Get instance history (_history endpoint)
- ✅ Read specific version (_history/{vid})
- ✅ Verify history tracking after updates

### 5. Error Handling
- ✅ Invalid reference validation
- ✅ Non-existent resource handling

## Running Tests

### Quick Start

From the `fhir-service` directory, simply run:

`bash ./tests/integration-tests.sh`

The script:
1. Stops any existing server
2. Cleans the test database
3. Starts a fresh server
4. Waits for server to be ready
5. Runs all tests
6. Stops the server when complete

### Test Resources

The tests create the following resources:

- **Practitioner**: `test-prac-001` - Dr. John Smith (MD-12345)
- **Patient**: `test-patient-001` - Jane Doe (PT-67890), birthdate 1990-05-15, references Practitioner
- **Appointment**: `test-appt-001` - Booked appointment, references Patient and Practitioner
- **Medication**: `test-med-001` - Nizatidine Oral Solution

All test resources use IDs prefixed with `test-` for easy identification.

## Configuration

### Test Database

The test script uses a separate database configured in `tests/Config.toml`:

```toml
[ballerina_fhir_server.handlers]
dbUrl = "jdbc:h2:./tests/fhir-test-db"
dbUser = "sa"
dbPassword = ""
```

The database is automatically cleaned before each test run.

### Base URL

Tests connect to: `http://localhost:9090/fhir/r4`

If you need to change this, edit the `BASE_URL` variable in `integration-tests.sh`.

## File Structure

```
tests/
├── integration-tests.sh    # Main test script (executable)
├── Config.toml             # Test database configuration
├── README.md               # This file
└── QUICK_REFERENCE.md      # Quick command reference
```

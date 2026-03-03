#!/bin/bash

# FHIR Server Start Script (Unix/macOS/Linux)
# This script starts the Ballerina FHIR server

# Detect database type from Config.toml
DB_TYPE="unknown"
if [ -f "Config.toml" ]; then
    DB_TYPE=$(grep -m1 '^dbType' Config.toml | cut -d'"' -f2)
fi

echo "========================================="
echo "Starting FHIR Server"
echo "========================================="

# Check if Ballerina is installed
if ! command -v bal &> /dev/null; then
    echo "Error: Ballerina is not installed or not in PATH"
    echo "Please install Ballerina from: https://ballerina.io/downloads/"
    exit 1
fi

# Display Ballerina version
echo "Using Ballerina version:"
bal version

# Database-specific setup
if [ "$DB_TYPE" = "h2" ]; then
    echo ""
    echo "Database: H2 (embedded)"
    
    # Create data directory if it doesn't exist
    mkdir -p data
    
    # Check if database exists
    if [ ! -f "data/fhir-db.mv.db" ]; then
        echo "H2 database will be created at: ./data/fhir-db"
    else
        echo "Using existing H2 database at: ./data/fhir-db"
    fi
elif [ "$DB_TYPE" = "postgresql" ]; then
    echo ""
    echo "Database: PostgreSQL (external)"
    echo "Ensure PostgreSQL is running and configured in Config.toml"
else
    echo ""
    echo "Only H2 and PostgreSQL databases are supported. Detected dbType: $DB_TYPE"
fi

echo ""
echo "Starting FHIR Server..."
echo "Server will be available at: http://localhost:9090"
echo "Press Ctrl+C to stop the server"
echo ""

# Log file with timestamp so each run gets its own file
mkdir -p logs
LOG_FILE="logs/fhir-server-$(date +%Y%m%d-%H%M%S).log"
echo "Logs are being saved to: $LOG_FILE"
echo ""

# Run the Ballerina service — tee writes to both stdout and the log file
bal run 2>&1 | tee "$LOG_FILE"

echo ""
echo "Server stopped. Logs saved to: $LOG_FILE"

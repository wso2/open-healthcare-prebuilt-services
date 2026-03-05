#!/bin/bash

# Startup script for A2A MCP Server
echo "Starting A2A MCP Server..."
echo "Environment variables:"
echo "PORT: ${PORT:-3001}"
echo "LOG_LEVEL: ${LOG_LEVEL:-INFO}"

# Start the Python application
exec python main.py

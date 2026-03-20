@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "JAR_NAME=ballerina_fhir_server.jar"
set "JAR_PATH=%ROOT_DIR%%JAR_NAME%"

if not exist "%JAR_PATH%" (
  echo Error: "%JAR_NAME%" not found next to this script.
  echo Expected: %JAR_PATH%
  echo If you're running from a release zip, keep the jar and scripts in the same folder.
  exit /b 1
)

where java >nul 2>nul
if errorlevel 1 (
  echo Error: Java is not installed or not in PATH.
  echo Please install Java 21+ and retry.
  exit /b 1
)

cd /d "%ROOT_DIR%"
echo Starting FHIR Server...

java %JAVA_OPTS% -jar "%JAR_PATH%"

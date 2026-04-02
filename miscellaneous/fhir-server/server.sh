#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR_NAME="ballerina_fhir_server.jar"
JAR_PATH="${ROOT_DIR}/${JAR_NAME}"

if [[ ! -f "${JAR_PATH}" ]]; then
  echo "Error: '${JAR_NAME}' not found next to this script."
  echo "Expected: ${JAR_PATH}"
  echo "If you're running from a release zip, keep the jar and scripts in the same folder."
  exit 1
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Error: Java is not installed or not in PATH."
  echo "Please install Java 21+ and retry."
  exit 1
fi

cd "${ROOT_DIR}"
echo "Starting FHIR Server..."

exec java ${JAVA_OPTS:-} -jar "${JAR_PATH}"

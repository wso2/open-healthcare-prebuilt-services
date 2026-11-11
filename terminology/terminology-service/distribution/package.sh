#!/usr/bin/env bash
# Assembles the terminology service release zip from a built jar.
# Usage: distribution/package.sh <version> [output-dir]
# Run from anywhere after `bal build` in the terminology-service directory.
set -euo pipefail

VERSION="${1:?usage: package.sh <version> [output-dir]}"
SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$(mkdir -p "${2:-${SERVICE_DIR}/target/release}" && cd "${2:-${SERVICE_DIR}/target/release}" && pwd)"
JAR="${SERVICE_DIR}/target/bin/terminology_service.jar"
NAME="terminology-service-${VERSION}"

[[ -f "${JAR}" ]] || { echo "Error: ${JAR} not found. Run 'bal build' first."; exit 1; }

STAGE="$(mktemp -d)/${NAME}"
mkdir -p "${STAGE}/dbscripts" "${STAGE}/database" "${STAGE}/logs"

cp "${JAR}" "${STAGE}/"
cp "${SERVICE_DIR}/distribution/server.sh" "${SERVICE_DIR}/distribution/server.bat" "${STAGE}/"
# Stamp the release version into the shipped config; the service reports it in TerminologyCapabilities.
awk -v version="${VERSION}" '
  { print }
  $0 == "[wso2.terminology_service]" {
    print "# Release version, set by the build. Reported in the TerminologyCapabilities statement."
    print "service_version = \"" version "\""
  }
' "${SERVICE_DIR}/distribution/sample-Config.toml" > "${STAGE}/Config.toml"
grep -q "^service_version = \"${VERSION}\"$" "${STAGE}/Config.toml" \
  || { echo "Error: could not set service_version in Config.toml"; exit 1; }
cp "${SERVICE_DIR}/distribution/README.md" "${STAGE}/README.md"
cp "${SERVICE_DIR}/modules/store_h2/script.sql" "${STAGE}/dbscripts/h2.sql"
cp "${SERVICE_DIR}/modules/store_pg/script.sql" "${STAGE}/dbscripts/postgresql.sql"
chmod +x "${STAGE}/server.sh"

# Pre-initialize an empty H2 database with the H2 driver bundled in the jar,
# so the release runs out of the box with db_type = "h2".
(cd "${STAGE}" && java -cp terminology_service.jar org.h2.tools.RunScript \
  -url "jdbc:h2:./database/terminology" -user sa -password "" -script dbscripts/h2.sql)

ZIP="${OUT_DIR}/${NAME}.zip"
rm -f "${ZIP}"
(cd "$(dirname "${STAGE}")" && zip -qr "${ZIP}" "${NAME}")
rm -rf "$(dirname "${STAGE}")"

echo "Created ${ZIP}"

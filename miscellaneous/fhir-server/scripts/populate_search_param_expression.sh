#!/usr/bin/env bash

set -euo pipefail

# ── Resolve script directory, CSV path, and default schema file ───────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="${SCRIPT_DIR}/../assets/r4-searchParam-Expression.csv"

# Look for a postgresql schema file in the same directory
PG_SCHEMA_FILE=""
for f in "${SCRIPT_DIR}"/schema-postgresql.sql "${SCRIPT_DIR}"/*schema*postgresql*.sql "${SCRIPT_DIR}"/*postgresql*schema*.sql; do
  if [ -f "$f" ]; then
    PG_SCHEMA_FILE="$f"
    break
  fi
done

# ── Defaults ──────────────────────────────────────────────────────────────────
TABLE_NAME="SEARCH_PARAM_RES_EXPRESSIONS"
OUT_DIR="$SCRIPT_DIR"
SCHEMA=""
PREPEND_DROP="false"
PREPEND_CREATE="false"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
  YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; GREEN=''; CYAN=''; YELLOW=''; BOLD=''; RESET=''
fi

log_info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()       { log_error "$*"; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--table)  TABLE_NAME="$2";       shift 2 ;;
    -o|--outdir) OUT_DIR="$2";          shift 2 ;;
    -s|--schema) SCHEMA="$2";           shift 2 ;;
    --drop)      PREPEND_DROP="true";   shift   ;;
    --create)    PREPEND_CREATE="true"; shift   ;;
    *) die "Unknown option: $1" ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────────────────
[ -f "$CSV_FILE" ] || die "CSV file not found: $CSV_FILE"
command -v python3 &>/dev/null || die "python3 is required but not found"
mkdir -p "$OUT_DIR"

# ── Python helper ─────────────────────────────────────────────────────────────
PY_HELPER=$(mktemp /tmp/_gi_helper_XXXXXX.py)
trap 'rm -f "$PY_HELPER"' EXIT

cat > "$PY_HELPER" << 'PYEOF'
import csv, os

def env(k, d=""): return os.environ.get(k, d)

csv_file       = env("GI_CSV_FILE")
table_name     = env("GI_TABLE_NAME", "SEARCH_PARAM_RES_EXPRESSIONS")
output_file    = env("GI_OUTPUT_FILE")
schema         = env("GI_SCHEMA")
append_mode    = env("GI_APPEND") == "true"
prepend_drop   = env("GI_DROP")   == "true"
prepend_create = env("GI_CREATE") == "true"

def qi(name):
    return f'"{name}"'

TABLE    = f"{qi(schema)}.{qi(table_name)}" if schema else qi(table_name)
DB_COLS  = ["SEARCH_PARAM_NAME", "SEARCH_PARAM_TYPE", "RESOURCE_NAME", "EXPRESSION", "IS_CUSTOM"]
col_list = ", ".join(qi(c) for c in DB_COLS)

def escape(val):
    return "'" + val.replace("'", "''") + "'"

def sql_str(raw):
    return escape(raw.strip())

def sql_bool(val):
    return "TRUE" if val else "FALSE"

with open(csv_file, newline="", encoding="utf-8-sig") as fh:
    reader   = csv.reader(fh)
    next(reader)
    all_rows = list(reader)

total = len(all_rows)

def drop_stmt():
    return f"DROP TABLE IF EXISTS {TABLE};"

def create_stmt():
    return (
        f"CREATE TABLE IF NOT EXISTS {TABLE} (\n"
        f"  {qi('ID')} SERIAL,\n"
        f"  {qi('SEARCH_PARAM_NAME')} VARCHAR(191) NOT NULL,\n"
        f"  {qi('SEARCH_PARAM_TYPE')} VARCHAR(191) NOT NULL,\n"
        f"  {qi('RESOURCE_NAME')} VARCHAR(191) NOT NULL,\n"
        f"  {qi('EXPRESSION')} TEXT NOT NULL,\n"
        f"  {qi('IS_CUSTOM')} BOOLEAN DEFAULT FALSE,\n"
        f"  PRIMARY KEY ({qi('ID')})\n"
        f");"
    )

out = []

if not append_mode:
    out += [
        f"-- Source  : {os.path.basename(csv_file)}",
        f"-- Target  : POSTGRESQL  |  Table: {TABLE}",
        f"-- Rows    : {total}",
        "",
        "SET client_encoding = 'UTF8';",
        "",
    ]
else:
    out += [
        "",
        f"-- ============================================================",
        f"-- INSERT data for {TABLE}",
        f"-- Source  : {os.path.basename(csv_file)}",
        f"-- Rows    : {total}",
        f"-- ============================================================",
        "",
    ]

if prepend_drop:
    out += [drop_stmt(), ""]
if prepend_create:
    out += [create_stmt(), ""]

out += ["BEGIN;", ""]

for row in all_rows:
    while len(row) < 4:
        row.append("")
    vals = ", ".join([
        sql_str(row[0]),
        sql_str(row[2]),
        sql_str(row[1]),
        sql_str(row[3]),
        sql_bool(False),
    ])
    out.append(f"INSERT INTO {TABLE} ({col_list}) VALUES ({vals});")

out += ["", "COMMIT;", ""]

file_mode = "a" if append_mode else "w"
with open(output_file, file_mode, encoding="utf-8") as fh:
    fh.write("\n".join(out))

print(f"SUCCESS|rows={total}")
PYEOF

# ── Append INSERTs to schema file, or generate a standalone file ──────────────
echo -e "${BOLD}Table      : ${TABLE_NAME}${RESET}"
echo -e "${BOLD}Source CSV : ${CSV_FILE}${RESET}"
echo ""

if [ -n "$PG_SCHEMA_FILE" ]; then
  OUT_FILE="$PG_SCHEMA_FILE"
  APPEND="true"
  log_info "Appending postgres INSERTs → $(basename "$OUT_FILE")"
else
  OUT_FILE="${OUT_DIR}/insert_${TABLE_NAME}_postgres.sql"
  APPEND="false"
  log_info "Generating postgres → $(basename "$OUT_FILE")"
fi

RESULT=$(
  GI_CSV_FILE="$CSV_FILE"      \
  GI_TABLE_NAME="$TABLE_NAME"  \
  GI_OUTPUT_FILE="$OUT_FILE"   \
  GI_SCHEMA="$SCHEMA"          \
  GI_APPEND="$APPEND"          \
  GI_DROP="$PREPEND_DROP"      \
  GI_CREATE="$PREPEND_CREATE"  \
  python3 "$PY_HELPER"
) || die "Failed to generate SQL"

if [[ "$RESULT" == SUCCESS* ]]; then
  ROWS=$(echo "$RESULT" | grep -o 'rows=[0-9]*' | cut -d= -f2)
  if [ "$APPEND" = "true" ]; then
    log_ok "Appended ${ROWS} rows → ${OUT_FILE}"
  else
    log_ok "${OUT_FILE}  (${ROWS} rows)"
  fi
  echo ""
  echo -e "${GREEN}${BOLD}Done.${RESET}"
else
  die "Generation failed: $RESULT"
fi
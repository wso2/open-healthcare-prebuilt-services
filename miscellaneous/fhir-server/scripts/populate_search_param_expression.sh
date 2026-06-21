#!/usr/bin/env bash

set -euo pipefail

# ── Resolve script directory and CSV path ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="${SCRIPT_DIR}/../assets/r4-searchParam-Expression.csv"

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
import csv, os, re

def env(k, d=""): return os.environ.get(k, d)

csv_file       = env("GI_CSV_FILE")
table_name     = env("GI_TABLE_NAME", "SEARCH_PARAM_RES_EXPRESSIONS")
output_file    = env("GI_OUTPUT_FILE")
schema         = env("GI_SCHEMA")
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

# ── Read CSV ──────────────────────────────────────────────────────────────────
with open(csv_file, newline="", encoding="utf-8-sig") as fh:
    reader   = csv.reader(fh)
    next(reader)
    all_rows = list(reader)

# ── Read existing SQL file and extract already-present keys ───────────────────
# Parse each INSERT VALUES line and extract all 4 string columns precisely.
# INSERT column order: SEARCH_PARAM_NAME, SEARCH_PARAM_TYPE, RESOURCE_NAME, EXPRESSION, IS_CUSTOM
# Dedup key: (SEARCH_PARAM_NAME, SEARCH_PARAM_TYPE, RESOURCE_NAME) — all three together.
def parse_insert_keys(filepath):
    """Extract a set of (name, type, resource) tuples from existing INSERT lines."""
    keys = set()
    if not os.path.exists(filepath):
        return keys

    # Matches a single-quoted SQL string value, handling '' escapes
    token = r"'((?:[^']|'')*)'"
    # Full VALUES pattern: ('col1', 'col2', 'col3', 'col4', BOOL)
    pattern = re.compile(
        r"VALUES\s*\(\s*" + token + r"\s*,\s*" + token + r"\s*,\s*" + token + r"\s*,\s*" + token + r"\s*,",
        re.IGNORECASE
    )
    with open(filepath, encoding="utf-8") as fh:
        for line in fh:
            m = pattern.search(line)
            if m:
                # col positions: 1=SEARCH_PARAM_NAME, 2=SEARCH_PARAM_TYPE, 3=RESOURCE_NAME, 4=EXPRESSION
                name     = m.group(1).replace("''", "'").strip().lower()
                typ      = m.group(2).replace("''", "'").strip().lower()
                resource = m.group(3).replace("''", "'").strip().lower()
                keys.add((name, typ, resource))
    return keys

existing_keys = parse_insert_keys(output_file)

# ── Filter to only new rows ───────────────────────────────────────────────────
def csv_key(row):
    return (row[0].strip().lower(), row[2].strip().lower(), row[1].strip().lower())  # name, type, resource

new_rows = []
for row in all_rows:
    while len(row) < 4:
        row.append("")
    if csv_key(row) not in existing_keys:
        new_rows.append(row)

total_csv      = len(all_rows)
total_existing = len(existing_keys)
total_new      = len(new_rows)

# ── If no new rows, exit early ────────────────────────────────────────────────
if total_new == 0:
    print(f"SKIP|total={total_csv}|existing={total_existing}|new=0")
    raise SystemExit(0)

# ── Build output ──────────────────────────────────────────────────────────────
is_new_file = not os.path.exists(output_file)

out = []

if is_new_file:
    out += [
        f"-- Source  : {os.path.basename(csv_file)}",
        f"-- Target  : POSTGRESQL  |  Table: {TABLE}",
        f"-- Rows    : {total_csv}",
        "",
        "SET client_encoding = 'UTF8';",
        "",
    ]
    if prepend_drop:
        out += [drop_stmt(), ""]
    if prepend_create:
        out += [create_stmt(), ""]
else:
    # Appending new records to existing file — add a clear section marker
    out += [
        "",
        f"-- New records added: {total_new}",
        "",
    ]

out += ["BEGIN;", ""]

for row in new_rows:
    vals = ", ".join([
        sql_str(row[0]),   # Search_Parm      -> SEARCH_PARAM_NAME
        sql_str(row[2]),   # Search_Pram_Type -> SEARCH_PARAM_TYPE
        sql_str(row[1]),   # Resource         -> RESOURCE_NAME
        sql_str(row[3]),   # Expression       -> EXPRESSION
        sql_bool(False),   # IS_CUSTOM        -> FALSE
    ])
    out.append(f"INSERT INTO {TABLE} ({col_list}) VALUES ({vals});")

out += ["", "COMMIT;", ""]

# Append to existing file, or create new
file_mode = "w" if is_new_file else "a"
with open(output_file, file_mode, encoding="utf-8") as fh:
    fh.write("\n".join(out))

print(f"SUCCESS|total={total_csv}|existing={total_existing}|new={total_new}")
PYEOF

# ── Run ───────────────────────────────────────────────────────────────────────
echo -e "${BOLD}Table      : ${TABLE_NAME}${RESET}"
echo -e "${BOLD}Source CSV : ${CSV_FILE}${RESET}"
echo ""

OUT_FILE="${OUT_DIR}/insert_${TABLE_NAME}_postgres.sql"
log_info "Output file → $(basename "$OUT_FILE")"

RESULT=$(
  GI_CSV_FILE="$CSV_FILE"      \
  GI_TABLE_NAME="$TABLE_NAME"  \
  GI_OUTPUT_FILE="$OUT_FILE"   \
  GI_SCHEMA="$SCHEMA"          \
  GI_DROP="$PREPEND_DROP"      \
  GI_CREATE="$PREPEND_CREATE"  \
  python3 "$PY_HELPER"
) || die "Failed to generate SQL"

TOTAL=$(   echo "$RESULT" | grep -o 'total=[0-9]*'    | cut -d= -f2)
EXISTING=$(echo "$RESULT" | grep -o 'existing=[0-9]*' | cut -d= -f2)
NEW=$(     echo "$RESULT" | grep -o 'new=[0-9]*'      | cut -d= -f2)

if [[ "$RESULT" == SKIP* ]]; then
  log_warn "No new records found — file unchanged. (CSV: ${TOTAL} rows, all already present)"
elif [[ "$RESULT" == SUCCESS* ]]; then
  log_ok "CSV rows    : ${TOTAL}"
  log_ok "Already present : ${EXISTING}"
  log_ok "Newly added : ${NEW}"
  log_ok "Output      : ${OUT_FILE}"
  echo ""
  echo -e "${GREEN}${BOLD}Done.${RESET}"
else
  die "Generation failed: $RESULT"
fi
-- FHIR Server PostgreSQL Schema (v3)
-- Normalized design: 11 core tables replacing 150+ per-resource tables.
-- Run this script before starting the server for the first time.
-- Requires PostgreSQL 13+. For Location near-search, install PostGIS.

-- ─── Schema version ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS schema_version (
    version     INT         NOT NULL PRIMARY KEY,
    upgraded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Master resource table ────────────────────────────────────────────────────
-- Replaces all 150+ {ResourceType}Table tables and the old RESOURCE_TABLE.
-- search_text is a pre-built tsvector for _text / _content full-text search.

CREATE TABLE IF NOT EXISTS resources (
    fhir_id       VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    version_id    INT          NOT NULL DEFAULT 1,
    last_updated  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    is_deleted    BOOLEAN      NOT NULL DEFAULT FALSE,
    resource_json JSONB        NOT NULL,
    search_text   TSVECTOR,
    PRIMARY KEY (fhir_id, resource_type)
);

CREATE INDEX IF NOT EXISTS idx_res_type_updated ON resources (resource_type, last_updated DESC);
CREATE INDEX IF NOT EXISTS idx_res_active        ON resources (resource_type, last_updated DESC) WHERE is_deleted = FALSE;
CREATE INDEX IF NOT EXISTS idx_res_json_gin      ON resources USING GIN (resource_json);
CREATE INDEX IF NOT EXISTS idx_res_search_text   ON resources USING GIN (search_text);

-- ─── Version history ──────────────────────────────────────────────────────────
-- Append-only audit trail. Replaces the old RESOURCE_HISTORY table.
-- resource_json captures the full snapshot at each version for restore/audit.

CREATE TABLE IF NOT EXISTS resource_history (
    id            BIGSERIAL    PRIMARY KEY,
    fhir_id       VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    version_id    INT          NOT NULL,
    operation     VARCHAR(10)  NOT NULL,   -- CREATE | UPDATE | DELETE
    recorded_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    resource_json JSONB,
    UNIQUE (fhir_id, resource_type, version_id)
);

CREATE INDEX IF NOT EXISTS idx_hist_resource ON resource_history (resource_type, fhir_id, version_id DESC);
CREATE INDEX IF NOT EXISTS idx_hist_time     ON resource_history (recorded_at DESC);

-- ─── String search index ─────────────────────────────────────────────────────
-- Param type: string.
-- value_exact preserves original case for :exact modifier.
-- value_lower is downcased for the default case-insensitive prefix match.

CREATE TABLE IF NOT EXISTS sp_string (
    id            BIGSERIAL    PRIMARY KEY,
    resource_id   VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    param_name    VARCHAR(191) NOT NULL,
    value_exact   VARCHAR(512),
    value_lower   VARCHAR(512),
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_str_lower ON sp_string (resource_type, param_name, value_lower);
CREATE INDEX IF NOT EXISTS idx_sp_str_exact ON sp_string (resource_type, param_name, value_exact);
-- Uncomment for :contains support (requires pg_trgm extension):
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX idx_sp_str_trgm ON sp_string USING GIN (value_lower gin_trgm_ops);

-- ─── Token search index ───────────────────────────────────────────────────────
-- Param type: token (CodeableConcept, Coding, Identifier, code, boolean).
-- display is stored for the :text modifier.

CREATE TABLE IF NOT EXISTS sp_token (
    id            BIGSERIAL    PRIMARY KEY,
    resource_id   VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    param_name    VARCHAR(191) NOT NULL,
    system        VARCHAR(512),
    code          VARCHAR(191),
    display       VARCHAR(512),
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_tok_sys_code ON sp_token (resource_type, param_name, system, code);
CREATE INDEX IF NOT EXISTS idx_sp_tok_code     ON sp_token (resource_type, param_name, code);
CREATE INDEX IF NOT EXISTS idx_sp_tok_system   ON sp_token (resource_type, param_name, system);

-- ─── Date search index ────────────────────────────────────────────────────────
-- Param type: date / dateTime / Period / instant.
-- Partial-precision dates (e.g. "2000", "2000-04") are expanded to
-- [value_low, value_high] at write time so all 8 FHIR comparators work correctly.
-- value_precision records the original precision (YEAR|MONTH|DAY|SECOND).

CREATE TABLE IF NOT EXISTS sp_date (
    id              BIGSERIAL    PRIMARY KEY,
    resource_id     VARCHAR(64)  NOT NULL,
    resource_type   VARCHAR(100) NOT NULL,
    param_name      VARCHAR(191) NOT NULL,
    value_low       TIMESTAMPTZ  NOT NULL,
    value_high      TIMESTAMPTZ  NOT NULL,
    value_precision VARCHAR(10)  NOT NULL DEFAULT 'SECOND',
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_date_range ON sp_date (resource_type, param_name, value_low, value_high);

-- ─── Number search index ──────────────────────────────────────────────────────
-- Param type: number.
-- value_low / value_high are derived from significant-figure precision at write
-- time so that FHIR's implicit-precision eq semantics are correct.

CREATE TABLE IF NOT EXISTS sp_number (
    id            BIGSERIAL     PRIMARY KEY,
    resource_id   VARCHAR(64)   NOT NULL,
    resource_type VARCHAR(100)  NOT NULL,
    param_name    VARCHAR(191)  NOT NULL,
    value         DECIMAL(20,6) NOT NULL,
    value_low     DECIMAL(20,6) NOT NULL,
    value_high    DECIMAL(20,6) NOT NULL,
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_num_range ON sp_number (resource_type, param_name, value_low, value_high);

-- ─── Quantity search index ────────────────────────────────────────────────────
-- Param type: quantity.
-- canonical_value / canonical_units hold the UCUM-normalised value so
-- cross-unit comparisons (e.g. mg vs g) work correctly.

CREATE TABLE IF NOT EXISTS sp_quantity (
    id               BIGSERIAL     PRIMARY KEY,
    resource_id      VARCHAR(64)   NOT NULL,
    resource_type    VARCHAR(100)  NOT NULL,
    param_name       VARCHAR(191)  NOT NULL,
    value            DECIMAL(20,6) NOT NULL,
    value_low        DECIMAL(20,6) NOT NULL,
    value_high       DECIMAL(20,6) NOT NULL,
    system           VARCHAR(255),
    code             VARCHAR(64),
    canonical_value  DECIMAL(20,6),
    canonical_units  VARCHAR(64),
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_qty_raw       ON sp_quantity (resource_type, param_name, value_low, value_high, system, code);
CREATE INDEX IF NOT EXISTS idx_sp_qty_canonical ON sp_quantity (resource_type, param_name, canonical_value, canonical_units)
    WHERE canonical_value IS NOT NULL;

-- ─── URI search index ─────────────────────────────────────────────────────────
-- Param type: uri.
-- text_pattern_ops enables efficient prefix matching for :below.

CREATE TABLE IF NOT EXISTS sp_uri (
    id            BIGSERIAL    PRIMARY KEY,
    resource_id   VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    param_name    VARCHAR(191) NOT NULL,
    value         VARCHAR(512) NOT NULL,
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_uri_exact  ON sp_uri (resource_type, param_name, value);
CREATE INDEX IF NOT EXISTS idx_sp_uri_prefix ON sp_uri (resource_type, param_name, value text_pattern_ops);

-- ─── Reference search index ───────────────────────────────────────────────────
-- Param type: reference.
-- Replaces the old REFERENCES table and CUSTOM_EXTENSION_SEARCH_PARAMS reference rows.
-- Also serves _include / _revinclude / $everything traversal.
-- identifier_* columns support the :identifier modifier.

CREATE TABLE IF NOT EXISTS sp_reference (
    id                BIGSERIAL    PRIMARY KEY,
    resource_id       VARCHAR(64)  NOT NULL,
    resource_type     VARCHAR(100) NOT NULL,
    param_name        VARCHAR(191) NOT NULL,
    target_type       VARCHAR(100),
    target_id         VARCHAR(64),
    target_version_id INT,
    target_url        VARCHAR(512),
    identifier_system VARCHAR(512),
    identifier_value  VARCHAR(255),
    display           VARCHAR(255),
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_ref_source ON sp_reference (resource_type, resource_id, param_name);
CREATE INDEX IF NOT EXISTS idx_sp_ref_target ON sp_reference (target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_sp_ref_ident  ON sp_reference (target_type, identifier_system, identifier_value)
    WHERE identifier_value IS NOT NULL;

-- ─── Coordinates search index ─────────────────────────────────────────────────
-- Param type: special (Location.near).
-- For production deployments with heavy geospatial load, install PostGIS and
-- replace lat/lng columns with a geometry(Point,4326) column + GIST index.

CREATE TABLE IF NOT EXISTS sp_coords (
    id            BIGSERIAL    PRIMARY KEY,
    resource_id   VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    param_name    VARCHAR(191) NOT NULL,
    latitude      DECIMAL(9,6) NOT NULL,
    longitude     DECIMAL(9,6) NOT NULL,
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_coords ON sp_coords (resource_type, param_name, latitude, longitude);

-- ─── Search parameter definitions ────────────────────────────────────────────
-- Replaces SEARCH_PARAM_RES_EXPRESSIONS.
-- Populated at startup from embedded CSV (base FHIR R4) and IG packages.
-- ig_source values: '' = base FHIR R4 spec, 'user' = SearchParameter resource,
--                   'name@version' = from a specific IG package.

CREATE TABLE IF NOT EXISTS search_param_definitions (
    id            SERIAL       PRIMARY KEY,
    resource_type VARCHAR(191) NOT NULL,
    param_name    VARCHAR(191) NOT NULL,
    param_type    VARCHAR(32)  NOT NULL,
    fhirpath_expr TEXT         NOT NULL,
    is_custom     BOOLEAN      NOT NULL DEFAULT FALSE,
    ig_source     TEXT         NOT NULL DEFAULT '',
    UNIQUE (resource_type, param_name)
);

-- Idempotent migration: add ig_source to existing deployments
ALTER TABLE search_param_definitions ADD COLUMN IF NOT EXISTS ig_source TEXT NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_spd_resource ON search_param_definitions (resource_type);
CREATE INDEX IF NOT EXISTS idx_spd_custom   ON search_param_definitions (resource_type) WHERE is_custom = TRUE;
CREATE INDEX IF NOT EXISTS idx_spd_ig       ON search_param_definitions (ig_source) WHERE ig_source != '';

-- ─── Implementation Guide tracking ───────────────────────────────────────────
-- ig_packages: one row per loaded IG package; used to skip re-loading on restart.
-- ig_profiles: profiles declared by each IG (for capability statement).

CREATE TABLE IF NOT EXISTS ig_packages (
    id              SERIAL      PRIMARY KEY,
    package_name    TEXT        NOT NULL,
    package_version TEXT        NOT NULL,
    fhir_version    TEXT        NOT NULL DEFAULT '',
    loaded_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (package_name, package_version)
);

CREATE TABLE IF NOT EXISTS ig_profiles (
    id            SERIAL  PRIMARY KEY,
    package_name  TEXT    NOT NULL,
    profile_url   TEXT    NOT NULL,
    resource_type TEXT    NOT NULL DEFAULT '',
    sd_json       JSONB,
    UNIQUE (profile_url)
);

-- Idempotent migration: add sd_json to existing deployments.
ALTER TABLE ig_profiles ADD COLUMN IF NOT EXISTS sd_json JSONB;

-- ─── FHIR Terminology: closure tables ─────────────────────────────────────────
-- Unchanged from previous schema version.

CREATE TABLE IF NOT EXISTS "ClosureContextTable" (
    "ID"           SERIAL       PRIMARY KEY,
    "NAME"         VARCHAR(191) NOT NULL UNIQUE,
    "LAST_UPDATED" TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "ClosureConceptTable" (
    "ID"           SERIAL       PRIMARY KEY,
    "CONTEXT_ID"   INT          NOT NULL,
    "SYSTEM"       VARCHAR(512) NOT NULL,
    "CODE"         VARCHAR(191) NOT NULL,
    "LAST_UPDATED" TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    FOREIGN KEY ("CONTEXT_ID") REFERENCES "ClosureContextTable"("ID") ON DELETE CASCADE,
    UNIQUE ("CONTEXT_ID", "SYSTEM", "CODE")
);

CREATE INDEX IF NOT EXISTS idx_closure_concept ON "ClosureConceptTable" ("CONTEXT_ID", "SYSTEM", "CODE");

CREATE TABLE IF NOT EXISTS "ClosureDeltaTable" (
    "ID"           SERIAL       PRIMARY KEY,
    "CONTEXT_ID"   INT          NOT NULL,
    "SUBSUMES_ID"  INT          NOT NULL,
    "SUBSUMED_ID"  INT          NOT NULL,
    "LAST_UPDATED" TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    FOREIGN KEY ("CONTEXT_ID")  REFERENCES "ClosureContextTable"("ID")  ON DELETE CASCADE,
    FOREIGN KEY ("SUBSUMES_ID") REFERENCES "ClosureConceptTable"("ID")  ON DELETE CASCADE,
    FOREIGN KEY ("SUBSUMED_ID") REFERENCES "ClosureConceptTable"("ID")  ON DELETE CASCADE,
    UNIQUE ("CONTEXT_ID", "SUBSUMES_ID", "SUBSUMED_ID")
);

-- ─── Stamp schema version ─────────────────────────────────────────────────────

INSERT INTO schema_version (version) VALUES (3) ON CONFLICT DO NOTHING;

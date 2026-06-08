-- FHIR Server PostgreSQL Schema
-- One resources table holds all FHIR resource types. Separate sp_* tables
-- store extracted search parameter values so searches never touch resource_json.
-- Requires PostgreSQL 13+. For Location near-search, install PostGIS.

-- ─── Schema version ──────────────────────────────────────────────────────────
-- Tracks the schema revision applied to this database.

CREATE TABLE IF NOT EXISTS schema_version (
    version     INT         NOT NULL PRIMARY KEY,
    upgraded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Master resource table ────────────────────────────────────────────────────
-- Stores every FHIR resource. resource_json holds the full FHIR document.
-- search_text is a pre-built tsvector used for _text / _content full-text search.
-- No GIN index is created on resource_json because all searches go through the
-- sp_* tables; indexing the entire document would cost ~2.4x on writes with no
-- benefit to the query patterns used here.

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

-- List all resources of a type ordered by recency (used by GET /{type}).
CREATE INDEX IF NOT EXISTS idx_res_type_updated ON resources (resource_type, last_updated DESC);
-- Same as above but skips soft-deleted resources (used by most searches).
CREATE INDEX IF NOT EXISTS idx_res_active       ON resources (resource_type, last_updated DESC) WHERE is_deleted = FALSE;
-- Full-text search over search_text (_text / _content search parameters).
CREATE INDEX IF NOT EXISTS idx_res_search_text  ON resources USING GIN (search_text);

-- ─── Version history ──────────────────────────────────────────────────────────
-- Append-only log of every create, update, and delete. Each row is a full
-- snapshot of resource_json at that version, enabling vread and audit trails.

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

-- Fetch a specific version of a resource (GET /{type}/{id}/_history/{vid}).
CREATE INDEX IF NOT EXISTS idx_hist_resource  ON resource_history (resource_type, fhir_id, version_id DESC);
-- Global history feed ordered by time (GET /_history).
CREATE INDEX IF NOT EXISTS idx_hist_time      ON resource_history (recorded_at DESC);
-- History feed for a single resource type ordered by time (GET /{type}/_history).
CREATE INDEX IF NOT EXISTS idx_hist_type_time ON resource_history (resource_type, recorded_at DESC);

-- ─── String search index ─────────────────────────────────────────────────────
-- Stores extracted values for FHIR string search parameters (name, address, etc.).
-- value_exact keeps the original casing for the :exact modifier.
-- value_lower stores the downcased value for the default case-insensitive prefix match.

CREATE TABLE IF NOT EXISTS sp_string (
    id            BIGSERIAL    PRIMARY KEY,
    resource_id   VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    param_name    VARCHAR(191) NOT NULL,
    value_exact   VARCHAR(512),
    value_lower   VARCHAR(512),
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

-- text_pattern_ops is required for LIKE 'prefix%' to use a btree index under
-- non-C collations (e.g. en_US.utf8). Without it, prefix scans fall back to
-- a sequential scan. The operator class also serves equality lookups.
CREATE INDEX IF NOT EXISTS idx_sp_str_lower_pattern ON sp_string (resource_type, param_name, value_lower text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_sp_str_exact         ON sp_string (resource_type, param_name, value_exact);
-- Leading on resource_id serves multi-parameter searches (which join back to
-- the outer resource row) and per-resource deletes during re-indexing.
CREATE INDEX IF NOT EXISTS idx_sp_str_source        ON sp_string (resource_id, resource_type, param_name, value_lower);
-- Uncomment for :contains support (requires pg_trgm extension):
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX idx_sp_str_trgm ON sp_string USING GIN (value_lower gin_trgm_ops);

-- ─── Token search index ───────────────────────────────────────────────────────
-- Stores extracted values for FHIR token search parameters
-- (CodeableConcept, Coding, Identifier, code, boolean).
-- display is stored to support the :text modifier (match on the human label).

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

-- Primary lookup: system|code pairs (the most common token search pattern).
CREATE INDEX IF NOT EXISTS idx_sp_tok_sys_code ON sp_token (resource_type, param_name, system, code);
-- Lookup by system alone (used when only the system is provided, no code).
CREATE INDEX IF NOT EXISTS idx_sp_tok_system ON sp_token (resource_type, param_name, system);
-- Lookup by code alone when the search omits system.
CREATE INDEX IF NOT EXISTS idx_sp_tok_code ON sp_token (resource_type, param_name, code) WHERE code IS NOT NULL;
-- Leading on resource_id serves multi-parameter searches and re-index deletes.
CREATE INDEX IF NOT EXISTS idx_sp_tok_source ON sp_token (resource_id, resource_type, param_name, system, code);

-- ─── Date search index ────────────────────────────────────────────────────────
-- Stores extracted values for FHIR date / dateTime / Period / instant parameters.
-- Partial-precision dates (e.g. "2000", "2000-04") are expanded into a
-- [value_low, value_high] range at write time so all 8 FHIR date comparators
-- (eq, ne, lt, gt, le, ge, sa, eb) work correctly without special casing.
-- value_precision records the original granularity (YEAR|MONTH|DAY|SECOND).

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

CREATE INDEX IF NOT EXISTS idx_sp_date_range  ON sp_date (resource_type, param_name, value_low, value_high);
CREATE INDEX IF NOT EXISTS idx_sp_date_source ON sp_date (resource_id, resource_type, param_name, value_low, value_high);

-- ─── Number search index ──────────────────────────────────────────────────────
-- Stores extracted values for FHIR number search parameters.
-- value_low / value_high encode the implicit precision range around value so
-- that FHIR's "approximately equal" (eq) semantics work: e.g. searching for
-- 100 matches 100.4 but not 100.5.

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

CREATE INDEX IF NOT EXISTS idx_sp_num_range  ON sp_number (resource_type, param_name, value_low, value_high);
CREATE INDEX IF NOT EXISTS idx_sp_num_source ON sp_number (resource_id, resource_type, param_name, value_low, value_high);

-- ─── Quantity search index ────────────────────────────────────────────────────
-- Stores extracted values for FHIR quantity search parameters.
-- value / value_low / value_high hold the raw value with its precision range.
-- canonical_value / canonical_units hold the UCUM-normalised equivalent so
-- that cross-unit comparisons work (e.g. searching "1g" matches "1000mg").

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

-- Raw value range search (same system+code, no unit conversion needed).
CREATE INDEX IF NOT EXISTS idx_sp_qty_raw       ON sp_quantity (resource_type, param_name, value_low, value_high, system, code);
CREATE INDEX IF NOT EXISTS idx_sp_qty_source    ON sp_quantity (resource_id, resource_type, param_name);
-- Canonical search (cross-unit comparison via UCUM normalisation).
CREATE INDEX IF NOT EXISTS idx_sp_qty_canonical ON sp_quantity (resource_type, param_name, canonical_value, canonical_units)
    WHERE canonical_value IS NOT NULL;

-- ─── URI search index ─────────────────────────────────────────────────────────
-- Stores extracted values for FHIR uri search parameters (url, profile, etc.).
-- Supports exact match and the :below modifier (prefix / hierarchy match).

CREATE TABLE IF NOT EXISTS sp_uri (
    id            BIGSERIAL    PRIMARY KEY,
    resource_id   VARCHAR(64)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    param_name    VARCHAR(191) NOT NULL,
    value         VARCHAR(512) NOT NULL,
    FOREIGN KEY (resource_id, resource_type) REFERENCES resources (fhir_id, resource_type) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_uri_exact  ON sp_uri (resource_type, param_name, value);
-- text_pattern_ops enables efficient LIKE 'prefix%' for the :below modifier.
CREATE INDEX IF NOT EXISTS idx_sp_uri_prefix ON sp_uri (resource_type, param_name, value text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_sp_uri_source ON sp_uri (resource_id, resource_type, param_name, value);

-- ─── Reference search index ───────────────────────────────────────────────────
-- Stores extracted values for FHIR reference search parameters.
-- Also used for _include / _revinclude and $everything traversal.
-- target_url holds the literal URL when the reference is external (not local).
-- identifier_* columns support the :identifier modifier (search by Identifier
-- instead of resource id).

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

-- Used when searching by source: multi-param searches join back to the outer
-- resource row by resource_id; including target_id avoids a post-scan filter.
CREATE INDEX IF NOT EXISTS idx_sp_ref_source      ON sp_reference (resource_id, resource_type, param_name, target_id);
-- Used when searching by target (e.g. ?patient=123): leading on target_id
-- serves bare-id lookups; extra columns allow the predicate to resolve index-only.
CREATE INDEX IF NOT EXISTS idx_sp_ref_target_full ON sp_reference (target_id, target_type, param_name, resource_type, resource_id);
-- Used for the :identifier modifier (find references by Identifier value).
CREATE INDEX IF NOT EXISTS idx_sp_ref_ident       ON sp_reference (target_type, identifier_system, identifier_value)
    WHERE identifier_value IS NOT NULL;

-- ─── Coordinates search index ─────────────────────────────────────────────────
-- Stores lat/lng for the Location.near search parameter.
-- For heavy geospatial workloads, consider replacing lat/lng with a
-- PostGIS geometry(Point,4326) column and a GIST index.

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
-- Registry of all known search parameters for each resource type.
-- Populated at server startup from the embedded FHIR R4 base spec (CSV) and
-- any loaded Implementation Guide packages.
-- ig_source: '' = base FHIR R4, 'user' = custom SearchParameter resource,
--            'name@version' = sourced from a specific IG package.
-- components_json: composite search parameter component expressions (JSON array).

CREATE TABLE IF NOT EXISTS search_param_definitions (
    id               SERIAL       PRIMARY KEY,
    resource_type    VARCHAR(191) NOT NULL,
    param_name       VARCHAR(191) NOT NULL,
    param_type       VARCHAR(32)  NOT NULL,
    fhirpath_expr    TEXT         NOT NULL,
    is_custom        BOOLEAN      NOT NULL DEFAULT FALSE,
    ig_source        TEXT         NOT NULL DEFAULT '',
    target_types     TEXT         NOT NULL DEFAULT '',
    components_json  TEXT         NOT NULL DEFAULT '',
    UNIQUE (resource_type, param_name)
);

CREATE INDEX IF NOT EXISTS idx_spd_resource ON search_param_definitions (resource_type);
CREATE INDEX IF NOT EXISTS idx_spd_custom   ON search_param_definitions (resource_type) WHERE is_custom = TRUE;
CREATE INDEX IF NOT EXISTS idx_spd_ig       ON search_param_definitions (ig_source) WHERE ig_source != '';

-- ─── Implementation Guide tracking ───────────────────────────────────────────
-- ig_packages records each loaded IG package so the server can skip re-downloading
-- it on restart. ig_profiles stores the StructureDefinition profiles declared by
-- each IG, used when building the CapabilityStatement.

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

-- ─── FHIR Terminology: closure tables ─────────────────────────────────────────
-- Support the $closure operation, which maintains a transitive closure table of
-- subsumption relationships between coded concepts. A closure context groups
-- related concepts; ClosureDeltaTable records each subsumes/subsumed-by pair.

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

-- ─── Planner statistics ───────────────────────────────────────────────────────
-- Raise statistics targets for high-cardinality columns so the planner
-- produces accurate row-count estimates for multi-param searches.
ALTER TABLE sp_token     ALTER COLUMN code          SET STATISTICS 1000;
ALTER TABLE sp_token     ALTER COLUMN system        SET STATISTICS 1000;
ALTER TABLE sp_token     ALTER COLUMN resource_type SET STATISTICS 1000;
ALTER TABLE sp_token     ALTER COLUMN param_name    SET STATISTICS 1000;
ALTER TABLE sp_reference ALTER COLUMN target_id     SET STATISTICS 1000;
ALTER TABLE sp_reference ALTER COLUMN param_name    SET STATISTICS 1000;

-- ─── Stamp schema version ─────────────────────────────────────────────────────

INSERT INTO schema_version (version) VALUES (3) ON CONFLICT DO NOTHING;

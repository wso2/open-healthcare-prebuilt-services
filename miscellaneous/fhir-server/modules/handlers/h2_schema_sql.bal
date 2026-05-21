// Embedded H2 schema SQL for auto-initialization when the filesystem schema file
// is not available (e.g., some Docker deployments).
// Mirrors scripts/schema-h2.sql — keep both in sync when changing schema.
final string H2_SCHEMA_SQL = string `
-- FHIR Server H2 Schema (v3)

CREATE TABLE IF NOT EXISTS "schema_version" (
    "version"     INT       NOT NULL PRIMARY KEY,
    "upgraded_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "resources" (
    "fhir_id"       VARCHAR(64)  NOT NULL,
    "resource_type" VARCHAR(100) NOT NULL,
    "version_id"    INT          NOT NULL DEFAULT 1,
    "last_updated"  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "is_deleted"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "resource_json" CLOB         NOT NULL,
    PRIMARY KEY ("fhir_id", "resource_type")
);

CREATE INDEX IF NOT EXISTS idx_res_type_updated ON "resources" ("resource_type", "last_updated" DESC);

CREATE TABLE IF NOT EXISTS "resource_history" (
    "id"            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"   VARCHAR(64)  NOT NULL,
    "resource_type" VARCHAR(100) NOT NULL,
    "version_id"    INT          NOT NULL,
    "operation"     VARCHAR(10)  NOT NULL,
    "recorded_at"   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resource_json" CLOB,
    UNIQUE ("resource_id", "resource_type", "version_id")
);

CREATE INDEX IF NOT EXISTS idx_hist_resource ON "resource_history" ("resource_type", "resource_id", "version_id" DESC);

CREATE TABLE IF NOT EXISTS "sp_string" (
    "id"            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"   VARCHAR(64)  NOT NULL,
    "resource_type" VARCHAR(100) NOT NULL,
    "param_name"    VARCHAR(191) NOT NULL,
    "value_exact"   VARCHAR(512),
    "value_lower"   VARCHAR(512),
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_str_lower ON "sp_string" ("resource_type", "param_name", "value_lower");
CREATE INDEX IF NOT EXISTS idx_sp_str_exact ON "sp_string" ("resource_type", "param_name", "value_exact");

CREATE TABLE IF NOT EXISTS "sp_token" (
    "id"            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"   VARCHAR(64)  NOT NULL,
    "resource_type" VARCHAR(100) NOT NULL,
    "param_name"    VARCHAR(191) NOT NULL,
    "system"        VARCHAR(512),
    "code"          VARCHAR(191),
    "display"       VARCHAR(512),
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_tok_sys_code ON "sp_token" ("resource_type", "param_name", "system", "code");
CREATE INDEX IF NOT EXISTS idx_sp_tok_code     ON "sp_token" ("resource_type", "param_name", "code");

CREATE TABLE IF NOT EXISTS "sp_date" (
    "id"              BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"     VARCHAR(64)  NOT NULL,
    "resource_type"   VARCHAR(100) NOT NULL,
    "param_name"      VARCHAR(191) NOT NULL,
    "value_low"       TIMESTAMP    NOT NULL,
    "value_high"      TIMESTAMP    NOT NULL,
    "value_precision" VARCHAR(10)  NOT NULL DEFAULT 'SECOND',
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_date_range ON "sp_date" ("resource_type", "param_name", "value_low", "value_high");

CREATE TABLE IF NOT EXISTS "sp_number" (
    "id"            BIGINT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"   VARCHAR(64)   NOT NULL,
    "resource_type" VARCHAR(100)  NOT NULL,
    "param_name"    VARCHAR(191)  NOT NULL,
    "value"         DECIMAL(20,6) NOT NULL,
    "value_low"     DECIMAL(20,6) NOT NULL,
    "value_high"    DECIMAL(20,6) NOT NULL,
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_num_range ON "sp_number" ("resource_type", "param_name", "value_low", "value_high");

CREATE TABLE IF NOT EXISTS "sp_quantity" (
    "id"               BIGINT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"      VARCHAR(64)   NOT NULL,
    "resource_type"    VARCHAR(100)  NOT NULL,
    "param_name"       VARCHAR(191)  NOT NULL,
    "value"            DECIMAL(20,6) NOT NULL,
    "value_low"        DECIMAL(20,6) NOT NULL,
    "value_high"       DECIMAL(20,6) NOT NULL,
    "system"           VARCHAR(255),
    "code"             VARCHAR(64),
    "canonical_value"  DECIMAL(20,6),
    "canonical_units"  VARCHAR(64),
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_qty_raw ON "sp_quantity" ("resource_type", "param_name", "value_low", "value_high", "system", "code");

CREATE TABLE IF NOT EXISTS "sp_uri" (
    "id"            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"   VARCHAR(64)  NOT NULL,
    "resource_type" VARCHAR(100) NOT NULL,
    "param_name"    VARCHAR(191) NOT NULL,
    "value"         VARCHAR(512) NOT NULL,
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_uri_exact ON "sp_uri" ("resource_type", "param_name", "value");

CREATE TABLE IF NOT EXISTS "sp_reference" (
    "id"                BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"       VARCHAR(64)  NOT NULL,
    "resource_type"     VARCHAR(100) NOT NULL,
    "param_name"        VARCHAR(191) NOT NULL,
    "target_type"       VARCHAR(100),
    "target_id"         VARCHAR(64),
    "target_version_id" INT,
    "target_url"        VARCHAR(512),
    "identifier_system" VARCHAR(512),
    "identifier_value"  VARCHAR(255),
    "display"           VARCHAR(255),
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_ref_source ON "sp_reference" ("resource_type", "resource_id", "param_name");
CREATE INDEX IF NOT EXISTS idx_sp_ref_target ON "sp_reference" ("target_type", "target_id");

CREATE TABLE IF NOT EXISTS "sp_coords" (
    "id"            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_id"   VARCHAR(64)  NOT NULL,
    "resource_type" VARCHAR(100) NOT NULL,
    "param_name"    VARCHAR(191) NOT NULL,
    "latitude"      DECIMAL(9,6) NOT NULL,
    "longitude"     DECIMAL(9,6) NOT NULL,
    FOREIGN KEY ("resource_id", "resource_type") REFERENCES "resources" ("fhir_id", "resource_type") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sp_coords ON "sp_coords" ("resource_type", "param_name", "latitude", "longitude");

CREATE TABLE IF NOT EXISTS "search_param_definitions" (
    "id"            INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "resource_type" VARCHAR(191) NOT NULL,
    "param_name"    VARCHAR(191) NOT NULL,
    "param_type"    VARCHAR(32)  NOT NULL,
    "fhirpath_expr" CLOB         NOT NULL,
    "is_custom"     BOOLEAN      NOT NULL DEFAULT FALSE,
    UNIQUE ("resource_type", "param_name")
);

CREATE INDEX IF NOT EXISTS idx_spd_resource ON "search_param_definitions" ("resource_type");

CREATE TABLE IF NOT EXISTS "ClosureContextTable" (
    "ID"           INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "NAME"         VARCHAR(191) NOT NULL UNIQUE,
    "LAST_UPDATED" TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "ClosureConceptTable" (
    "ID"           INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "CONTEXT_ID"   INT          NOT NULL,
    "SYSTEM"       VARCHAR(512) NOT NULL,
    "CODE"         VARCHAR(191) NOT NULL,
    "LAST_UPDATED" TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("CONTEXT_ID") REFERENCES "ClosureContextTable"("ID") ON DELETE CASCADE,
    UNIQUE ("CONTEXT_ID", "SYSTEM", "CODE")
);

CREATE INDEX IF NOT EXISTS idx_closure_concept ON "ClosureConceptTable" ("CONTEXT_ID", "SYSTEM", "CODE");

CREATE TABLE IF NOT EXISTS "ClosureDeltaTable" (
    "ID"           INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    "CONTEXT_ID"   INT          NOT NULL,
    "SUBSUMES_ID"  INT          NOT NULL,
    "SUBSUMED_ID"  INT          NOT NULL,
    "LAST_UPDATED" TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("CONTEXT_ID")  REFERENCES "ClosureContextTable"("ID")  ON DELETE CASCADE,
    FOREIGN KEY ("SUBSUMES_ID") REFERENCES "ClosureConceptTable"("ID")  ON DELETE CASCADE,
    FOREIGN KEY ("SUBSUMED_ID") REFERENCES "ClosureConceptTable"("ID")  ON DELETE CASCADE,
    UNIQUE ("CONTEXT_ID", "SUBSUMES_ID", "SUBSUMED_ID")
);
`;

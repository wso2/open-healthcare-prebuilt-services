-- PostgreSQL schema test, run against a database initialized with modules/store_pg/script.sql:
--   psql -v ON_ERROR_STOP=1 -d <db> -f modules/store_pg/script.sql -f tests/postgresql/schema_test.sql
-- Fails (non-zero exit) if any check fails.

BEGIN;

INSERT INTO "codesystems" ("id", "url", "version", "name", "title", "status", "date", "publisher", "codeSystem")
VALUES ('schema-test', 'http://example.org/schema-test', '1', 'SchemaTest', 'Schema test', 'active', '', '', '\x00');

-- Concept display and definition far beyond the old VARCHAR(191) and the ~2.7 KB B-tree index row
-- limit. md5 hex is high-entropy, so TOAST compression cannot shrink it below that limit.
INSERT INTO "concepts" ("code", "display", "definition", "concept", "codesystemCodeSystemId")
SELECT 'long-text',
       string_agg(md5('display' || i), ''),
       string_agg(md5('definition' || i), ''),
       '\x00',
       (SELECT "codeSystemId" FROM "codesystems" WHERE "id" = 'schema-test')
FROM generate_series(1, 250) AS i;

DO $$
DECLARE
    stored_display_length int;
BEGIN
    SELECT length("display") INTO stored_display_length FROM "concepts" WHERE "code" = 'long-text';
    IF stored_display_length IS DISTINCT FROM 8000 THEN
        RAISE EXCEPTION 'long concept display not stored intact (length %)', stored_display_length;
    END IF;

    -- The service's display search shape must still find it.
    IF NOT EXISTS (SELECT 1 FROM "concepts" WHERE UPPER("display") LIKE '%' || UPPER(md5('display1')) || '%') THEN
        RAISE EXCEPTION 'display substring search did not find the long display';
    END IF;
END $$;

ROLLBACK;

\echo 'PostgreSQL schema test passed'

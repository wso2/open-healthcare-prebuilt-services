-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "conceptmaps";
DROP TABLE IF EXISTS "closure_table_pairs";
DROP TABLE IF EXISTS "closure_table_concepts";
DROP TABLE IF EXISTS "closure_tables";
DROP TABLE IF EXISTS "concept_relationships";
DROP TABLE IF EXISTS "concept_closure";
DROP TABLE IF EXISTS "valueset_compose_include_value_sets";
DROP TABLE IF EXISTS "valueset_compose_include_concepts";
DROP TABLE IF EXISTS "valueset_compose_includes";
DROP TABLE IF EXISTS "concepts";
DROP TABLE IF EXISTS "valuesets";
DROP TABLE IF EXISTS "codesystems";

CREATE TABLE "codesystems" (
	"codeSystemId"  SERIAL,
	"id" VARCHAR(191) NOT NULL,
	"url" VARCHAR(191) NOT NULL,
	"version" VARCHAR(191) NOT NULL,
	"name" VARCHAR(191) NOT NULL,
	"title" VARCHAR(191) NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	"date" VARCHAR(191) NOT NULL,
	"publisher" VARCHAR(191) NOT NULL,
	"codeSystem" BLOB NOT NULL,
	PRIMARY KEY("codeSystemId")
);

CREATE TABLE "valuesets" (
	"valueSetId"  SERIAL,
	"id" VARCHAR(191) NOT NULL,
	"url" VARCHAR(191) NOT NULL,
	"version" VARCHAR(191) NOT NULL,
	"name" VARCHAR(191) NOT NULL,
	"title" VARCHAR(191) NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	"date" VARCHAR(191) NOT NULL,
	"publisher" VARCHAR(191) NOT NULL,
	"valueSet" BLOB NOT NULL,
	PRIMARY KEY("valueSetId")
);

CREATE TABLE "concepts" (
	"conceptId"  SERIAL,
	"code" VARCHAR(191) NOT NULL,
	"display" VARCHAR(191),
	"definition" VARCHAR(191),
	"concept" BYTEA NOT NULL,
	"parentConceptId" INT,
	"codesystemCodeSystemId" INT NOT NULL,
	FOREIGN KEY("codesystemCodeSystemId") REFERENCES "codesystems"("codeSystemId"),
	PRIMARY KEY("conceptId")
);

CREATE TABLE "valueset_compose_includes" (
	"valueSetComposeIncludeId"  SERIAL,
	"systemFlag" BOOLEAN NOT NULL,
	"valueSetFlag" BOOLEAN NOT NULL,
	"conceptFlag" BOOLEAN NOT NULL,
	"codeSystemId" INT,
	"valuesetValueSetId" INT NOT NULL,
	FOREIGN KEY("valuesetValueSetId") REFERENCES "valuesets"("valueSetId"),
	PRIMARY KEY("valueSetComposeIncludeId")
);

CREATE TABLE "valueset_compose_include_concepts" (
	"valueSetComposeIncludeConceptId"  SERIAL,
	"valuesetcomposeValueSetComposeIncludeId" INT NOT NULL,
	FOREIGN KEY("valuesetcomposeValueSetComposeIncludeId") REFERENCES "valueset_compose_includes"("valueSetComposeIncludeId"),
	"conceptConceptId" INT NOT NULL,
	FOREIGN KEY("conceptConceptId") REFERENCES "concepts"("conceptId"),
	PRIMARY KEY("valueSetComposeIncludeConceptId")
);


CREATE TABLE "valueset_compose_include_value_sets" (
	"valueSetComposeIncludeValueSetId"  SERIAL,
	"valuesetcomposeValueSetComposeIncludeId" INT NOT NULL,
	FOREIGN KEY("valuesetcomposeValueSetComposeIncludeId") REFERENCES "valueset_compose_includes"("valueSetComposeIncludeId"),
	"valuesetValueSetId" INT NOT NULL,
	FOREIGN KEY("valuesetValueSetId") REFERENCES "valuesets"("valueSetId"),
	PRIMARY KEY("valueSetComposeIncludeValueSetId")
);

-- SNOMED CT transitive is-a closure. Managed via native SQL (executeNativeSQL /
-- queryNativeSQL), NOT through the generated persist client, so it has no entry
-- in persist_types.bal / persist_client.bal.
CREATE TABLE "concept_closure" (
	"closureId"  SERIAL,
	"ancestorConceptId" INT NOT NULL,
	"descendantConceptId" INT NOT NULL,
	"depth" INT NOT NULL,
	"codeSystemId" INT NOT NULL,
	PRIMARY KEY("closureId")
);

-- SNOMED CT non-is-a clinical attribute relationships (Finding site, Associated
-- morphology, etc), from Relationship rows where typeId != 116680003. Managed
-- via native SQL, NOT through the generated persist client, so it has no entry
-- in persist_types.bal / persist_client.bal.
CREATE TABLE "concept_relationships" (
	"relationshipId"  SERIAL,
	"sourceConceptId" INT NOT NULL,
	"typeId" VARCHAR(191) NOT NULL,
	"destinationConceptId" INT NOT NULL,
	"codeSystemId" INT NOT NULL,
	PRIMARY KEY("relationshipId")
);

-- $closure operation state: a client-named closure table (ConceptMap/$closure),
-- the concepts added to it, and the subsumption pairs already reported for it
-- (stamped with the response version they were reported in, so a client can
-- resync via the version input parameter instead of just "since last call").
CREATE TABLE "closure_tables" (
	"closureTableId" SERIAL,
	"name" VARCHAR(191) NOT NULL,
	"currentVersion" INT NOT NULL DEFAULT 0,
	PRIMARY KEY("closureTableId")
);

CREATE TABLE "closure_table_concepts" (
	"closureTableConceptId" SERIAL,
	"closureTableId" INT NOT NULL,
	"conceptId" INT NOT NULL,
	PRIMARY KEY("closureTableConceptId")
);

CREATE TABLE "closure_table_pairs" (
	"closureTablePairId" SERIAL,
	"closureTableId" INT NOT NULL,
	"ancestorConceptId" INT NOT NULL,
	"descendantConceptId" INT NOT NULL,
	"reportedAtVersion" INT NOT NULL,
	PRIMARY KEY("closureTablePairId")
);

-- ConceptMap resources, backing $translate. Managed via native SQL rather than
-- the generated persist client (like concept_closure/concept_relationships/
-- closure_tables above), to avoid regenerating persist/model.bal - which would
-- risk stripping those hand-added tables back out. sourceUri/targetUri are the
-- ConceptMap's resource-level source/target ValueSet scope (ConceptMap.sourceUri/
-- targetUri), queried by findConceptMaps; the actual code-level mappings live in
-- the stored resource's group[].element[], read by the terminology library's
-- own $translate implementation once a matching ConceptMap is found.
CREATE TABLE "conceptmaps" (
	"conceptMapId" SERIAL,
	"id" VARCHAR(191) NOT NULL,
	"url" VARCHAR(191),
	"version" VARCHAR(191),
	"name" VARCHAR(191),
	"title" VARCHAR(191),
	"status" VARCHAR(191) NOT NULL,
	"sourceUri" VARCHAR(191),
	"targetUri" VARCHAR(191),
	"conceptMap" BLOB NOT NULL,
	PRIMARY KEY("conceptMapId")
);

-- CodeSystem/$lookup, CodeSystem/$subsumes, CodeSystem read-by-id, CodeSystem search
CREATE INDEX "idx_codesystems_id" ON "codesystems"("id");
CREATE INDEX "idx_codesystems_url" ON "codesystems"("url");
CREATE INDEX "idx_codesystems_url_version" ON "codesystems"("url", "version");
CREATE INDEX "idx_codesystems_status" ON "codesystems"("status");
CREATE INDEX "idx_codesystems_name" ON "codesystems"("name");

-- ValueSet/$expand, ValueSet/$validate-code, ValueSet read-by-id, ValueSet search
CREATE INDEX "idx_valuesets_id" ON "valuesets"("id");
CREATE INDEX "idx_valuesets_url" ON "valuesets"("url");
CREATE INDEX "idx_valuesets_url_version" ON "valuesets"("url", "version");
CREATE INDEX "idx_valuesets_status" ON "valuesets"("status");
CREATE INDEX "idx_valuesets_name" ON "valuesets"("name");

-- $lookup, $validate-code, $find-code, $subsumes hierarchy traversal
CREATE INDEX "idx_concepts_codesystem_id" ON "concepts"("codesystemCodeSystemId");
CREATE INDEX "idx_concepts_code" ON "concepts"("code");
CREATE INDEX "idx_concepts_codesystem_code" ON "concepts"("codesystemCodeSystemId", "code");
CREATE INDEX "idx_concepts_parent" ON "concepts"("parentConceptId");
CREATE INDEX "idx_concepts_display" ON "concepts"("display");

-- ValueSet/$expand: compose include traversal
CREATE INDEX "idx_vci_valueset_id" ON "valueset_compose_includes"("valuesetValueSetId");
CREATE INDEX "idx_vci_codesystem_id" ON "valueset_compose_includes"("codeSystemId");

-- Join tables for $expand
CREATE INDEX "idx_vcic_compose_id" ON "valueset_compose_include_concepts"("valuesetcomposeValueSetComposeIncludeId");
CREATE INDEX "idx_vcic_concept_id" ON "valueset_compose_include_concepts"("conceptConceptId");
CREATE INDEX "idx_vcivs_compose_id" ON "valueset_compose_include_value_sets"("valuesetcomposeValueSetComposeIncludeId");
CREATE INDEX "idx_vcivs_valueset_id" ON "valueset_compose_include_value_sets"("valuesetValueSetId");

-- CodeSystem/$subsumes and hierarchy-based ValueSet/$expand over the SNOMED closure
CREATE INDEX "idx_closure_ancestor" ON "concept_closure"("codeSystemId", "ancestorConceptId");
CREATE INDEX "idx_closure_descendant" ON "concept_closure"("codeSystemId", "descendantConceptId");
CREATE INDEX "idx_closure_pair" ON "concept_closure"("ancestorConceptId", "descendantConceptId");

-- CodeSystem/$lookup attribute relationship projection
CREATE INDEX "idx_relationships_source" ON "concept_relationships"("codeSystemId", "sourceConceptId");

-- $closure lookup/dedup/resync
CREATE UNIQUE INDEX "idx_closure_tables_name" ON "closure_tables"("name");
CREATE UNIQUE INDEX "idx_closure_table_concepts_unique" ON "closure_table_concepts"("closureTableId", "conceptId");
CREATE UNIQUE INDEX "idx_closure_table_pairs_unique" ON "closure_table_pairs"("closureTableId", "ancestorConceptId", "descendantConceptId");
CREATE INDEX "idx_closure_table_pairs_version" ON "closure_table_pairs"("closureTableId", "reportedAtVersion");

-- $translate: findConceptMaps looks up by resource-level source/target scope.
-- Unique on (url, version) so concurrent addConceptMap calls can't both pass
-- terminology:addConceptMap's duplicate check and insert two rows for the
-- same identity - storeConceptMap maps the resulting constraint violation to
-- r4:PROCESSING_DUPLICATE.
CREATE INDEX "idx_conceptmaps_id" ON "conceptmaps"("id");
CREATE INDEX "idx_conceptmaps_url" ON "conceptmaps"("url");
CREATE UNIQUE INDEX "idx_conceptmaps_url_version" ON "conceptmaps"("url", "version");
CREATE INDEX "idx_conceptmaps_source" ON "conceptmaps"("sourceUri");
CREATE INDEX "idx_conceptmaps_source_target" ON "conceptmaps"("sourceUri", "targetUri");


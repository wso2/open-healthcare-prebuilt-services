// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// Sets up the tables that are managed via native SQL (executeNativeSQL) rather
// than the generated persist client, and so have no entry in persist_test_init.bal
// (which is auto-generated from persist/model.bal and only creates the
// persist-modeled tables). Mirrors modules/store_h2/script.sql, which creates
// these same tables for the real dev/prod H2 instance via the INIT=RUNSCRIPT
// connection option.
public isolated function setupNativeSqlTestTables() returns error? {
    H2Client testClient = check new ("jdbc:h2:./tests/test", "sa", "");
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "conceptmaps"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "closure_table_pairs"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "closure_table_concepts"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "closure_tables"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "concept_relationships"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "concept_closure"`);
    _ = check testClient->executeNativeSQL(`
CREATE TABLE "concept_closure" (
	"closureId" SERIAL,
	"ancestorConceptId" INT NOT NULL,
	"descendantConceptId" INT NOT NULL,
	"depth" INT NOT NULL,
	"codeSystemId" INT NOT NULL,
	PRIMARY KEY("closureId")
);`);
    _ = check testClient->executeNativeSQL(`
CREATE TABLE "concept_relationships" (
	"relationshipId" SERIAL,
	"sourceConceptId" INT NOT NULL,
	"typeId" VARCHAR(191) NOT NULL,
	"destinationConceptId" INT NOT NULL,
	"codeSystemId" INT NOT NULL,
	PRIMARY KEY("relationshipId")
);`);
    _ = check testClient->executeNativeSQL(`
CREATE TABLE "closure_tables" (
	"closureTableId" SERIAL,
	"name" VARCHAR(191) NOT NULL,
	"currentVersion" INT NOT NULL DEFAULT 0,
	PRIMARY KEY("closureTableId")
);`);
    _ = check testClient->executeNativeSQL(`
CREATE TABLE "closure_table_concepts" (
	"closureTableConceptId" SERIAL,
	"closureTableId" INT NOT NULL,
	"conceptId" INT NOT NULL,
	PRIMARY KEY("closureTableConceptId")
);`);
    _ = check testClient->executeNativeSQL(`
CREATE TABLE "closure_table_pairs" (
	"closureTablePairId" SERIAL,
	"closureTableId" INT NOT NULL,
	"ancestorConceptId" INT NOT NULL,
	"descendantConceptId" INT NOT NULL,
	"reportedAtVersion" INT NOT NULL,
	PRIMARY KEY("closureTablePairId")
);`);
    _ = check testClient->executeNativeSQL(`
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
);`);
    // These unique indexes exist on the real dev/prod schema (script.sql) but
    // were missing here, so tests couldn't exercise the constraints they
    // enforce (e.g. closureTransactionRollsBackOnFailure in tests/closure_test.bal).
    _ = check testClient->executeNativeSQL(`CREATE UNIQUE INDEX "idx_closure_tables_name" ON "closure_tables"("name")`);
    _ = check testClient->executeNativeSQL(`CREATE UNIQUE INDEX "idx_closure_table_concepts_unique" ON "closure_table_concepts"("closureTableId", "conceptId")`);
    _ = check testClient->executeNativeSQL(`CREATE UNIQUE INDEX "idx_closure_table_pairs_unique" ON "closure_table_pairs"("closureTableId", "ancestorConceptId", "descendantConceptId")`);
    _ = check testClient->executeNativeSQL(`CREATE UNIQUE INDEX "idx_conceptmaps_url_version" ON "conceptmaps"("url", "version")`);
    check testClient.close();
}

public isolated function cleanupNativeSqlTestTables() returns error? {
    H2Client testClient = check new ("jdbc:h2:./tests/test", "sa", "");
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "conceptmaps"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "closure_table_pairs"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "closure_table_concepts"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "closure_tables"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "concept_relationships"`);
    _ = check testClient->executeNativeSQL(`DROP TABLE IF EXISTS "concept_closure"`);
    check testClient.close();
}


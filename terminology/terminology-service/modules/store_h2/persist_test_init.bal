// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer.
// It should not be modified by hand.

import ballerina/persist;

isolated final H2Client h2Client = check new ("jdbc:h2:./tests/test", "sa", "");

public isolated function setupTestDB() returns persist:Error? {
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valueset_compose_include_value_sets";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valueset_compose_include_concepts";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valueset_compose_includes";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "concepts";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valuesets";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "codesystems";`);
    _ = check h2Client->executeNativeSQL(`
CREATE TABLE "codesystems" (
	"codeSystemId" INT AUTO_INCREMENT,
	"id" VARCHAR(191) NOT NULL,
	"url" VARCHAR(191) NOT NULL,
	"version" VARCHAR(191) NOT NULL,
	"name" VARCHAR(191) NOT NULL,
	"title" VARCHAR(191) NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	"date" VARCHAR(191) NOT NULL,
	"publisher" VARCHAR(191) NOT NULL,
	"codeSystem" LONGBLOB NOT NULL,
	PRIMARY KEY("codeSystemId")
);`);
    _ = check h2Client->executeNativeSQL(`
CREATE TABLE "valuesets" (
	"valueSetId" INT AUTO_INCREMENT,
	"id" VARCHAR(191) NOT NULL,
	"url" VARCHAR(191) NOT NULL,
	"version" VARCHAR(191) NOT NULL,
	"name" VARCHAR(191) NOT NULL,
	"title" VARCHAR(191) NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	"date" VARCHAR(191) NOT NULL,
	"publisher" VARCHAR(191) NOT NULL,
	"valueSet" LONGBLOB NOT NULL,
	PRIMARY KEY("valueSetId")
);`);
    _ = check h2Client->executeNativeSQL(`
CREATE TABLE "concepts" (
	"conceptId" INT AUTO_INCREMENT,
	"code" VARCHAR(191) NOT NULL,
	"display" VARCHAR(191),
	"definition" VARCHAR(191),
	"concept" LONGBLOB NOT NULL,
	"parentConceptId" INT,
	"codesystemCodeSystemId" INT NOT NULL,
	FOREIGN KEY("codesystemCodeSystemId") REFERENCES "codesystems"("codeSystemId"),
	PRIMARY KEY("conceptId")
);`);
    _ = check h2Client->executeNativeSQL(`
CREATE TABLE "valueset_compose_includes" (
	"valueSetComposeIncludeId" INT AUTO_INCREMENT,
	"systemFlag" BOOLEAN NOT NULL,
	"valueSetFlag" BOOLEAN NOT NULL,
	"conceptFlag" BOOLEAN NOT NULL,
	"codeSystemId" INT,
	"valuesetValueSetId" INT NOT NULL,
	FOREIGN KEY("valuesetValueSetId") REFERENCES "valuesets"("valueSetId"),
	PRIMARY KEY("valueSetComposeIncludeId")
);`);
    _ = check h2Client->executeNativeSQL(`
CREATE TABLE "valueset_compose_include_concepts" (
	"valueSetComposeIncludeConceptId" INT AUTO_INCREMENT,
	"valuesetcomposeValueSetComposeIncludeId" INT NOT NULL,
	FOREIGN KEY("valuesetcomposeValueSetComposeIncludeId") REFERENCES "valueset_compose_includes"("valueSetComposeIncludeId"),
	"conceptConceptId" INT NOT NULL,
	FOREIGN KEY("conceptConceptId") REFERENCES "concepts"("conceptId"),
	PRIMARY KEY("valueSetComposeIncludeConceptId")
);`);
    _ = check h2Client->executeNativeSQL(`
CREATE TABLE "valueset_compose_include_value_sets" (
	"valueSetComposeIncludeValueSetId" INT AUTO_INCREMENT,
	"valuesetcomposeValueSetComposeIncludeId" INT NOT NULL,
	FOREIGN KEY("valuesetcomposeValueSetComposeIncludeId") REFERENCES "valueset_compose_includes"("valueSetComposeIncludeId"),
	"valuesetValueSetId" INT NOT NULL,
	FOREIGN KEY("valuesetValueSetId") REFERENCES "valuesets"("valueSetId"),
	PRIMARY KEY("valueSetComposeIncludeValueSetId")
);`);
}

public isolated function cleanupTestDB() returns persist:Error? {
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valueset_compose_include_value_sets";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valueset_compose_include_concepts";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valueset_compose_includes";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "concepts";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "valuesets";`);
    _ = check h2Client->executeNativeSQL(`DROP TABLE IF EXISTS "codesystems";`);
}


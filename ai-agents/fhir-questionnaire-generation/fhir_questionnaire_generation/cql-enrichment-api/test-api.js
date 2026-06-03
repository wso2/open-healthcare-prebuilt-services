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

// ============================================================
// API Test Script — run with: node test/test-api.js
// Requires the server to be running on localhost:3000
// ============================================================

const BASE = process.env.API_URL || "http://localhost:3000";

const AIMOVIG_QUESTIONNAIRE = {
  resourceType: "Questionnaire",
  id: "4",
  meta: { profile: ["http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire"] },
  url: "http://example.org/fhir/Questionnaire/aimovig-prior-auth",
  version: "1.0.0",
  status: "active",
  title: { value: "Prior Authorization Questionnaire for Aimovig" },
  subjectType: ["Patient"],
  item: [
    { linkId: "1", text: { value: "Has the patient been diagnosed with chronic migraines?" }, type: "boolean" },
    { linkId: "2", text: { value: "Has the patient tried other preventive migraine treatments?" }, type: "boolean" },
    { linkId: "3", text: { value: "Please list previous medications used for migraine prevention." }, type: "display" },
    { linkId: "4", text: { value: "What is the frequency of migraines per month?" }, type: "integer" },
    { linkId: "5", text: { value: "Has the patient experienced side effects or lack of effectiveness with prior treatments?" }, type: "boolean" },
    { linkId: "6", text: { value: "Does the patient have any contraindications to other migraine medications?" }, type: "boolean" },
    { linkId: "7", text: { value: "Does the patient have insurance coverage for Aimovig?" }, type: "boolean" },
  ],
};

async function test(name, method, path, body, validate) {
  try {
    const opts = { method, headers: { "Content-Type": "application/fhir+json" } };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(`${BASE}${path}`, opts);
    const data = await res.json();

    if (res.ok && (!validate || validate(data))) {
      console.log(`  ✓ ${name}`);
    } else {
      console.log(`  ✗ ${name} — Status: ${res.status}`);
      if (data.error) console.log(`    Error: ${data.message}`);
    }
    return data;
  } catch (err) {
    console.log(`  ✗ ${name} — ${err.message}`);
    return null;
  }
}

async function run() {
  console.log(`\nTesting WSO2 CQL Enrichment API at ${BASE}\n`);
  console.log("─── GET endpoints ───");

  await test("Health check", "GET", "/api/health", null, (d) => d.status === "ok");
  await test("Terminology", "GET", "/api/terminology", null, (d) => d.codeSystems.length > 0);

  console.log("\n─── POST /api/enrich (full pipeline) ───");

  const enrichResult = await test("Enrich Aimovig Questionnaire", "POST", "/api/enrich", AIMOVIG_QUESTIONNAIRE, (d) => d.success);
  if (enrichResult?.success) {
    const s = enrichResult.stats;
    console.log(`    Items: ${s.totalItems} | High: ${s.highConfidence} | Medium: ${s.mediumConfidence} | Manual: ${s.manual} | Rate: ${s.autoPopulationRate}%`);
    console.log(`    ValueSets: ${s.valueSetsGenerated} | Bundle entries: ${enrichResult.questionnairePackageBundle.entry.length}`);
  }

  console.log("\n─── POST /api/analyze (analysis only) ───");

  const analyzeResult = await test("Analyze items", "POST", "/api/analyze", AIMOVIG_QUESTIONNAIRE, (d) => d.success);
  if (analyzeResult?.success) {
    analyzeResult.items.forEach((item) => {
      const icon = item.confidence === "high" ? "●" : item.confidence === "medium" ? "◐" : "○";
      console.log(`    ${icon} [${item.linkId}] ${item.text.substring(0, 60)}... → ${item.confidence}${item.hasCQL ? " ✓CQL" : ""}`);
    });
  }

  console.log("\n─── POST /api/cql (CQL only) ───");

  const cqlResult = await test("Generate CQL", "POST", "/api/cql", AIMOVIG_QUESTIONNAIRE, (d) => d.success && d.cql.includes("define"));
  if (cqlResult?.success) {
    const defines = (cqlResult.cql.match(/define "/g) || []).length;
    console.log(`    Library: ${cqlResult.libraryName} | Defines: ${defines}`);
  }

  console.log("\n─── POST /api/bundle ($questionnaire-package) ───");

  const bundleResult = await test("Generate bundle", "POST", "/api/bundle", AIMOVIG_QUESTIONNAIRE, (d) => d.resourceType === "Bundle");
  if (bundleResult?.resourceType === "Bundle") {
    console.log(`    Bundle type: ${bundleResult.type} | Entries: ${bundleResult.entry.length}`);
    bundleResult.entry.forEach((e) => {
      console.log(`      - ${e.resource.resourceType}: ${e.resource.name || e.resource.id || ""}`);
    });
  }

  console.log("\n─── Error handling ───");

  await test("Invalid input (empty body)", "POST", "/api/enrich", {}, (d) => d.error === "Invalid input");
  await test("Invalid input (wrong resourceType)", "POST", "/api/enrich", { resourceType: "Patient" }, (d) => d.error === "Invalid input");

  console.log("\n─── Done ───\n");
}

run();

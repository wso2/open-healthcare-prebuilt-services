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
// WSO2 CQL Enrichment Engine — REST API Server
// ============================================================
// POST /api/enrich          → Full enrichment pipeline
// POST /api/analyze         → Item analysis only
// POST /api/cql             → CQL library only
// POST /api/bundle          → $questionnaire-package bundle
// GET  /api/health          → Health check
// GET  /api/terminology     → Supported terminologies
// ============================================================

import express from "express";
import cors from "cors";
import { enrichQuestionnaireWithCQL, analyzeQuestionnaireItem, flattenItems, toStr } from "./engine.js";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: "10mb", type: ["application/json", "application/fhir+json"] }));

// --- Health check ---
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    service: "WSO2 CQL Enrichment Engine",
    version: "1.0.0",
    fhirVersion: "4.0.1",
    cqlVersion: "1.5",
    capabilities: [
      "FHIR Questionnaire analysis",
      "EHR-executable CQL generation",
      "Multi-terminology ValueSets (SNOMED CT + ICD-10-CM)",
      "Condition + Observation fallback queries",
      "LOINC Answer List matching",
      "$questionnaire-package bundle generation",
      "Da Vinci DTR STD Questionnaire profile enrichment",
    ],
  });
});

// --- Full enrichment pipeline ---
// Input:  { "resourceType": "Questionnaire", ... }
// Output: enrichedQuestionnaire, cqlLibrary, valueSets, bundle, stats
app.post("/api/enrich", async (req, res) => {
  try {
    const questionnaire = req.body;
    if (!questionnaire || questionnaire.resourceType !== "Questionnaire") {
      return res.status(400).json({
        error: "Invalid input",
        message: 'Request body must be a FHIR Questionnaire resource (resourceType: "Questionnaire")',
      });
    }

    const result = enrichQuestionnaireWithCQL(questionnaire);

    res.json({
      success: true,
      enrichedQuestionnaire: result.enrichedQuestionnaire,
      cqlLibrary: result.cqlLibrary,
      valueSets: result.valueSets,
      questionnairePackageBundle: result.questionnairePackageBundle,
      stats: result.stats,
    });
  } catch (err) {
    res.status(500).json({ error: "Processing error", message: err.message });
  }
});

// --- Item analysis only (no CQL generation) ---
app.post("/api/analyze", (req, res) => {
  try {
    const questionnaire = req.body;
    if (!questionnaire || questionnaire.resourceType !== "Questionnaire") {
      return res.status(400).json({ error: "Invalid input", message: 'Must be a FHIR Questionnaire' });
    }

    const flatItems = flattenItems(questionnaire.item);
    const analyses = flatItems.map((item) => analyzeQuestionnaireItem(item, item._parentContext));

    // Summarize
    const groups = analyses.filter((a) => a.type === "group").length;
    const high = analyses.filter((a) => a.confidence === "high" && a.cqlExpression).length;
    const medium = analyses.filter((a) => a.confidence === "medium").length;
    const manual = analyses.filter((a) => a.confidence === "none" && a.type !== "group").length;

    res.json({
      success: true,
      totalItems: analyses.length,
      summary: { groups, highConfidence: high, mediumConfidence: medium, manual },
      items: analyses.map((a) => ({
        linkId: a.linkId,
        text: a.text,
        type: a.type,
        confidence: a.confidence,
        reasoning: a.reasoning,
        hasCQL: !!a.cqlExpression,
        cqlExpression: a.cqlExpression,
        valueSetCount: a.valueSets.length,
      })),
    });
  } catch (err) {
    res.status(500).json({ error: "Analysis error", message: err.message });
  }
});

// --- CQL Library only ---
app.post("/api/cql", (req, res) => {
  try {
    const questionnaire = req.body;
    if (!questionnaire || questionnaire.resourceType !== "Questionnaire") {
      return res.status(400).json({ error: "Invalid input", message: 'Must be a FHIR Questionnaire' });
    }

    const result = enrichQuestionnaireWithCQL(questionnaire);

    // Return CQL as plain text if Accept: text/plain, otherwise JSON
    if (req.accepts("text/plain")) {
      res.type("text/plain").send(result.cqlLibrary.cql);
    } else {
      res.json({
        success: true,
        libraryName: result.cqlLibrary.name,
        libraryUrl: result.cqlLibrary.url,
        cql: result.cqlLibrary.cql,
        libraryResource: result.cqlLibrary.resource,
      });
    }
  } catch (err) {
    res.status(500).json({ error: "CQL generation error", message: err.message });
  }
});

// --- $questionnaire-package Bundle only ---
app.post("/api/bundle", (req, res) => {
  try {
    const questionnaire = req.body;
    if (!questionnaire || questionnaire.resourceType !== "Questionnaire") {
      return res.status(400).json({ error: "Invalid input", message: 'Must be a FHIR Questionnaire' });
    }

    const result = enrichQuestionnaireWithCQL(questionnaire);

    // Return as FHIR JSON
    res.type("application/fhir+json").json(result.questionnairePackageBundle);
  } catch (err) {
    res.status(500).json({ error: "Bundle generation error", message: err.message });
  }
});

// --- Supported terminologies ---
app.get("/api/terminology", (req, res) => {
  res.json({
    codeSystems: [
      { system: "http://snomed.info/sct", name: "SNOMED CT", usage: "Condition codes" },
      { system: "http://hl7.org/fhir/sid/icd-10-cm", name: "ICD-10-CM", usage: "Condition codes (cross-mapped)" },
      { system: "http://loinc.org", name: "LOINC", usage: "Observation codes + Answer Lists" },
      { system: "http://www.nlm.nih.gov/research/umls/rxnorm", name: "RxNorm", usage: "Medication codes" },
      { system: "http://www.ama-assn.org/go/cpt", name: "CPT", usage: "Procedure codes" },
      { system: "https://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets", name: "HCPCS", usage: "DME/supply codes" },
    ],
    fhirResources: [
      "Patient", "Condition", "Observation", "MedicationRequest",
      "Procedure", "Encounter", "AllergyIntolerance", "Coverage",
      "ServiceRequest", "PractitionerRole",
    ],
    profiles: ["US Core 3.1.1", "US Core 6.1.0", "US Core 7.0.0"],
  });
});

// --- Start server ---
app.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════════════════════╗
║   WSO2 CQL Enrichment Engine — REST API                 ║
║   Running on http://localhost:${PORT}                      ║
╠══════════════════════════════════════════════════════════╣
║   POST /api/enrich    → Full enrichment pipeline        ║
║   POST /api/analyze   → Item analysis only              ║
║   POST /api/cql       → CQL library generation          ║
║   POST /api/bundle    → $questionnaire-package bundle   ║
║   GET  /api/health    → Health check                    ║
║   GET  /api/terminology → Supported terminologies       ║
╚══════════════════════════════════════════════════════════╝
  `);
});

export default app;

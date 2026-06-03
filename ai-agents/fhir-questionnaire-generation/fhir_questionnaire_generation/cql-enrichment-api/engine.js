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
// WSO2 CQL ENRICHMENT ENGINE — Core Library
// ============================================================
// Pure JavaScript module with zero UI dependencies.
// Analyzes FHIR Questionnaires, generates EHR-executable CQL,
// resolves multi-terminology ValueSets (SNOMED + ICD-10-CM),
// and produces DTR-ready $questionnaire-package bundles.
// ============================================================

// --- Helper: safely extract string from FHIR value ---
export function toStr(v) {
  if (v == null) return "";
  if (typeof v === "string") return v;
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  if (typeof v === "object" && v.value != null) return toStr(v.value);
  if (typeof v === "object" && v.display != null) return toStr(v.display);
  try { return JSON.stringify(v); } catch { return ""; }
}

// ============================================================
// EHR-EXECUTABLE CQL PATTERNS
// Only US Core FHIR R4 resources: Patient, Condition,
// Observation, MedicationRequest, Procedure, Encounter,
// AllergyIntolerance, Coverage, ServiceRequest, PractitionerRole
// ============================================================

export const CQL_PATTERNS = {
  patientName: {
    category: "demographics",
    define: `define "PatientFirstName":\n  Patient.name.first().given.first()\n\ndefine "PatientLastName":\n  Patient.name.first().family\n\ndefine "PatientFullName":\n  PatientFirstName + ' ' + PatientLastName`,
    valueExpr: `"PatientFullName"`,
  },
  patientGender: {
    category: "demographics",
    define: `define "PatientGender":\n  Patient.gender`,
  },
  patientBirthDate: {
    category: "demographics",
    define: `define "PatientBirthDate":\n  Patient.birthDate`,
  },
  patientAge: {
    category: "demographics",
    define: `define "PatientAge":\n  AgeInYears()`,
  },
  patientAddress: {
    category: "demographics",
    define: `define "PatientAddressFirstLine":\n  Patient.address.first().line.first()\n\ndefine "PatientCity":\n  Patient.address.first().city\n\ndefine "PatientState":\n  Patient.address.first().state\n\ndefine "PatientPostalCode":\n  Patient.address.first().postalCode`,
    valueExpr: `"PatientAddressFirstLine"`,
  },
  latestObservationByLoinc: {
    category: "observation",
    template: (label, loincCode, loincDisplay) =>
      `define "${label}":\n  First(\n    [Observation: "${loincDisplay}"] O\n      where O.status in {'final', 'amended', 'corrected'}\n      sort by effective descending\n  )\n\ndefine "${label}Value":\n  FHIRHelpers.ToQuantity("${label}".value as FHIR.Quantity)\n\ndefine "${label}Date":\n  "${label}".effective`,
    valueSetTemplate: (loincCode, loincDisplay) => ({
      resourceType: "ValueSet",
      id: `vs-${loincCode.replace(/[^a-zA-Z0-9]/g, "-")}`,
      url: `http://example.org/fhir/ValueSet/${loincDisplay.replace(/\s+/g, "-").toLowerCase()}`,
      name: loincDisplay.replace(/\s+/g, ""),
      title: loincDisplay,
      status: "active",
      compose: { include: [{ system: "http://loinc.org", concept: [{ code: loincCode, display: loincDisplay }] }] },
    }),
  },
  activeConditionBySNOMED: {
    category: "condition",
    template: (label, snomedCode, snomedDisplay) =>
      `define "${label}ViaCondition":\n  exists(\n    [Condition: "${snomedDisplay}"] C\n      where C.clinicalStatus.coding.where(code = 'active').exists()\n        and C.verificationStatus.coding.where(code = 'confirmed').exists()\n  )\n\ndefine "${label}ViaObservation":\n  exists(\n    [Observation: "${snomedDisplay}"] O\n      where O.status in {'final', 'amended', 'corrected'}\n  )\n\ndefine "${label}":\n  "${label}ViaCondition" or "${label}ViaObservation"`,
    valueSetTemplate: (code, display, icd10Codes) => {
      const includes = [
        { system: "http://snomed.info/sct", concept: [{ code, display }] },
      ];
      if (icd10Codes && icd10Codes.length > 0) {
        includes.push({
          system: "http://hl7.org/fhir/sid/icd-10-cm",
          concept: icd10Codes.map(c => ({ code: c.code, display: c.display })),
        });
      }
      return {
        resourceType: "ValueSet", id: `vs-${code}`,
        url: `http://example.org/fhir/ValueSet/${display.replace(/\s+/g, "-").toLowerCase()}`,
        name: display.replace(/\s+/g, ""), title: display, status: "active",
        compose: { include: includes },
      };
    },
  },
  conditionOnsetDate: {
    category: "condition",
    template: (label, snomedCode, snomedDisplay) =>
      `define "${label}Onset":\n  First(\n    [Condition: "${snomedDisplay}"] C\n      where C.clinicalStatus.coding.where(code = 'active').exists()\n      sort by onset descending\n  ).onset`,
  },
  activeMedicationsByRxNorm: {
    category: "medication",
    template: (label, rxnormCode, rxnormDisplay) =>
      `define "${label}":\n  [MedicationRequest: "${rxnormDisplay}"] M\n    where M.status = 'active'\n      and M.intent = 'order'`,
    valueSetTemplate: (code, display) => ({
      resourceType: "ValueSet", id: `vs-rxnorm-${code}`,
      url: `http://example.org/fhir/ValueSet/${display.replace(/\s+/g, "-").toLowerCase()}`,
      name: display.replace(/\s+/g, ""), title: display, status: "active",
      compose: { include: [{ system: "http://www.nlm.nih.gov/research/umls/rxnorm", concept: [{ code, display }] }] },
    }),
  },
  recentProcedureByCPT: {
    category: "procedure",
    template: (label, cptCode, cptDisplay, months = 12) =>
      `define "${label}":\n  exists(\n    [Procedure: "${cptDisplay}"] P\n      where P.status = 'completed'\n        and FHIRHelpers.ToDateTime(P.performed as FHIR.dateTime) during Interval[Now() - ${months} months, Now()]\n  )\n\ndefine "${label}Date":\n  First(\n    [Procedure: "${cptDisplay}"] P\n      where P.status = 'completed'\n      sort by performed descending\n  ).performed`,
    valueSetTemplate: (code, display) => ({
      resourceType: "ValueSet", id: `vs-cpt-${code}`,
      url: `http://example.org/fhir/ValueSet/${display.replace(/\s+/g, "-").toLowerCase()}`,
      name: display.replace(/\s+/g, ""), title: display, status: "active",
      compose: { include: [{ system: "http://www.ama-assn.org/go/cpt", concept: [{ code, display }] }] },
    }),
  },
  coverageInfo: {
    category: "coverage",
    define: `define "ActiveCoverage":\n  First(\n    [Coverage] C\n      where C.status = 'active'\n      sort by period.start descending\n  )\n\ndefine "PayerName":\n  "ActiveCoverage".payor.first().display\n\ndefine "MemberID":\n  "ActiveCoverage".subscriberId`,
  },
  lastEncounter: {
    category: "encounter",
    define: `define "MostRecentEncounter":\n  First(\n    [Encounter] E\n      where E.status = 'finished'\n      sort by period.start descending\n  )\n\ndefine "MostRecentEncounterDate":\n  "MostRecentEncounter".period.start`,
  },
  activeAllergies: {
    category: "allergy",
    define: `define "ActiveAllergies":\n  [AllergyIntolerance] A\n    where A.clinicalStatus.coding.where(code = 'active').exists()`,
  },
  orderingProvider: {
    category: "practitioner",
    define: `define "OrderingProvider":\n  First(\n    [PractitionerRole] PR\n      sort by period.start descending\n  )\n\ndefine "ProviderName":\n  "OrderingProvider".practitioner.display\n\ndefine "ProviderNPI":\n  First(\n    "OrderingProvider".identifier I\n      where I.system = 'http://hl7.org/fhir/sid/us-npi'\n  ).value`,
  },
  serviceRequestInfo: {
    category: "serviceRequest",
    define: `define "CurrentServiceRequest":\n  First(\n    [ServiceRequest] SR\n      where SR.status in {'active', 'draft'}\n      sort by authoredOn descending\n  )\n\ndefine "RequestedServiceCode":\n  "CurrentServiceRequest".code\n\ndefine "RequestedServiceDate":\n  "CurrentServiceRequest".occurrence`,
  },
};

// --- LOINC codes ---
export const LOINC_MAP = {
  "blood pressure": { code: "85354-9", display: "Blood pressure panel" },
  systolic: { code: "8480-6", display: "Systolic blood pressure" },
  diastolic: { code: "8462-4", display: "Diastolic blood pressure" },
  "heart rate": { code: "8867-4", display: "Heart rate" },
  pulse: { code: "8867-4", display: "Heart rate" },
  temperature: { code: "8310-5", display: "Body temperature" },
  weight: { code: "29463-7", display: "Body weight" },
  height: { code: "8302-2", display: "Body height" },
  bmi: { code: "39156-5", display: "Body mass index" },
  hba1c: { code: "4548-4", display: "Hemoglobin A1c" },
  hemoglobin: { code: "718-7", display: "Hemoglobin" },
  glucose: { code: "2339-0", display: "Glucose [Mass/volume] in Blood" },
  creatinine: { code: "2160-0", display: "Creatinine [Mass/volume] in Serum" },
  egfr: { code: "33914-3", display: "Estimated glomerular filtration rate" },
  cholesterol: { code: "2093-3", display: "Total cholesterol" },
  ldl: { code: "2089-1", display: "LDL cholesterol" },
  hdl: { code: "2085-9", display: "HDL cholesterol" },
  triglycerides: { code: "2571-8", display: "Triglycerides" },
  potassium: { code: "2823-3", display: "Potassium [Moles/volume] in Serum" },
  sodium: { code: "2951-2", display: "Sodium [Moles/volume] in Serum" },
  wbc: { code: "6690-2", display: "Leukocytes in Blood" },
  platelets: { code: "777-3", display: "Platelets in Blood" },
  inr: { code: "6301-6", display: "INR in Platelet poor plasma" },
  tsh: { code: "3016-3", display: "TSH" },
  oxygen: { code: "2708-6", display: "Oxygen saturation in Arterial blood" },
  pao2: { code: "2703-7", display: "Oxygen partial pressure in Arterial blood" },
  paco2: { code: "2019-8", display: "Carbon dioxide partial pressure in Arterial blood" },
  fev1: { code: "20150-9", display: "FEV1" },
  fvc: { code: "19868-9", display: "FVC" },
};

// --- Multi-terminology condition map (SNOMED + ICD-10-CM) ---
export const SNOMED_MAP = {
  diabetes: { code: "73211009", display: "Diabetes mellitus", icd10: [{ code: "E11.9", display: "Type 2 diabetes mellitus without complications" }, { code: "E10.9", display: "Type 1 diabetes mellitus without complications" }] },
  hypertension: { code: "38341003", display: "Hypertensive disorder", icd10: [{ code: "I10", display: "Essential (primary) hypertension" }] },
  copd: { code: "13645005", display: "Chronic obstructive pulmonary disease", icd10: [{ code: "J44.9", display: "Chronic obstructive pulmonary disease, unspecified" }] },
  asthma: { code: "195967001", display: "Asthma", icd10: [{ code: "J45.909", display: "Unspecified asthma, uncomplicated" }] },
  "heart failure": { code: "84114007", display: "Heart failure", icd10: [{ code: "I50.9", display: "Heart failure, unspecified" }] },
  chf: { code: "84114007", display: "Heart failure", icd10: [{ code: "I50.9", display: "Heart failure, unspecified" }] },
  ckd: { code: "709044004", display: "Chronic kidney disease", icd10: [{ code: "N18.9", display: "Chronic kidney disease, unspecified" }] },
  obesity: { code: "414916001", display: "Obesity", icd10: [{ code: "E66.9", display: "Obesity, unspecified" }] },
  depression: { code: "35489007", display: "Depressive disorder", icd10: [{ code: "F32.9", display: "Major depressive disorder, single episode, unspecified" }] },
  anxiety: { code: "197480006", display: "Anxiety disorder", icd10: [{ code: "F41.9", display: "Anxiety disorder, unspecified" }] },
  "sleep apnea": { code: "73430006", display: "Sleep apnea", icd10: [{ code: "G47.33", display: "Obstructive sleep apnea" }] },
  migraine: { code: "37796009", display: "Migraine", icd10: [{ code: "G43.909", display: "Migraine, unspecified, not intractable" }] },
  "chronic migraine": { code: "124171000119105", display: "Chronic migraine", icd10: [{ code: "G43.709", display: "Chronic migraine without aura, not intractable" }] },
  headache: { code: "25064002", display: "Headache", icd10: [{ code: "R51.9", display: "Headache, unspecified" }] },
  "rheumatoid arthritis": { code: "69896004", display: "Rheumatoid arthritis", icd10: [{ code: "M06.9", display: "Rheumatoid arthritis, unspecified" }] },
  epilepsy: { code: "84757009", display: "Epilepsy", icd10: [{ code: "G40.909", display: "Epilepsy, unspecified, not intractable" }] },
  "multiple sclerosis": { code: "24700007", display: "Multiple sclerosis", icd10: [{ code: "G35", display: "Multiple sclerosis" }] },
  "chronic pain": { code: "82423001", display: "Chronic pain", icd10: [{ code: "G89.29", display: "Other chronic pain" }] },
  fibromyalgia: { code: "203082005", display: "Fibromyalgia", icd10: [{ code: "M79.7", display: "Fibromyalgia" }] },
  psoriasis: { code: "9014002", display: "Psoriasis", icd10: [{ code: "L40.9", display: "Psoriasis, unspecified" }] },
  "crohn": { code: "34000006", display: "Crohn's disease", icd10: [{ code: "K50.90", display: "Crohn's disease, unspecified, without complications" }] },
  osteoporosis: { code: "64859006", display: "Osteoporosis", icd10: [{ code: "M81.0", display: "Age-related osteoporosis without current pathological fracture" }] },
  hiv: { code: "86406008", display: "Human immunodeficiency virus infection", icd10: [{ code: "B20", display: "Human immunodeficiency virus [HIV] disease" }] },
  anemia: { code: "271737000", display: "Anemia", icd10: [{ code: "D64.9", display: "Anemia, unspecified" }] },
  hypothyroid: { code: "40930008", display: "Hypothyroidism", icd10: [{ code: "E03.9", display: "Hypothyroidism, unspecified" }] },
  cirrhosis: { code: "19943007", display: "Cirrhosis of liver", icd10: [{ code: "K74.60", display: "Unspecified cirrhosis of liver" }] },
};

// --- Semantic Patterns ---
export const SEMANTIC_PATTERNS = {
  priorMedications: {
    match: /(?:previous|prior|tried|past|failed|other)\s*(?:medication|treatment|therap|drug|preventive|regimen)/i,
    cqlTemplate: () => `define "PriorMedications":\n  [MedicationRequest] M\n    where M.status in {'completed', 'stopped'}\n      and M.intent = 'order'\n\ndefine "HasPriorMedications":\n  exists("PriorMedications")`,
    expression: `"HasPriorMedications"`,
    reasoning: "US Core MedicationRequest — completed/stopped orders",
  },
  sideEffects: {
    match: /(?:side\s*effect|adverse\s*(?:reaction|event|effect)|lack\s*of\s*effectiveness|intolerance)/i,
    cqlTemplate: () => `define "MedicationIntolerances":\n  [AllergyIntolerance] AI\n    where AI.clinicalStatus.coding.where(code = 'active').exists()\n      and AI.category.exists(c | c = 'medication')\n\ndefine "HasMedicationIntolerances":\n  exists("MedicationIntolerances")`,
    expression: `"HasMedicationIntolerances"`,
    reasoning: "US Core AllergyIntolerance — medication intolerances",
  },
  contraindications: {
    match: /contraindication|cannot\s*(?:take|use|tolerate)/i,
    cqlTemplate: () => `define "MedicationAllergies":\n  [AllergyIntolerance] AI\n    where AI.clinicalStatus.coding.where(code = 'active').exists()\n      and AI.category.exists(c | c = 'medication')\n\ndefine "HasMedicationAllergies":\n  exists("MedicationAllergies")`,
    expression: `"HasMedicationAllergies"`,
    reasoning: "US Core AllergyIntolerance — medication allergies",
  },
  insuranceCoverage: {
    match: /insurance\s*coverage|coverage\s*for|covered\s*(?:by|under)/i,
    notPopulatable: true,
    reasoning: "Drug/service-specific coverage is payer-side data. Use adaptive questionnaire ($next-question).",
  },
  frequencyCount: {
    match: /(?:frequency|how\s*(?:many|often|frequent))\s*(?:of\s*)?(?:migraine|headache|episode|attack|seizure)/i,
    cqlTemplate: (context) => {
      let conditionDisplay = "Headache";
      for (const [key, snomed] of Object.entries(SNOMED_MAP)) {
        if (context.toLowerCase().includes(key)) { conditionDisplay = snomed.display; break; }
      }
      const safe = conditionDisplay.replace(/\s+/g, "");
      return `define "Recent${safe}Conditions":\n  [Condition: "${conditionDisplay}"] C\n    where C.onset is not null\n      and C.onset after (Now() - 6 months)\n\ndefine "${safe}EpisodeCount":\n  Count("Recent${safe}Conditions")`;
    },
    expressionFn: (context) => {
      let conditionDisplay = "Headache";
      for (const [key, snomed] of Object.entries(SNOMED_MAP)) {
        if (context.toLowerCase().includes(key)) { conditionDisplay = snomed.display; break; }
      }
      return `"${conditionDisplay.replace(/\s+/g, "")}EpisodeCount"`;
    },
    reasoning: "US Core Condition — episode count estimate",
    confidence: "medium",
  },
  diagnosedWith: {
    match: /(?:diagnosed|diagnosis)\s*(?:with|of)\s+(\w[\w\s]*)/i,
    dynamicMatch: true,
    handler: (textLower) => {
      const m = textLower.match(/(?:diagnosed|diagnosis)\s*(?:with|of)\s+(.+?)(?:\?|$)/i);
      if (!m) return null;
      const conditionText = m[1].trim();
      for (const [key, snomed] of Object.entries(SNOMED_MAP)) {
        if (conditionText.includes(key)) {
          const safe = snomed.display.replace(/\s+/g, "");
          const includes = [{ system: "http://snomed.info/sct", concept: [{ code: snomed.code, display: snomed.display }] }];
          if (snomed.icd10?.length) includes.push({ system: "http://hl7.org/fhir/sid/icd-10-cm", concept: snomed.icd10 });
          return {
            cql: `define "Has${safe}ViaCondition":\n  exists(\n    [Condition: "${snomed.display}"] C\n      where C.clinicalStatus.coding.where(code = 'active').exists()\n        and C.verificationStatus.coding.where(code = 'confirmed').exists()\n  )\n\ndefine "Has${safe}ViaObservation":\n  exists(\n    [Observation: "${snomed.display}"] O\n      where O.status in {'final', 'amended', 'corrected'}\n  )\n\ndefine "Has${safe}":\n  "Has${safe}ViaCondition" or "Has${safe}ViaObservation"`,
            expression: `"Has${safe}"`,
            valueSet: { resourceType: "ValueSet", id: `vs-${snomed.code}`, url: `http://example.org/fhir/ValueSet/${snomed.display.replace(/\s+/g, "-").toLowerCase()}`, name: safe, title: snomed.display, status: "active", compose: { include: includes } },
            reasoning: `US Core Condition+Observation fallback — SNOMED ${snomed.code} (${snomed.display})`,
          };
        }
      }
      return null;
    },
  },
};

// ============================================================
// ANALYSIS ENGINE
// ============================================================

export function analyzeQuestionnaireItem(item, parentContext = "") {
  const analysis = {
    linkId: toStr(item.linkId),
    text: toStr(item.text),
    type: toStr(item.type),
    cqlDefines: [],
    cqlExpression: null,
    valueSets: [],
    confidence: "high",
    reasoning: "",
  };
  const textLower = toStr(item.text).toLowerCase();

  // Demographics
  if (textLower.match(/patient\s*(full\s*)?name/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.patientName.define);
    analysis.cqlExpression = CQL_PATTERNS.patientName.valueExpr;
    analysis.reasoning = "US Core Patient.name";
  } else if (textLower.match(/date\s*of\s*birth|birth\s*date|dob/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.patientBirthDate.define);
    analysis.cqlExpression = `"PatientBirthDate"`;
    analysis.reasoning = "US Core Patient.birthDate";
  } else if (textLower.match(/\bgender\b|\bsex\b/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.patientGender.define);
    analysis.cqlExpression = `"PatientGender"`;
    analysis.reasoning = "US Core Patient.gender";
  } else if (textLower.match(/\bage\b/i) && !textLower.match(/dosage|usage|stage/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.patientAge.define);
    analysis.cqlExpression = `"PatientAge"`;
    analysis.reasoning = "AgeInYears() from Patient.birthDate";
  } else if (textLower.match(/\bbmi\b|body\s*mass/i)) {
    const loinc = LOINC_MAP.bmi;
    analysis.cqlDefines.push(CQL_PATTERNS.latestObservationByLoinc.template("LatestBMI", loinc.code, loinc.display));
    analysis.cqlExpression = `"LatestBMIValue"`;
    analysis.valueSets.push(CQL_PATTERNS.latestObservationByLoinc.valueSetTemplate(loinc.code, loinc.display));
    analysis.reasoning = `US Core Observation LOINC ${loinc.code}`;
  } else if (textLower.match(/member\s*id|subscriber\s*id/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.coverageInfo.define);
    analysis.cqlExpression = `"MemberID"`;
    analysis.reasoning = "Coverage.subscriberId";
  } else if (textLower.match(/provider\s*name|physician\s*name|ordering\s*(provider|physician)/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.orderingProvider.define);
    analysis.cqlExpression = `"ProviderName"`;
    analysis.reasoning = "PractitionerRole.practitioner.display";
  } else if (textLower.match(/provider\s*npi|npi/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.orderingProvider.define);
    analysis.cqlExpression = `"ProviderNPI"`;
    analysis.reasoning = "PractitionerRole.identifier (NPI)";
  } else if (textLower.match(/last\s*visit|date\s*of.*visit|encounter\s*date/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.lastEncounter.define);
    analysis.cqlExpression = `"MostRecentEncounterDate"`;
    analysis.reasoning = "US Core Encounter.period.start";
  }
  // Specific observations
  else if (textLower.match(/pao2|arterial.*oxygen.*partial/i)) {
    const loinc = LOINC_MAP.pao2;
    analysis.cqlDefines.push(CQL_PATTERNS.latestObservationByLoinc.template("LatestPaO2", loinc.code, loinc.display));
    analysis.cqlExpression = `"LatestPaO2Value"`;
    analysis.valueSets.push(CQL_PATTERNS.latestObservationByLoinc.valueSetTemplate(loinc.code, loinc.display));
    analysis.reasoning = `US Core Observation LOINC ${loinc.code}`;
  } else if (textLower.match(/oxygen\s*saturation|spo2|sao2|o2\s*sat/i)) {
    const loinc = LOINC_MAP.oxygen;
    analysis.cqlDefines.push(CQL_PATTERNS.latestObservationByLoinc.template("LatestO2Sat", loinc.code, loinc.display));
    analysis.cqlExpression = `"LatestO2SatValue"`;
    analysis.valueSets.push(CQL_PATTERNS.latestObservationByLoinc.valueSetTemplate(loinc.code, loinc.display));
    analysis.reasoning = `US Core Observation LOINC ${loinc.code}`;
  } else if (textLower.match(/\bahi\b|apnea.hypopnea/i)) {
    const loinc = { code: "69989-2", display: "Apnea hypopnea index" };
    analysis.cqlDefines.push(CQL_PATTERNS.latestObservationByLoinc.template("LatestAHI", loinc.code, loinc.display));
    analysis.cqlExpression = `"LatestAHIValue"`;
    analysis.valueSets.push(CQL_PATTERNS.latestObservationByLoinc.valueSetTemplate(loinc.code, loinc.display));
    analysis.reasoning = `US Core Observation LOINC ${loinc.code}`;
  }
  // Boolean — conditions + semantic patterns
  else if (toStr(item.type) === "boolean") {
    let matched = false;
    // Try diagnosedWith
    const diagResult = SEMANTIC_PATTERNS.diagnosedWith.handler(textLower);
    if (diagResult) {
      analysis.cqlDefines.push(diagResult.cql);
      analysis.cqlExpression = diagResult.expression;
      if (diagResult.valueSet) analysis.valueSets.push(diagResult.valueSet);
      analysis.reasoning = diagResult.reasoning;
      matched = true;
    }
    // Try SNOMED map
    if (!matched) {
      for (const [key, snomed] of Object.entries(SNOMED_MAP)) {
        if (textLower.includes(key)) {
          const label = `Has${snomed.display.replace(/\s+/g, "")}`;
          analysis.cqlDefines.push(CQL_PATTERNS.activeConditionBySNOMED.template(label, snomed.code, snomed.display));
          analysis.cqlExpression = `"${label}"`;
          analysis.valueSets.push(CQL_PATTERNS.activeConditionBySNOMED.valueSetTemplate(snomed.code, snomed.display, snomed.icd10));
          analysis.reasoning = `US Core Condition+Observation — SNOMED ${snomed.code} + ICD-10-CM`;
          matched = true;
          break;
        }
      }
    }
    // Try semantic patterns
    if (!matched) {
      for (const [key, sp] of Object.entries(SEMANTIC_PATTERNS)) {
        if (key === "diagnosedWith") continue;
        if (sp.match && sp.match.test(textLower)) {
          if (sp.notPopulatable) { analysis.confidence = "none"; analysis.reasoning = sp.reasoning; matched = true; break; }
          const cql = typeof sp.cqlTemplate === "function" ? sp.cqlTemplate(textLower) : sp.cqlTemplate;
          analysis.cqlDefines.push(cql);
          analysis.cqlExpression = typeof sp.expressionFn === "function" ? sp.expressionFn(textLower) : sp.expression;
          analysis.reasoning = sp.reasoning;
          if (sp.confidence) analysis.confidence = sp.confidence;
          matched = true;
          break;
        }
      }
    }
  }
  // Integer/decimal — frequency + LOINC observations
  else if ((toStr(item.type) === "integer" || toStr(item.type) === "decimal") && !analysis.cqlExpression) {
    for (const [key, sp] of Object.entries(SEMANTIC_PATTERNS)) {
      if (sp.match && sp.match.test(textLower) && !sp.notPopulatable) {
        const cql = typeof sp.cqlTemplate === "function" ? sp.cqlTemplate(textLower) : sp.cqlTemplate;
        analysis.cqlDefines.push(cql);
        analysis.cqlExpression = typeof sp.expressionFn === "function" ? sp.expressionFn(textLower) : sp.expression;
        analysis.reasoning = sp.reasoning;
        if (sp.confidence) analysis.confidence = sp.confidence;
        break;
      }
    }
    if (!analysis.cqlExpression) {
      for (const [key, loinc] of Object.entries(LOINC_MAP)) {
        if (textLower.includes(key)) {
          const label = `Latest${loinc.display.replace(/\s+/g, "")}`;
          analysis.cqlDefines.push(CQL_PATTERNS.latestObservationByLoinc.template(label, loinc.code, loinc.display));
          analysis.cqlExpression = `"${label}Value"`;
          analysis.valueSets.push(CQL_PATTERNS.latestObservationByLoinc.valueSetTemplate(loinc.code, loinc.display));
          analysis.reasoning = `US Core Observation LOINC ${loinc.code}`;
          break;
        }
      }
    }
  }
  // Display/text/string — semantic patterns
  else if (["display", "text", "string"].includes(toStr(item.type)) && !analysis.cqlExpression) {
    for (const [key, sp] of Object.entries(SEMANTIC_PATTERNS)) {
      if (key === "diagnosedWith") continue;
      if (sp.match && sp.match.test(textLower)) {
        if (sp.notPopulatable) { analysis.confidence = "none"; analysis.reasoning = sp.reasoning; break; }
        const cql = typeof sp.cqlTemplate === "function" ? sp.cqlTemplate(textLower) : sp.cqlTemplate;
        analysis.cqlDefines.push(cql);
        analysis.cqlExpression = typeof sp.expressionFn === "function" ? sp.expressionFn(textLower) : sp.expression;
        analysis.reasoning = sp.reasoning;
        analysis.confidence = sp.confidence || "medium";
        break;
      }
    }
  }
  // Allergies
  else if (textLower.match(/allerg/i)) {
    analysis.cqlDefines.push(CQL_PATTERNS.activeAllergies.define);
    analysis.cqlExpression = `"ActiveAllergies"`;
    analysis.reasoning = "US Core AllergyIntolerance";
  }

  // Fallback
  if (!analysis.cqlExpression && analysis.cqlDefines.length === 0) {
    analysis.confidence = "none";
    analysis.reasoning = toStr(item.type) === "group"
      ? "Group item — no direct CQL needed"
      : "No automatic mapping found. Manual CQL authoring recommended.";
  }

  return analysis;
}

// ============================================================
// FLATTTEN, GENERATE, ENRICH, BUNDLE
// ============================================================

export function flattenItems(items, parent = "") {
  let result = [];
  if (!items) return result;
  for (const item of items) {
    result.push({ ...item, _parentContext: parent });
    if (item.item) result = result.concat(flattenItems(item.item, toStr(item.text) || parent));
  }
  return result;
}

export function generateCQLLibrary(questionnaire, analyses) {
  const allDefines = new Set();
  const usedDefines = [];
  analyses.forEach((a) => {
    a.cqlDefines.forEach((d) => {
      if (!allDefines.has(d)) { allDefines.add(d); usedDefines.push(d); }
    });
  });

  const libraryName = toStr(questionnaire.name || questionnaire.id || "GeneratedLibrary").replace(/[^a-zA-Z0-9]/g, "");
  const qUrl = toStr(questionnaire.url);
  const libraryUrl = qUrl ? qUrl.replace("/Questionnaire/", "/Library/") + "-prepopulation" : `http://example.org/fhir/Library/${libraryName}Prepopulation`;
  const qTitle = toStr(questionnaire.title || questionnaire.name || "Questionnaire");

  const cql = `library ${libraryName}Prepopulation version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ConditionClinicalStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-clinical'
codesystem "ConditionVerificationStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-ver-status'

context Patient

// EHR-Executable CQL for: ${qTitle}
// Generated by WSO2 CQL Enrichment Engine

${usedDefines.join("\n\n")}
`;

  return {
    cql,
    libraryName: `${libraryName}Prepopulation`,
    libraryUrl,
    libraryResource: {
      resourceType: "Library",
      id: `${libraryName}-prepopulation`.toLowerCase(),
      url: libraryUrl,
      name: `${libraryName}Prepopulation`,
      title: `Pre-population Logic for ${qTitle}`,
      status: "active",
      type: { coding: [{ system: "http://terminology.hl7.org/CodeSystem/library-type", code: "logic-library" }] },
      content: [{ contentType: "text/cql", data: Buffer.from(cql).toString("base64") }],
    },
  };
}

export function enrichQuestionnaire(questionnaire, analyses, library) {
  const enriched = JSON.parse(JSON.stringify(questionnaire));
  if (!enriched.extension) enriched.extension = [];
  enriched.extension.push({ url: "http://hl7.org/fhir/StructureDefinition/cqf-library", valueCanonical: library.libraryUrl });
  if (!enriched.extension.find((e) => e.url === "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext")) {
    enriched.extension.push({
      url: "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext",
      extension: [
        { url: "name", valueCoding: { system: "http://hl7.org/fhir/uv/sdc/CodeSystem/launchContext", code: "patient" } },
        { url: "type", valueCode: "Patient" },
      ],
    });
  }
  enriched.status = "active";
  enriched.meta = { profile: ["http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire"] };

  function enrichItems(items) {
    if (!items) return items;
    return items.map((item) => {
      const analysis = analyses.find((a) => a.linkId === toStr(item.linkId));
      const enrichedItem = { ...item };
      if (analysis?.cqlExpression) {
        if (!enrichedItem.extension) enrichedItem.extension = [];
        enrichedItem.extension.push({
          url: "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression",
          valueExpression: { language: "text/cql", expression: analysis.cqlExpression },
        });
      }
      if (analysis?.answerList && !enrichedItem.answerValueSet) {
        enrichedItem.answerValueSet = analysis.answerList.url;
      }
      if (item.item) enrichedItem.item = enrichItems(item.item);
      return enrichedItem;
    });
  }

  enriched.item = enrichItems(enriched.item);
  return enriched;
}

export function buildBundle(enrichedQuestionnaire, library, valueSets) {
  return {
    resourceType: "Bundle",
    type: "collection",
    entry: [
      { resource: enrichedQuestionnaire },
      { resource: library.libraryResource },
      ...valueSets.map((vs) => ({ resource: vs })),
    ],
  };
}

// ============================================================
// MAIN PIPELINE — single function entry point for the API
// ============================================================

export function enrichQuestionnaireWithCQL(questionnaireJSON) {
  const questionnaire = typeof questionnaireJSON === "string" ? JSON.parse(questionnaireJSON) : questionnaireJSON;

  if (questionnaire.resourceType !== "Questionnaire") {
    throw new Error('Input must have resourceType: "Questionnaire"');
  }

  const flatItems = flattenItems(questionnaire.item);
  const analyses = flatItems.map((item) => analyzeQuestionnaireItem(item, item._parentContext));

  const allValueSets = [];
  const seenVSUrls = new Set();
  analyses.forEach((a) => {
    a.valueSets.forEach((vs) => {
      if (!seenVSUrls.has(vs.url)) { seenVSUrls.add(vs.url); allValueSets.push(vs); }
    });
  });

  const library = generateCQLLibrary(questionnaire, analyses);
  const enrichedQuestionnaire = enrichQuestionnaire(questionnaire, analyses, library);
  const bundle = buildBundle(enrichedQuestionnaire, library, allValueSets);

  const stats = {
    totalItems: analyses.length,
    groups: analyses.filter((a) => a.type === "group").length,
    highConfidence: analyses.filter((a) => a.confidence === "high" && a.cqlExpression).length,
    mediumConfidence: analyses.filter((a) => a.confidence === "medium").length,
    manual: analyses.filter((a) => a.confidence === "none" && a.type !== "group").length,
    valueSetsGenerated: allValueSets.length,
  };
  const populatable = stats.highConfidence + stats.mediumConfidence;
  const total = stats.totalItems - stats.groups;
  stats.autoPopulationRate = total > 0 ? Math.round((populatable / total) * 100) : 0;

  return {
    enrichedQuestionnaire,
    cqlLibrary: { name: library.libraryName, url: library.libraryUrl, cql: library.cql, resource: library.libraryResource },
    valueSets: allValueSets,
    questionnairePackageBundle: bundle,
    itemAnalyses: analyses,
    stats,
  };
}

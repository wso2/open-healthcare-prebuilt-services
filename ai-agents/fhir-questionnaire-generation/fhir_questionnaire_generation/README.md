# FHIR Questionnaire Generation

The **FHIR Questionnaire Generation** module provides the functionality to **generate FHIR Questionnaire resources** using a collaborative system of AI agents.

Under the `/fhir_questionnaire_agents` directory, two agents are implemented:

* **Generator Agent** – responsible for creating the initial FHIR Questionnaire resource.
* **Reviewer Agent** – reviews and validates the generated questionnaire to ensure quality, accuracy, and compliance.

The **`fhir_questionnaire_orchestration`** service acts as a **file-listener** that monitors the `/prompts` directory for extracted scenario details. Once a new scenario is detected, it triggers the **Generator Agent** to create the FHIR Questionnaire. The orchestration layer manages the structured conversation between the **Generator** and **Reviewer** agents to produce a refined and validated output.

Upon successful generation, the final FHIR Questionnaire resources are sent to the **Policy Processor Service** via its `/questionnaire` endpoint. These questionnaires can later be retrieved through the Policy Processor’s API.

---

## Prerequisites

* **Ballerina** must be installed on your system.
  👉 [Download Ballerina](https://ballerina.io/downloads/)

---

## Configuration

The service uses configurable parameters defined in the orchestration module.

| Parameter                            | Description                                                                |
| ------------------------------------ | -------------------------------------------------------------------------- |
| **POLICY_FLOW_ORCHESTRATOR**         | Base URL of the Policy Processor service to post generated questionnaires. |
| **FHIR_QUESTIONNAIRE_GENERATOR_URL** | Endpoint of the Generator Agent.                                           |
| **FHIR_REVIEWER_URL**                | Endpoint of the Reviewer Agent.                                            |
| **FTP Settings**                     | Connection details for FTP-based communication and prompt retrieval.       |
| **AGENT_CONV_LIMIT**                 | Maximum number of review iterations between Generator and Reviewer agents. |

Below is an example configuration:

```toml
configurable string POLICY_FLOW_ORCHESTRATOR = "http://localhost:6080"

configurable string FHIR_QUESTIONNAIRE_GENERATOR_URL = "http://localhost:7082/QuestionnaireGenerator"
configurable string FHIR_REVIEWER_URL = "http://localhost:7081/Reviewer"

configurable string FTP_HOST = ""
configurable int FTP_PORT = 2121
configurable string FTP_USERNAME = ""
configurable string FTP_PASSWORD = ""

configurable int AGENT_CONV_LIMIT = 5
```

---

## Running the Service

To start the **FHIR Questionnaire Generation** orchestration service:

1. **Navigate** to the orchestration directory:

   ```bash
   cd fhir_questionnaire_generation_orchestration
   ```

2. **Run** the service:

   ```bash
   bal run
   ```

Before starting, ensure:

* Both the **Generator** and **Reviewer** agents are running.
* The **FTP server** is accessible and configured correctly.

---

## Notes

* The orchestration logic ensures human-like collaboration between AI agents, enhancing the reliability of generated FHIR resources.
* Generated questionnaires are automatically posted to the **Policy Processor Service**, which serves as the central access point for retrieval and further integration.

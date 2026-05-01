# FHIR Questionnaire Generator Agent

The **FHIR Questionnaire Generator Agent** is responsible for creating **FHIR Questionnaire resources** based on user inputs and predefined templates.
It leverages **AI capabilities** to interpret user requirements, structure questions, and generate standards-compliant **FHIR Questionnaires** that can be directly used in healthcare data workflows.

This agent operates as part of the **FHIR Questionnaire Generation pipeline**, collaborating with the **Reviewer Agent** and the orchestration service to ensure quality and accuracy.

---

## Configuration

Before running the **Questionnaire Generator Agent**, ensure the following environment variables are set:
- **Anthropic API Key**: Required for accessing the Anthropic AI services.

```sh
ANTHROPOIC_API_KEY=<your_anthropic_api_key>
```

## Running the Service

1. **Run** the service using Ballerina:

   ```bash
   bal run
   ```

2. Once started, the **Questionnaire Generator Agent** will be available at:
   **`http://localhost:7082/QuestionnaireGenerator`**

---

## Notes

* Ensure all necessary configuration and dependencies are set before running the agent.
* This service is designed to be triggered by the **FHIR Questionnaire Orchestration** layer rather than accessed directly.
* The generated questionnaires follow the **HL7 FHIR** standard, ensuring interoperability across systems.

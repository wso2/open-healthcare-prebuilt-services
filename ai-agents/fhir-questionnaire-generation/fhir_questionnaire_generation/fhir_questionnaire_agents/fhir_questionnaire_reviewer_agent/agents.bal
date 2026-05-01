// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).

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

import ballerina/ai;
import ballerinax/ai.anthropic;


final anthropic:ModelProvider _ReviewerModel = check new (ANTHROPIC_API_KEY, "claude-sonnet-4-20250514", serviceUrl = ANTHROPIC_REVIEWER_AGENT_AI_GATEWAY_URL);
final ai:Agent _ReviewerAgent = check new (
    systemPrompt = {
        role: "You are an expert FHIR validator and clinical logic analyst. Your primary function is to review a generated FHIR Questionnaire to ensure it is structurally sound. You should make sure that the questionnaire",
        instructions: string `
        ## Your Goal
        Your task is to meticulously review the provided FHIR Questionnaire JSON. You will then generate a concise feedback report in Markdown, highlighting any discrepancies, errors, or areas for improvement. This feedback is intended for the AI agent that originally created the questionnaire, so it must be clear, specific, and actionable.
        ## Inputs You Will Receive
        **FHIR Questionnaire**: The JSON object of the questionnaire that needs to be reviewed.
        ## Validation Criteria (Your Checklist)
        You must check the questionnaire against the following criteria:
            ### 1\. Structural Integrity
                * **Correct Resource Type**: Is the resourceType correctly set to Questionnaire?
                * **Essential Metadata**: Does it have a status of draft, a title, and a unique id?
                * **Item Structure**:
                * Does every item have a unique, sequential linkId?
                * Is the text of each question a clear and accurate representation of the criterion from the source context?
                * Is the type for each item appropriate (e.g., boolean for yes/no, choice for selection, group for sectioning)?
            ### 2\. Logical Accuracy
                * **Grouping**: Does the questionnaire use nested group items to correctly represent the nested logic (e.g., \\"One of the following\\" that contains a \\"Both of the following\\") from the source document?
                * **Conditional Logic (enableWhen)**:
                * Are enableWhen conditions used correctly to show or hide questions based on previous answers?
                * Does the enableWhen.question correctly reference the linkId of the controlling question?
                * Is the enableWhen.operator and answer[x] combination logical and correct? For instance, if a question about \\"headache days per month\\" is only relevant for patients with \\"4 to 7 migraine days,\\" is the enableWhen condition set up correctly to enforce this?
            ### 3\. Completeness and Fidelity
                * **Full Coverage**: Have all criteria from *both* the \\"initial therapy\\" and \\"continuation of therapy\\" sections been converted into questionnaire items?
                * **No Extraneous Items**: Are there any questions in the questionnaire that do not correspond to a criterion in the source text?
                * **Correct Values**: Are the specific values from the text accurately reflected in the questions or answer choices (e.g., \\"at least two months,\\" \\"4 to 7 migraine days\\")?
        ## Required Output Format (Your Feedback Report)
        Provide your feedback in a Markdown report. Start with an overall assessment and then list specific, actionable recommendations. IF THERE IS NO FEEDBACK, STATE \"APPROVED\".
            ### Example Feedback Report:
                ## FHIR Questionnaire Review
                **Overall Assessment**: Fails. The questionnaire is structurally valid but contains critical logical errors that do not accurately reflect the source policy.
                ### Feedback & Recommendations 
                * **[LOGICAL ERROR]**: The group item for the \\"4 to 7 migraine days\\" and \\"8 or more migraine days\\" conditions is structured as a flat list. It fails to represent the primary \\"One of the following\\" choice. **Suggestion**: Restructure this into a parent group item with a controlling question that asks the user to select one of the two main pathways.
                * **[MISSING CONDITION]**: The enableWhen logic is missing for the question regarding \\"less than 15 headache days per month.\\" This question should only appear after the user confirms the patient has \\"4 to 7 migraine days.\\" **Suggestion**: Add an enableWhen condition to item with linkId '1.2.1.1' that depends on the answer to the item with linkId '1.2'.
                * **[INCOMPLETE]**: State if it missed any criteria from the source text.
                * **[CLARITY]**: The question for prophylactic therapies is a single \\"Yes/No.\\" It doesn't allow the user to specify *which two* therapies were trialed. **Suggestion**: Change the item type to choice with repeats: true and list the therapy options so a user can select the specific ones that apply.
        ## Satisfaction of Criteria
        If there are no issues found, respond with:
        APPROVED
        Do not include any additional comments other than <<APPROVED>>, if no issues are found.
        `
    }, memory = new ai:MessageWindowChatMemory(5), model = _ReviewerModel, tools = [], verbose = true
);

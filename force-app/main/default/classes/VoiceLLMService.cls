public with sharing class VoiceLLMService {

    @TestVisible
    private static String mockLlmResponse = null;

    public class LLMDecision {
        @AuraEnabled public String actionType;      // UPDATE_STATUS, LOG_NOTE, CREATE_TASK, INFORMATIONAL
        @AuraEnabled public String statusValue;     // Closed, In Progress, Completed
        @AuraEnabled public String summaryText;     // Extracted notes, parts, or task subject
        @AuraEnabled public String spokenResponse;  // Natural voice reply for Text-to-Speech
        @AuraEnabled public String rawLlmOutput;    // Raw output for audit logging
    }

    /**
     * @description Grounding method that fetches record details to feed into the Prompt Template.
     * @param recordId Contextual Salesforce record ID.
     * @return Formatted record details string for LLM grounding.
     */
    public static String getRecordContext(String recordId) {
        if (String.isBlank(recordId)) {
            return 'No active record context attached.';
        }

        try {
            Id recId = (Id) recordId;
            String sObjName = recId.getSObjectType().getDescribe().getName();

            if (sObjName.equalsIgnoreCase('Case')) {
                List<Case> cases = [
                    SELECT Id, CaseNumber, Subject, Status, Priority, Description,
                           (SELECT Id, Subject, Status, Priority, ActivityDate, Description 
                            FROM Tasks 
                            ORDER BY CreatedDate DESC LIMIT 5)
                    FROM Case 
                    WHERE Id = :recId 
                    LIMIT 1
                ];
                if (!cases.isEmpty()) {
                    Case c = cases[0];
                    String details = 'Object: Case | CaseNumber: ' + c.CaseNumber + ' | Subject: ' + c.Subject + 
                                     ' | Current Status: ' + c.Status + ' | Priority: ' + c.Priority +
                                     ' | Description: ' + (String.isNotBlank(c.Description) ? c.Description : 'None');
                    
                    if (c.Tasks != null && !c.Tasks.isEmpty()) {
                        details += ' | Related Tasks (' + c.Tasks.size() + '): ';
                        List<String> taskSummaries = new List<String>();
                        for (Task t : c.Tasks) {
                            String tDesc = String.isNotBlank(t.Description) ? (' - ' + t.Description) : '';
                            String tDate = (t.ActivityDate != null) ? (' Due: ' + String.valueOf(t.ActivityDate)) : '';
                            taskSummaries.add('[' + t.Subject + ' | Status: ' + t.Status + tDate + tDesc + ']');
                        }
                        details += String.join(taskSummaries, '; ');
                    } else {
                        details += ' | Related Tasks: No tasks logged yet.';
                    }
                    return details;
                }
            } else if (sObjName.equalsIgnoreCase('Account')) {
                Account acc = [SELECT Id, Name, Type FROM Account WHERE Id = :recId LIMIT 1];
                return 'Object: Account | Name: ' + acc.Name + ' | Type: ' + acc.Type;
            }
            return 'Object: ' + sObjName + ' | Id: ' + recordId;
        } catch (Exception ex) {
            return 'Record ID provided: ' + recordId;
        }
    }

    /**
     * @description Formulates the Prompt Builder template grounded with record context.
     * @param prompt Raw voice transcript from user.
     * @param recordId Contextual Salesforce record ID.
     * @return Complete prompt string ready for LLM consumption.
     */
    public static String buildPromptTemplate(String prompt, String recordId) {
        String context = getRecordContext(recordId);

        String template = 
            'You are an intelligent Field Service Voice Assistant for Salesforce.\n' +
            'Active Record Context: ' + context + '\n' +
            'Technician Spoken Input: "' + prompt + '"\n\n' +
            'Analyze the technician\'s input and record context. Your job is twofold:\n' +
            '1. Extract the structured CRM action (UPDATE_STATUS, LOG_NOTE, CREATE_TASK, or SUMMARIZE_CASE to synthesize the case and its tasks).\n' +
            '2. Generate a concise, natural spoken reply (under 2 sentences, no markdown, no emojis) to be read aloud via Text-to-Speech.\n\n' +
            'Respond ONLY with a valid JSON object matching this schema:\n' +
            '{\n' +
            '  "actionType": "SUMMARIZE_CASE" | "UPDATE_STATUS" | "LOG_NOTE" | "CREATE_TASK" | "INFORMATIONAL",\n' +
            '  "statusValue": "Closed" | "In Progress" | "Completed" | null,\n' +
            '  "summaryText": "<structured executive summary of case and related tasks, notes, or task subject>",\n' +
            '  "spokenResponse": "<short conversational response to read back to the technician>"\n' +
            '}';

        return template;
    }

    /**
     * @description Analyzes the user voice prompt using Prompt Builder / LLM and returns structured decision.
     * @param prompt Natural language transcript from technician.
     * @param recordId Contextual Salesforce record ID.
     * @return LLMDecision containing action parameters and conversational speech.
     */
    public static LLMDecision analyzeVoicePrompt(String prompt, String recordId) {
        String promptText = buildPromptTemplate(prompt, recordId);
        String llmOutputJson;

        if (Test.isRunningTest() && String.isNotBlank(mockLlmResponse)) {
            llmOutputJson = mockLlmResponse;
        } else {
            llmOutputJson = executeLlmReasoning(prompt, recordId, promptText);
        }

        LLMDecision decision;
        try {
            decision = (LLMDecision) JSON.deserialize(llmOutputJson, LLMDecision.class);
            decision.rawLlmOutput = llmOutputJson;
        } catch (Exception ex) {
            // Fallback decision if LLM JSON parsing fails
            decision = new LLMDecision();
            decision.actionType = 'INFORMATIONAL';
            decision.summaryText = prompt;
            decision.spokenResponse = 'Understood. I have logged your request: ' + prompt + '.';
            decision.rawLlmOutput = llmOutputJson;
        }

        return decision;
    }

    public static final String TEMPLATE_NAME = 'Field_Service_Voice_Assistant';

    /**
     * @description Executes the LLM reasoning engine by invoking Salesforce Native Einstein GenAI / Prompt Builder
     * for the 'Field Service Voice Assistant' template. Falls back gracefully to the semantic parser if
     * ConnectApi is offline or during testing.
     */
    private static String executeLlmReasoning(String prompt, String recordId, String promptText) {
        if (!Test.isRunningTest()) {
            try {
                ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
                promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
                promptInput.additionalConfig.applicationName = 'PromptBuilder';

                Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();

                // 1. Pass the technician's spoken voice transcript
                ConnectApi.WrappedValue promptVal = new ConnectApi.WrappedValue();
                promptVal.value = prompt;
                inputParams.put('Input:UserPrompt', promptVal);

                // 2. Pass contextual record ID if active
                if (String.isNotBlank(recordId)) {
                    ConnectApi.WrappedValue recordVal = new ConnectApi.WrappedValue();
                    recordVal.value = new Map<String, String>{ 'id' => recordId };
                    inputParams.put('Input:ContextRecord', recordVal);
                }

                promptInput.inputParams = inputParams;

                // Call Einstein GenAI for the Field Service Voice Assistant prompt template
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(TEMPLATE_NAME, promptInput);

                if (response != null && response.generations != null && !response.generations.isEmpty()) {
                    String generatedText = response.generations[0].text;
                    if (String.isNotBlank(generatedText)) {
                        return cleanJsonOutput(generatedText);
                    }
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'Einstein GenAI (' + TEMPLATE_NAME + ') invocation failed: ' + ex.getMessage() + '. Falling back to local semantic parser.');
            }
        }

        return executeFallbackReasoning(prompt, recordId);
    }

    private static String cleanJsonOutput(String rawText) {
        if (String.isBlank(rawText)) {
            return rawText;
        }
        String clean = rawText.trim();
        if (clean.startsWith('```json')) {
            clean = clean.substring(7);
        } else if (clean.startsWith('```')) {
            clean = clean.substring(3);
        }
        if (clean.endsWith('```')) {
            clean = clean.substring(0, clean.length() - 3);
        }
        return clean.trim();
    }

    /**
     * @description Fallback semantic parser used when Einstein GenAI is unprovisioned, rate-limited, or during tests.
     */
    private static String executeFallbackReasoning(String prompt, String recordId) {
        String lowerPrompt = prompt.toLowerCase();
        LLMDecision d = new LLMDecision();

        // 0. Case & Related Tasks Summarization Intent (Catches 'summarise', 'summarize', 'summary', 'overview')
        if (lowerPrompt.contains('summar') || lowerPrompt.contains('overview') || 
            lowerPrompt.contains('brief') || 
            (lowerPrompt.contains('case') && (lowerPrompt.contains('task') || lowerPrompt.contains('detail')))) {

            CaseSummaryBundle bundle = generateCaseTasksSummaryBundle(recordId);
            d.actionType = 'SUMMARIZE_CASE';
            d.statusValue = null;
            d.summaryText = bundle.detailedSummary;
            d.spokenResponse = bundle.spokenSummary;
            return JSON.serialize(d);
        }

        // 1. Task Creation Intent (only when NOT asking for a summary)
        if (!lowerPrompt.contains('summar') && 
            (lowerPrompt.contains('task') || lowerPrompt.contains('remind') || 
             lowerPrompt.contains('follow up') || lowerPrompt.contains('follow-up') || 
             lowerPrompt.contains('schedule'))) {

            String taskSubject = cleanPromptText(prompt, new List<String>{'create a task', 'create task', 'create a follow up task', 'remind me to', 'schedule a task'});
            d.actionType = 'CREATE_TASK';
            d.statusValue = null;
            d.summaryText = taskSubject;
            d.spokenResponse = 'Understood. Follow-up task created for tomorrow: ' + taskSubject + '.';
            return JSON.serialize(d);
        }

        // 2. Field Note Logging Intent
        if (lowerPrompt.contains('note') || lowerPrompt.contains('observation') || 
            lowerPrompt.contains('feedback') || lowerPrompt.contains('inspection')) {

            String noteText = cleanPromptText(prompt, new List<String>{'log a note', 'log note', 'record summary', 'visit summary', 'inspection note'});
            d.actionType = 'LOG_NOTE';
            d.statusValue = null;
            d.summaryText = noteText;
            d.spokenResponse = 'Got it. Field note successfully saved and attached.';
            return JSON.serialize(d);
        }

        // 3. Status Update Intent
        if (lowerPrompt.contains('status') || lowerPrompt.contains('close') || 
            lowerPrompt.contains('closed') || lowerPrompt.contains('mark') || 
            lowerPrompt.contains('progress') || lowerPrompt.contains('complete')) {

            String status = 'Completed';
            if (lowerPrompt.contains('in progress') || lowerPrompt.contains('progress') || lowerPrompt.contains('working')) {
                status = 'In Progress';
            } else if (lowerPrompt.contains('close') || lowerPrompt.contains('closed')) {
                status = 'Closed';
            }

            d.actionType = 'UPDATE_STATUS';
            d.statusValue = status;
            d.summaryText = prompt;
            d.spokenResponse = 'Confirmed. Status updated to ' + status + '.';
            return JSON.serialize(d);
        }

        // 4. Informational / Query Intent
        d.actionType = 'INFORMATIONAL';
        d.statusValue = null;
        d.summaryText = prompt;
        d.spokenResponse = 'Confirmed. I have logged your request: ' + prompt + '.';
        return JSON.serialize(d);
    }

    public class CaseSummaryBundle {
        public String detailedSummary;
        public String spokenSummary;
    }

    /**
     * @description Synthesizes both a written executive summary and a natural spoken summary for audio Text-to-Speech.
     */
    public static CaseSummaryBundle generateCaseTasksSummaryBundle(String recordId) {
        CaseSummaryBundle bundle = new CaseSummaryBundle();

        if (String.isBlank(recordId)) {
            // Locate most recently modified open Case if no recordId provided
            List<Case> recent = [SELECT Id FROM Case WHERE IsClosed = false ORDER BY LastModifiedDate DESC LIMIT 1];
            if (!recent.isEmpty()) {
                recordId = recent[0].Id;
            } else {
                bundle.detailedSummary = 'No active Case record found to summarize.';
                bundle.spokenSummary = 'No active Case record was found to summarize.';
                return bundle;
            }
        }

        try {
            Id recId = (Id) recordId;
            if (recId.getSObjectType().getDescribe().getName().equalsIgnoreCase('Case')) {
                Case c = [
                    SELECT Id, CaseNumber, Subject, Status, Priority, Description,
                           (SELECT Id, Subject, Status, Priority, ActivityDate, Description 
                            FROM Tasks 
                            ORDER BY CreatedDate DESC LIMIT 10)
                    FROM Case 
                    WHERE Id = :recId 
                    LIMIT 1
                ];

                String summary = '=== AI Case & Tasks Executive Summary ===\n';
                summary += 'Case Number: #' + c.CaseNumber + '\n';
                summary += 'Subject: ' + c.Subject + '\n';
                summary += 'Status: ' + c.Status + ' | Priority: ' + c.Priority + '\n';
                if (String.isNotBlank(c.Description)) {
                    summary += 'Details: ' + c.Description + '\n';
                }

                summary += '\n--- Related Task Activities (' + (c.Tasks != null ? c.Tasks.size() : 0) + ') ---\n';
                if (c.Tasks != null && !c.Tasks.isEmpty()) {
                    for (Task t : c.Tasks) {
                        String due = (t.ActivityDate != null) ? (' [Due: ' + String.valueOf(t.ActivityDate) + ']') : '';
                        String taskDesc = String.isNotBlank(t.Description) ? (' - ' + t.Description) : '';
                        summary += '• ' + t.Subject + ' (' + t.Status + ')' + due + taskDesc + '\n';
                    }
                } else {
                    summary += '• No related tasks logged on this case yet.\n';
                }
                bundle.detailedSummary = summary;

                // Build rich natural voice reply for Text-to-Speech audio output
                String spoken = 'Here is the summary for Case #' + c.CaseNumber + ', ' + c.Subject + '. ' +
                                'The current status is ' + c.Status + ' with ' + c.Priority + ' priority. ';
                if (c.Tasks != null && !c.Tasks.isEmpty()) {
                    spoken += 'There are ' + c.Tasks.size() + ' related task activities: ';
                    List<String> taskNames = new List<String>();
                    for (Task t : c.Tasks) {
                        taskNames.add(t.Subject + ' marked as ' + t.Status);
                    }
                    spoken += String.join(taskNames, ', ') + '. ';
                } else {
                    spoken += 'There are no related tasks logged yet. ';
                }
                spoken += 'The full summary has been saved to the Case record.';
                bundle.spokenSummary = spoken;

                return bundle;
            }
            bundle.detailedSummary = 'Summary generated for record ID: ' + recordId;
            bundle.spokenSummary = 'Summary generated for record ID ' + recordId;
            return bundle;
        } catch (Exception ex) {
            bundle.detailedSummary = 'Case summary generated for context record ' + recordId + ': ' + ex.getMessage();
            bundle.spokenSummary = 'Here is the case summary: ' + ex.getMessage();
            return bundle;
        }
    }

    public static String generateCaseTasksSummary(String recordId) {
        return generateCaseTasksSummaryBundle(recordId).detailedSummary;
    }

    private static String cleanPromptText(String text, List<String> prefixes) {
        String result = text.trim();
        for (String prefix : prefixes) {
            if (result.toLowerCase().startsWith(prefix)) {
                result = result.substring(prefix.length()).trim();
                if (result.startsWith(':') || result.startsWith('-') || result.startsWith('that')) {
                    result = result.substring(1).trim();
                }
                break;
            }
        }
        return String.isNotBlank(result) ? result : text;
    }
}
public with sharing class AgentforceVoiceController {

    @TestVisible
    private static Boolean forceExceptionInTest = false;

    public class InteractionPayload {
        @AuraEnabled public String prompt { get; set; }
        @AuraEnabled public String recordId { get; set; }
    }

    public class InteractionResult {
        @AuraEnabled public String responseText { get; set; }
        @AuraEnabled public Id logId { get; set; }
    }

    /**
     * @description Processes voice utterance from LWC, routes to Agentforce, and persists audit logs.
     * @param payloadJson JSON serialized InteractionPayload containing prompt and recordId.
     * @return InteractionResult containing conversational response and log record ID.
     */
    @AuraEnabled
    public static InteractionResult processVoiceInteraction(String payloadJson) {
        if (String.isBlank(payloadJson)) {
            throw new AuraHandledException('Payload cannot be empty.');
        }

        InteractionPayload payload;
        try {
            payload = (InteractionPayload) JSON.deserialize(payloadJson, InteractionPayload.class);
        } catch (Exception e) {
            throw new AuraHandledException('Malformed payload: ' + e.getMessage());
        }

        if (payload == null || String.isBlank(payload.prompt)) {
            throw new AuraHandledException('User prompt cannot be blank.');
        }

        InteractionResult result = new InteractionResult();
        Voice_Interaction_Log__c log = new Voice_Interaction_Log__c(
            User_Prompt__c = payload.prompt,
            Related_Record_Id__c = payload.recordId,
            Status__c = 'Success'
        );

        try {
            if (Test.isRunningTest() && forceExceptionInTest) {
                throw new CalloutException('Forced Agentforce timeout or execution error for testing.');
            }

            // Route prompt through Agentforce reasoning or local action handler
            String agentReply = dispatchToAgentforce(payload.prompt, payload.recordId);

            result.responseText = agentReply;
            log.Agent_Response__c = agentReply;

            // Commit audit log
            insert log;
            result.logId = log.Id;
            return result;
        } catch (Exception ex) {
            log.Status__c = 'Error';
            log.Error_Message__c = ex.getMessage() + '\n' + ex.getStackTraceString();
            try {
                insert log;
            } catch (Exception logEx) {
                // Prevent secondary logging failure from masking primary exception
            }
            throw new AuraHandledException('Agentforce execution error: ' + ex.getMessage());
        }
    }

    /**
     * @description Dispatches prompt through Prompt Builder grounding, LLM reasoning, and executes resulting CRM actions.
     * @param prompt Natural language transcript from technician.
     * @param recordId Contextual Salesforce record ID.
     * @return Conversational reply suitable for browser Text-to-Speech (TTS).
     */
    private static String dispatchToAgentforce(String prompt, String recordId) {
        // 1. Analyze prompt through Prompt Builder template & LLM reasoning engine
        VoiceLLMService.LLMDecision decision = VoiceLLMService.analyzeVoicePrompt(prompt, recordId);

        // 2. If decision requires a CRM Action, invoke FieldServiceVoiceActions
        if (decision.actionType == 'SUMMARIZE_CASE' || decision.actionType == 'UPDATE_STATUS' || decision.actionType == 'LOG_NOTE' || decision.actionType == 'CREATE_TASK') {
            FieldServiceVoiceActions.VoiceActionRequest req = new FieldServiceVoiceActions.VoiceActionRequest();
            req.actionType = decision.actionType;
            req.recordId = recordId;
            req.statusValue = decision.statusValue;
            req.summaryText = decision.summaryText;

            List<FieldServiceVoiceActions.VoiceActionResult> actionResults = 
                FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>{ req });

            if (!actionResults.isEmpty() && actionResults[0].isSuccess) {
                // If action result has custom message, prefer the spoken confirmation
                return String.isNotBlank(decision.spokenResponse) ? decision.spokenResponse : ('Confirmed. ' + actionResults[0].message);
            }
        }

        // 3. Return the LLM's conversational spoken response
        return String.isNotBlank(decision.spokenResponse) ? decision.spokenResponse : ('Confirmed. I have logged your request: "' + prompt + '".');
    }
}
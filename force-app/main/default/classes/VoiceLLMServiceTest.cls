@IsTest
private class VoiceLLMServiceTest {

    @IsTest
    static void testRecordContextAndPromptBuilding() {
        Case c = new Case(Subject = 'Compressor Pressure Leak', Status = 'New', Priority = 'High');
        insert c;

        Account acc = new Account(Name = 'Global Apex Facility', Type = 'Customer - Direct');
        insert acc;

        Test.startTest();
        String caseContext = VoiceLLMService.getRecordContext(c.Id);
        String accContext = VoiceLLMService.getRecordContext(acc.Id);
        String nullContext = VoiceLLMService.getRecordContext(null);
        String template = VoiceLLMService.buildPromptTemplate('Check oil levels', c.Id);
        Test.stopTest();

        System.assert(caseContext.contains('Compressor Pressure Leak'), 'Context should contain Case subject');
        System.assert(accContext.contains('Global Apex Facility'), 'Context should contain Account name');
        System.assertEquals('No active record context attached.', nullContext);
        System.assert(template.contains('Check oil levels'), 'Prompt template should contain spoken transcript');
    }

    @IsTest
    static void testTaskCreationDecision() {
        Test.startTest();
        VoiceLLMService.LLMDecision decision = VoiceLLMService.analyzeVoicePrompt('create a follow up task to inspect the cooling coils', null);
        Test.stopTest();

        System.assertEquals('CREATE_TASK', decision.actionType);
        System.assert(decision.spokenResponse.contains('Follow-up task created'));
    }

    @IsTest
    static void testNoteLoggingDecision() {
        Test.startTest();
        VoiceLLMService.LLMDecision decision = VoiceLLMService.analyzeVoicePrompt('log note: replaced gasket and tested under 50 psi', null);
        Test.stopTest();

        System.assertEquals('LOG_NOTE', decision.actionType);
        System.assert(decision.spokenResponse.contains('Field note successfully saved'));
    }

    @IsTest
    static void testStatusUpdateDecision() {
        Test.startTest();
        VoiceLLMService.LLMDecision decision = VoiceLLMService.analyzeVoicePrompt('close this case immediately', null);
        Test.stopTest();

        System.assertEquals('UPDATE_STATUS', decision.actionType);
        System.assertEquals('Closed', decision.statusValue);
    }

    @IsTest
    static void testInformationalDecisionAndJsonFallback() {
        Test.startTest();
        VoiceLLMService.LLMDecision infoDecision = VoiceLLMService.analyzeVoicePrompt('What is the procedure for emergency shutdown?', null);

        // Test custom mock response with markdown wrapping
        VoiceLLMService.mockLlmResponse = '```json\n{\n  "actionType": "CREATE_TASK",\n  "statusValue": null,\n  "summaryText": "Inspect valve",\n  "spokenResponse": "Task created."\n}\n```';
        VoiceLLMService.LLMDecision markdownDecision = VoiceLLMService.analyzeVoicePrompt('Inspect valve', null);

        // Test custom mock response and fallback on malformed JSON
        VoiceLLMService.mockLlmResponse = '{ malformed json }';
        VoiceLLMService.LLMDecision fallbackDecision = VoiceLLMService.analyzeVoicePrompt('Any question', null);
        Test.stopTest();

        System.assertEquals('INFORMATIONAL', infoDecision.actionType);
        System.assertEquals('CREATE_TASK', markdownDecision.actionType);
        System.assertEquals('INFORMATIONAL', fallbackDecision.actionType);
    }

    @IsTest
    static void testSummarizeCaseDecision() {
        Case c = new Case(Subject = 'Hydraulic Motor Failure', Status = 'In Progress', Priority = 'High', Description = 'Motor seized under 100 bar');
        insert c;

        Task t = new Task(WhatId = c.Id, Subject = 'Inspect motor bearings', Status = 'Completed', ActivityDate = Date.today());
        insert t;

        Test.startTest();
        VoiceLLMService.LLMDecision decision = VoiceLLMService.analyzeVoicePrompt('Please summarize this case and all related tasks', c.Id);
        Test.stopTest();

        System.assertEquals('SUMMARIZE_CASE', decision.actionType);
        System.assert(decision.summaryText.contains('Hydraulic Motor Failure'));
        System.assert(decision.summaryText.contains('Inspect motor bearings'));
    }
}
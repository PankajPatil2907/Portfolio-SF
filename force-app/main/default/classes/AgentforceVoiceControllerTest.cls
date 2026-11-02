@IsTest
private class AgentforceVoiceControllerTest {

    @IsTest
    static void testSuccessfulStatusInteraction() {
        Case c = new Case(Subject = 'Field Heating Inspection', Status = 'New');
        insert c;

        AgentforceVoiceController.InteractionPayload payload = new AgentforceVoiceController.InteractionPayload();
        payload.prompt = 'Close work order. Filter replaced and tests passed.';
        payload.recordId = c.Id;

        Test.startTest();
        AgentforceVoiceController.InteractionResult result = 
            AgentforceVoiceController.processVoiceInteraction(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.logId, 'Log ID should be populated');
        System.assert(result.responseText.contains('Case status successfully updated') || result.responseText.contains('Confirmed'), 
            'Expected conversational confirmation');

        Voice_Interaction_Log__c log = [
            SELECT Id, User_Prompt__c, Agent_Response__c, Status__c, Related_Record_Id__c, Error_Message__c 
            FROM Voice_Interaction_Log__c 
            WHERE Id = :result.logId
        ];
        System.assertEquals('Success', log.Status__c, 'Status should be Success');
        System.assertEquals(payload.prompt, log.User_Prompt__c, 'Prompt should match');
        System.assertEquals(c.Id, log.Related_Record_Id__c, 'Related record ID should match');
        System.assertEquals(null, log.Error_Message__c, 'Error message should be null');
    }

    @IsTest
    static void testSuccessfulTaskIntent() {
        Account acc = new Account(Name = 'Skyline Facilities');
        insert acc;

        AgentforceVoiceController.InteractionPayload payload = new AgentforceVoiceController.InteractionPayload();
        payload.prompt = 'Remind me to follow up next week on equipment calibration.';
        payload.recordId = acc.Id;

        Test.startTest();
        AgentforceVoiceController.InteractionResult result = 
            AgentforceVoiceController.processVoiceInteraction(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result.logId);
        System.assert(result.responseText.contains('task') || result.responseText.contains('Understood'));
    }

    @IsTest
    static void testSuccessfulNoteIntent() {
        AgentforceVoiceController.InteractionPayload payload = new AgentforceVoiceController.InteractionPayload();
        payload.prompt = 'Log note: Customer satisfied with current maintenance cycle.';
        payload.recordId = null;

        Test.startTest();
        AgentforceVoiceController.InteractionResult result = 
            AgentforceVoiceController.processVoiceInteraction(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result.logId);
        System.assert(result.responseText.contains('saved') || result.responseText.contains('Got it'));
    }

    @IsTest
    static void testSuccessfulGenericIntent() {
        AgentforceVoiceController.InteractionPayload payload = new AgentforceVoiceController.InteractionPayload();
        payload.prompt = 'What is the current warranty status on this component?';
        payload.recordId = null;

        Test.startTest();
        AgentforceVoiceController.InteractionResult result = 
            AgentforceVoiceController.processVoiceInteraction(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result.logId);
        System.assert(result.responseText.contains('Confirmed'));
    }

    @IsTest
    static void testSuccessfulSummarizeCaseIntent() {
        Case c = new Case(Subject = 'Turbine Leak', Status = 'In Progress', Description = 'Initial diagnosis shows gasket crack');
        insert c;

        Task t = new Task(WhatId = c.Id, Subject = 'Order replacement gasket', Status = 'Completed');
        insert t;

        AgentforceVoiceController.InteractionPayload payload = new AgentforceVoiceController.InteractionPayload();
        payload.prompt = 'Summarize this case and its tasks';
        payload.recordId = c.Id;

        Test.startTest();
        AgentforceVoiceController.InteractionResult result = 
            AgentforceVoiceController.processVoiceInteraction(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result.logId);
        System.assert(result.responseText.contains('summary') || result.responseText.contains('Turbine Leak') || result.responseText.contains('saved'));
    }

    @IsTest
    static void testBlankPayloadValidation() {
        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            AgentforceVoiceController.processVoiceInteraction('');
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }
        Test.stopTest();

        System.assert(exceptionCaught, 'Blank payload should throw AuraHandledException');
    }

    @IsTest
    static void testBlankPromptValidation() {
        AgentforceVoiceController.InteractionPayload payload = new AgentforceVoiceController.InteractionPayload();
        payload.prompt = '';
        payload.recordId = null;

        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            AgentforceVoiceController.processVoiceInteraction(JSON.serialize(payload));
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }
        Test.stopTest();

        System.assert(exceptionCaught, 'Blank prompt should throw AuraHandledException');
    }

    @IsTest
    static void testMalformedJsonValidation() {
        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            AgentforceVoiceController.processVoiceInteraction('{ malformed-json: true }');
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }
        Test.stopTest();

        System.assert(exceptionCaught, 'Malformed JSON should throw AuraHandledException');
    }

    @IsTest
    static void testErrorAuditLogging() {
        AgentforceVoiceController.forceExceptionInTest = true;

        AgentforceVoiceController.InteractionPayload payload = new AgentforceVoiceController.InteractionPayload();
        payload.prompt = 'Check maintenance schedule';
        payload.recordId = '001000000000000AAA';

        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            AgentforceVoiceController.processVoiceInteraction(JSON.serialize(payload));
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }
        Test.stopTest();

        System.assert(exceptionCaught, 'Forced exception should throw AuraHandledException');

        // Verify that an audit record with Status='Error' was inserted into the database
        List<Voice_Interaction_Log__c> errorLogs = [
            SELECT Id, User_Prompt__c, Status__c, Error_Message__c 
            FROM Voice_Interaction_Log__c 
            WHERE Status__c = 'Error'
        ];
        System.assert(!errorLogs.isEmpty(), 'An error audit log must be persisted even on failure');
        System.assert(errorLogs[0].Error_Message__c.contains('Forced Agentforce timeout'));
    }
}
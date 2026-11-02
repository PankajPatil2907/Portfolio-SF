@IsTest
private class FieldServiceVoiceActionsTest {

    @IsTest
    static void testUpdateStatusOnCase() {
        Case c = new Case(Subject = 'Test Equipment Repair', Status = 'New');
        insert c;

        FieldServiceVoiceActions.VoiceActionRequest req = new FieldServiceVoiceActions.VoiceActionRequest();
        req.recordId = c.Id;
        req.actionType = 'UPDATE_STATUS';
        req.statusValue = 'Closed';
        req.summaryText = 'Filter replaced and unit tested successfully.';

        Test.startTest();
        List<FieldServiceVoiceActions.VoiceActionResult> results = 
            FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isSuccess, 'Action should succeed');
        System.assert(results[0].message.contains('Closed'), 'Result message should mention status');

        Case updatedCase = [SELECT Status, Description FROM Case WHERE Id = :c.Id];
        System.assertEquals('Closed', updatedCase.Status, 'Case status should be updated');
    }

    @IsTest
    static void testUpdateStatusWithoutRecordId() {
        FieldServiceVoiceActions.VoiceActionRequest req = new FieldServiceVoiceActions.VoiceActionRequest();
        req.actionType = 'UPDATE_STATUS';
        req.statusValue = 'Completed';

        Test.startTest();
        List<FieldServiceVoiceActions.VoiceActionResult> results = 
            FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
    }

    @IsTest
    static void testUpdateStatusOnAccount() {
        Account acc = new Account(Name = 'ACME Field Site');
        insert acc;

        FieldServiceVoiceActions.VoiceActionRequest req = new FieldServiceVoiceActions.VoiceActionRequest();
        req.recordId = acc.Id;
        req.actionType = 'UPDATE_STATUS';
        req.statusValue = 'Completed';
        req.summaryText = 'Work on site verified.';

        Test.startTest();
        List<FieldServiceVoiceActions.VoiceActionResult> results = 
            FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
    }

    @IsTest
    static void testLogNote() {
        Account acc = new Account(Name = 'Global Tech Client');
        insert acc;

        FieldServiceVoiceActions.VoiceActionRequest req = new FieldServiceVoiceActions.VoiceActionRequest();
        req.recordId = acc.Id;
        req.actionType = 'LOG_NOTE';
        req.summaryText = 'Customer requested additional quarterly inspection.';

        Test.startTest();
        List<FieldServiceVoiceActions.VoiceActionResult> results = 
            FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
        System.assert(results[0].message.contains('successfully saved'));

        List<Task> tasks = [SELECT Id, Subject, Description FROM Task WHERE WhatId = :acc.Id];
        System.assert(!tasks.isEmpty(), 'A Task should be created for note');
    }

    @IsTest
    static void testCreateTask() {
        Contact con = new Contact(LastName = 'Smith', Email = 'smith@example.com');
        insert con;

        FieldServiceVoiceActions.VoiceActionRequest req = new FieldServiceVoiceActions.VoiceActionRequest();
        req.recordId = con.Id;
        req.actionType = 'CREATE_TASK';
        req.summaryText = 'Call technician lead for signoff';

        Test.startTest();
        List<FieldServiceVoiceActions.VoiceActionResult> results = 
            FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
        System.assert(results[0].message.contains('Follow-up task created'));
    }

    @IsTest
    static void testDefaultActionAndEmptyInput() {
        Test.startTest();
        List<FieldServiceVoiceActions.VoiceActionResult> emptyResults = 
            FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>());
        System.assertEquals(0, emptyResults.size());

        FieldServiceVoiceActions.VoiceActionRequest req = new FieldServiceVoiceActions.VoiceActionRequest();
        req.actionType = 'UNKNOWN_INTENT';
        req.summaryText = 'Check spare parts catalog';

        List<FieldServiceVoiceActions.VoiceActionResult> defaultResults = 
            FieldServiceVoiceActions.executeVoiceAction(new List<FieldServiceVoiceActions.VoiceActionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, defaultResults.size());
        System.assert(defaultResults[0].isSuccess);
    }
}
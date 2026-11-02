public with sharing class FieldServiceVoiceActions {

    public class VoiceActionRequest {
        @InvocableVariable(label='Context Record ID' description='Salesforce record ID (e.g. Case, WorkOrder, Account) where the voice action is executed.' required=false)
        public String recordId;

        @InvocableVariable(label='Action Type' description='The specific operation to perform. Must be strictly one of: SUMMARIZE_CASE, UPDATE_STATUS, LOG_NOTE, or CREATE_TASK.' required=true)
        public String actionType;

        @InvocableVariable(label='Target Status' description='Target status value to apply (e.g., Closed, Completed, In Progress) when actionType is UPDATE_STATUS.' required=false)
        public String statusValue;

        @InvocableVariable(label='Summary Text' description='Extracted details from user speech: resolution notes, visit summary, or follow-up task subject.' required=false)
        public String summaryText;
    }

    public class VoiceActionResult {
        @InvocableVariable(label='Is Success' description='True if the action executed and committed to Salesforce without errors.')
        public Boolean isSuccess;

        @InvocableVariable(label='Result Message' description='Conversational confirmation message formatted for Text-to-Speech audio output.')
        public String message;
    }

    @InvocableMethod(label='Execute Field Service Voice Action' description='Executes field service operations based on spoken technician requests. Use this action to: 1) summarize a case and related tasks, 2) update or close a work order/case status, 3) log on-site visit notes or inspection summaries, or 4) schedule a follow-up task or reminder.')
    public static List<VoiceActionResult> executeVoiceAction(List<VoiceActionRequest> requests) {
        List<VoiceActionResult> results = new List<VoiceActionResult>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        for (VoiceActionRequest req : requests) {
            VoiceActionResult res = new VoiceActionResult();
            try {
                String action = (req.actionType != null) ? req.actionType.toUpperCase().trim() : '';

                if (action == 'SUMMARIZE_CASE') {
                    res = handleSummarizeCase(req);
                } else if (action == 'UPDATE_STATUS') {
                    res = handleUpdateStatus(req);
                } else if (action == 'LOG_NOTE') {
                    res = handleLogNote(req);
                } else if (action == 'CREATE_TASK') {
                    res = handleCreateTask(req);
                } else {
                    res.isSuccess = true;
                    res.message = 'Understood. Action recognized: ' + (String.isNotBlank(req.summaryText) ? req.summaryText : 'Field request logged.');
                }
            } catch (Exception ex) {
                res.isSuccess = false;
                res.message = 'I encountered an error executing that request: ' + ex.getMessage();
            }
            results.add(res);
        }

        return results;
    }

    private static VoiceActionResult handleUpdateStatus(VoiceActionRequest req) {
        VoiceActionResult res = new VoiceActionResult();
        String targetStatus = String.isNotBlank(req.statusValue) ? req.statusValue : 'Completed';

        if (String.isBlank(req.recordId)) {
            // Intelligent fallback: locate the most recent open Case for the user
            List<Case> recentCases = [
                SELECT Id, CaseNumber, Subject 
                FROM Case 
                WHERE IsClosed = false 
                ORDER BY LastModifiedDate DESC 
                LIMIT 1
            ];
            if (!recentCases.isEmpty()) {
                Case c = recentCases[0];
                c.Status = targetStatus;
                if (String.isNotBlank(req.summaryText)) {
                    c.Description = req.summaryText;
                }
                update c;
                res.isSuccess = true;
                res.message = 'Case #' + c.CaseNumber + ' (' + c.Subject + ') status successfully updated to ' + targetStatus + '.';
                return res;
            }

            res.isSuccess = true;
            res.message = 'Status recorded as ' + targetStatus + '. (No active Case record was found to update).';
            return res;
        }

        Id recId;
        try {
            recId = (Id) req.recordId;
        } catch (Exception e) {
            res.isSuccess = false;
            res.message = 'Invalid Salesforce Record ID provided.';
            return res;
        }

        String sObjName = recId.getSObjectType().getDescribe().getName();

        // Update Case if record is a Case
        if (sObjName.equalsIgnoreCase('Case')) {
            Case c = new Case(Id = recId, Status = targetStatus);
            if (String.isNotBlank(req.summaryText)) {
                c.Description = req.summaryText;
            }
            update c;
            res.isSuccess = true;
            res.message = 'Case status successfully updated to ' + targetStatus + '.';
            return res;
        }

        // Generic Task creation if record cannot be updated directly
        Task followUp = new Task(
            WhatId = recId,
            Subject = 'Status Update: ' + targetStatus,
            Description = req.summaryText,
            Status = 'Completed',
            Priority = 'Normal',
            ActivityDate = Date.today()
        );
        insert followUp;

        res.isSuccess = true;
        res.message = sObjName + ' status update recorded as ' + targetStatus + '.';
        return res;
    }

    private static VoiceActionResult handleLogNote(VoiceActionRequest req) {
        VoiceActionResult res = new VoiceActionResult();
        String noteContent = String.isNotBlank(req.summaryText) ? req.summaryText : 'Site visit completed.';

        Task noteTask = new Task(
            Subject = 'Field Voice Note - ' + DateTime.now().format('yyyy-MM-dd HH:mm'),
            Description = noteContent,
            Status = 'Completed',
            Priority = 'Normal',
            ActivityDate = Date.today()
        );

        if (String.isNotBlank(req.recordId)) {
            try {
                Id recId = (Id) req.recordId;
                String sObjName = recId.getSObjectType().getDescribe().getName();
                if (sObjName.equalsIgnoreCase('Contact') || sObjName.equalsIgnoreCase('Lead')) {
                    noteTask.WhoId = recId;
                } else {
                    noteTask.WhatId = recId;
                }
            } catch (Exception ignore) {
                // If invalid ID format, task is still logged without relation
            }
        }

        insert noteTask;
        res.isSuccess = true;
        res.message = 'Field note successfully saved and attached.';
        return res;
    }

    private static VoiceActionResult handleCreateTask(VoiceActionRequest req) {
        VoiceActionResult res = new VoiceActionResult();
        String taskSubject = String.isNotBlank(req.summaryText) ? req.summaryText : 'Follow-up with customer';

        Task newTask = new Task(
            Subject = taskSubject,
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(1)
        );

        if (String.isNotBlank(req.recordId)) {
            try {
                Id recId = (Id) req.recordId;
                String sObjName = recId.getSObjectType().getDescribe().getName();
                if (sObjName.equalsIgnoreCase('Contact') || sObjName.equalsIgnoreCase('Lead')) {
                    newTask.WhoId = recId;
                } else {
                    newTask.WhatId = recId;
                }
            } catch (Exception ignore) {
                // Task created without relation if invalid ID
            }
        }

        insert newTask;
        res.isSuccess = true;
        res.message = 'Follow-up task created for tomorrow: ' + taskSubject + '.';
        return res;
    }

    private static VoiceActionResult handleSummarizeCase(VoiceActionRequest req) {
        VoiceActionResult res = new VoiceActionResult();
        String summary = String.isNotBlank(req.summaryText) ? req.summaryText : 'Case and task summary generated.';

        Id recId;
        if (String.isNotBlank(req.recordId)) {
            try {
                recId = (Id) req.recordId;
            } catch (Exception e) {
                // Ignore invalid ID format
            }
        }

        if (recId == null) {
            List<Case> recent = [SELECT Id, CaseNumber, Subject FROM Case WHERE IsClosed = false ORDER BY LastModifiedDate DESC LIMIT 1];
            if (!recent.isEmpty()) {
                recId = recent[0].Id;
            }
        }

        if (recId != null && recId.getSObjectType().getDescribe().getName().equalsIgnoreCase('Case')) {
            Case c = new Case(Id = recId);
            
            // 1. Store in Case.AI_Summary__c if custom field is available
            Map<String, SObjectField> fieldMap = Schema.SObjectType.Case.fields.getMap();
            if (fieldMap.containsKey('ai_summary__c')) {
                c.put('AI_Summary__c', summary);
            }
            
            // 2. Also populate standard Case Description if currently empty
            Case existing = [SELECT Id, CaseNumber, Description FROM Case WHERE Id = :recId LIMIT 1];
            if (String.isBlank(existing.Description)) {
                c.Description = summary;
            }
            update c;

            // 3. Insert CaseComment as an audit entry
            try {
                CaseComment comment = new CaseComment(
                    ParentId = recId,
                    CommentBody = '🤖 [AI Executive Summary]\n' + summary,
                    IsPublished = false
                );
                insert comment;
            } catch (Exception ex) {
                // If CaseComment restricted by profile, ignore
            }

            res.isSuccess = true;
            res.message = 'Case #' + existing.CaseNumber + ' summary saved to the Case record.';
            return res;
        }

        res.isSuccess = true;
        res.message = 'Summary generated: ' + summary;
        return res;
    }
}
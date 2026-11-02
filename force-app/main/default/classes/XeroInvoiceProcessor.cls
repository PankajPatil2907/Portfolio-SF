public class XeroInvoiceProcessor {

    // ── Statuses to skip entirely (never upsert or delete) ────────────────
    private static final Set<String> EXCLUDED_STATUSES = new Set<String>{
        'DRAFT', 'DELETED', 'VOIDED'
    };

    // ─────────────────────────────────────────────────────────────────────
    public static void process(List<XeroInvoiceParser.XeroInvoice> invoices) {
        if (invoices == null || invoices.isEmpty()) return;

        Set<String>   excludedContacts = getExcludedContacts();
        List<Xero_Error_Log__c> errorLogs = new List<Xero_Error_Log__c>();

        // ── 1. Collect all Xero Invoice IDs so we can look up what already
        //       exists in Salesforce (needed for delete decisions).         ──
        Set<String> allXeroIds = new Set<String>();
        for (XeroInvoiceParser.XeroInvoice inv : invoices) {
            if (inv.InvoiceID != null) allXeroIds.add(inv.InvoiceID);
        }

        // existingInvoiceMap: XeroInvoiceId → Salesforce record Id
        Map<String, Id> existingInvoiceMap = new Map<String, Id>();
        for (Xero_Invoice__c sfInv : [
            SELECT Id, Xero_Invoice_Id__c
            FROM   Xero_Invoice__c
            WHERE  Xero_Invoice_Id__c IN :allXeroIds
        ]) {
            existingInvoiceMap.put(sfInv.Xero_Invoice_Id__c, sfInv.Id);
        }

        // ── 2. Separate invoices into three buckets ──────────────────────
        //    • toUpsert  – valid invoices (build SF records)
        //    • toDelete  – invalid invoices that already exist in SF
        //    • (skip)    – status-excluded, never seen before → ignore
        List<XeroInvoiceParser.XeroInvoice> eligibleInvoices    = new List<XeroInvoiceParser.XeroInvoice>();
        Set<String> xeroIdsToDelete     = new Set<String>();

        // Collect project numbers and contact names for bulk queries
        Set<String> projectNumbers = new Set<String>();
        Set<String> contactNames   = new Set<String>();

        for (XeroInvoiceParser.XeroInvoice inv : invoices) {

            // ── 2a. Status exclusion – skip silently ─────────────────────
            if (EXCLUDED_STATUSES.contains(inv.Status?.toUpperCase())) {
                // If a formerly-valid invoice flips to DRAFT/VOIDED/DELETED
                // in Xero we also want to remove it from SF.
                if (existingInvoiceMap.containsKey(inv.InvoiceID)) {
                    xeroIdsToDelete.add(inv.InvoiceID);
                    errorLogs.add(makeErrorLog(
                        inv.InvoiceID, inv.InvoiceNumber,
                        'Invoice status changed to ' + inv.Status + ' – removed from Salesforce.'
                    ));
                }
                continue;
            }

            // ── 2b. Excluded contact ──────────────────────────────────────
            if (inv.Contact != null && excludedContacts.contains(inv.Contact.Name)) {
                if (existingInvoiceMap.containsKey(inv.InvoiceID)) {
                    xeroIdsToDelete.add(inv.InvoiceID);
                    errorLogs.add(makeErrorLog(
                        inv.InvoiceID, inv.InvoiceNumber,
                        'Contact "' + inv.Contact.Name + '" is in the excluded contacts list – removed from Salesforce.'
                    ));
                }
                continue; // don't upsert
            }

            eligibleInvoices.add(inv);

            String projNum = XeroInvoiceParser.extractProjectNumber(inv);
            if (projNum != null) projectNumbers.add(projNum);
            if (inv.Contact?.Name != null) contactNames.add(inv.Contact.Name);
        }

        // ── 3. Bulk Salesforce lookups ────────────────────────────────────
        Map<String, Project__c> projectMap = new Map<String, Project__c>();
        for (Project__c p : [
            SELECT Id, Name, Client__c, Client__r.Name
            FROM   Project__c
            WHERE  Name IN :projectNumbers
        ]) {
            projectMap.put(p.Name, p);
        }

        // ── 4. Validate each eligible invoice ────────────────────────────
        List<Xero_Invoice__c>  toUpsert = new List<Xero_Invoice__c>();
        Map<Xero_Invoice_Line_Item__c, String> liToInvoiceXeroId = new Map<Xero_Invoice_Line_Item__c, String>();

        for (XeroInvoiceParser.XeroInvoice inv : eligibleInvoices) {

            String projNum   = XeroInvoiceParser.extractProjectNumber(inv);
            String contactNm = inv.Contact?.Name;

            // ── 4a. Project conflict across line items ────────────────────
            // extractProjectNumber returns null when lines conflict.
            // Distinguish "no tracking at all" vs "conflict":
            Boolean hasTrackingLines = invoiceHasProjectTracking(inv);
            Boolean projectConflict  = hasTrackingLines && projNum == null;

            if (projectConflict) {
                errorLogs.add(makeErrorLog(
                    inv.InvoiceID, inv.InvoiceNumber,
                    'Conflicting Project tracking across line items – invoice is invalid.'
                ));
                if (existingInvoiceMap.containsKey(inv.InvoiceID)) {
                    xeroIdsToDelete.add(inv.InvoiceID);
                }
                continue;
            }

            // ── 4b. Project lookup (when a project number is present) ─────
            Project__c matchedProject = (projNum != null) ? projectMap.get(projNum) : null;

            if (projNum != null && matchedProject == null) {
                errorLogs.add(makeErrorLog(
                    inv.InvoiceID, inv.InvoiceNumber,
                    'No matching Project found in Salesforce for Project Number: ' + projNum
                ));
                if (existingInvoiceMap.containsKey(inv.InvoiceID)) {
                    xeroIdsToDelete.add(inv.InvoiceID);
                }
                continue;
            }

            // ── 4c. Contact / Account name mismatch ──────────────────────
            String accountName = matchedProject?.Client__r?.Name;
            if (matchedProject != null && accountName != contactNm) {
                errorLogs.add(makeErrorLog(
                    inv.InvoiceID, inv.InvoiceNumber,
                    'Contact "' + contactNm + '" does not match Account "' + accountName
                    + '" derived from Project – invoice is invalid.'
                ));
                if (existingInvoiceMap.containsKey(inv.InvoiceID)) {
                    xeroIdsToDelete.add(inv.InvoiceID);
                }
                continue;
            }

            // ── 4d. Invoice is valid → build upsert record ────────────────
            Xero_Invoice__c sfInv        = new Xero_Invoice__c();
            sfInv.Name                   = inv.InvoiceNumber;
            sfInv.Xero_Invoice_Id__c     = inv.InvoiceID;
            sfInv.Reference__c           = inv.Reference;
            sfInv.Xero_Invoice_Status__c = inv.Status;
            sfInv.Invoice_Date__c        = XeroInvoiceParser.parseDate(inv.DateString);
            sfInv.Invoice_Due_Date__c    = XeroInvoiceParser.parseDate(inv.DueDateString);
            sfInv.Net_Amount__c          = inv.SubTotal;
            sfInv.Total_Amount__c        = inv.Total;
            sfInv.Amount_Paid__c         = XeroInvoiceParser.getTotalAmountPaid(inv);
            sfInv.Balance_Due__c         = inv.AmountDue;
            sfInv.Account__c             = matchedProject?.Client__c;
            sfInv.Project__c             = matchedProject?.Id;
            sfInv.Last_Synced__c         = DateTime.now();
            sfInv.Xero_Invoice_Url__c    = 'https://go.xero.com/AccountsReceivable/Edit.aspx?InvoiceID=' + inv.InvoiceID;
            toUpsert.add(sfInv);

            // ── 4e. Build line items ───────────────────────────────────────
            if (inv.LineItems != null) {
                for (XeroInvoiceParser.XeroLineItem line : inv.LineItems) {
                    Xero_Invoice_Line_Item__c li = new Xero_Invoice_Line_Item__c();
                    li.Name           = line.LineItemID;
                    li.Description__c = line.Description;
                    li.Quantity__c    = line.Quantity;
                    li.Price__c       = line.UnitAmount;
                    li.Tax_Amount__c  = line.TaxAmount;
                    li.Total__c       = line.LineAmount;
                    if (line.DiscountRate != null) {
                        li.Discount__c = line.DiscountRate;
                    }
                    if (line.Tracking != null) {
                        for (XeroInvoiceParser.XeroTracking t : line.Tracking) {
                            if (t.Name == 'Projects') {
                                li.Project__c = t.Option;
                            }
                        }
                    }
                    li.Xero_Invoice__c = null; // resolved after upsert
                    liToInvoiceXeroId.put(li, inv.InvoiceID);
                }
            }
        }

        // ── 5. Delete invalid records (invoices first, then line items) ───
        //
        // NOTE: If Xero_Invoice_Line_Item__c.Xero_Invoice__c is a Master-Detail
        // relationship the child records cascade-delete automatically.
        // If it is a Lookup relationship, query and delete children first.
        //
        if (!xeroIdsToDelete.isEmpty()) {
            deleteInvoicesAndChildren(xeroIdsToDelete, existingInvoiceMap, errorLogs);
        }

        // ── 6. Upsert valid invoices ──────────────────────────────────────
        if (!toUpsert.isEmpty()) {
            List<Database.UpsertResult> results =
                Database.upsert(toUpsert, Xero_Invoice__c.Name, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String msg = results[i].getErrors()[0].getMessage();
                    errorLogs.add(makeErrorLog(
                        toUpsert[i].Xero_Invoice_Id__c,
                        toUpsert[i].Name,
                        'Invoice upsert failed: ' + msg
                    ));
                }
            }
        }

        // ── 7. Re-query SF ids so we can link line items ──────────────────
        Set<String> upsertedXeroIds = new Set<String>();
        for (Xero_Invoice__c inv : toUpsert) {
            if (inv.Xero_Invoice_Id__c != null) upsertedXeroIds.add(inv.Xero_Invoice_Id__c);
        }

        Map<String, Id> freshInvoiceIdMap = new Map<String, Id>();
        for (Xero_Invoice__c rec : [
            SELECT Id, Xero_Invoice_Id__c
            FROM   Xero_Invoice__c
            WHERE  Xero_Invoice_Id__c IN :upsertedXeroIds
        ]) {
            freshInvoiceIdMap.put(rec.Xero_Invoice_Id__c, rec.Id);
        }

        // ── 8. Upsert line items ──────────────────────────────────────────
        List<Xero_Invoice_Line_Item__c> validLineItems = new List<Xero_Invoice_Line_Item__c>();
        for (Xero_Invoice_Line_Item__c li : liToInvoiceXeroId.keySet()) {
            String xeroId = liToInvoiceXeroId.get(li);
            li.Xero_Invoice__c = freshInvoiceIdMap.get(xeroId);
            if (li.Xero_Invoice__c != null && li.Name != null) {
                validLineItems.add(li);
            }
        }

        if (!validLineItems.isEmpty()) {
            List<Database.UpsertResult> liResults =
                Database.upsert(validLineItems, Xero_Invoice_Line_Item__c.Name, false);

            for (Integer i = 0; i < liResults.size(); i++) {
                if (!liResults[i].isSuccess()) {
                    String msg = liResults[i].getErrors()[0].getMessage();
                    errorLogs.add(makeErrorLog(
                        null,
                        validLineItems[i].Name,
                        'Line item upsert failed: ' + msg
                    ));
                }
            }
        }

        // ── 9. Insert error logs ──────────────────────────────────────────
        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Deletes SF invoices (and their line items) for the given Xero IDs.
     *
     * Strategy:
     *  1. Delete child line items first (handles Lookup relationships).
     *     For Master-Detail relationships this step is harmless redundancy.
     *  2. Delete parent invoices.
     *  3. Any delete failure is caught per-record and logged.
     */
    private static void deleteInvoicesAndChildren(
        Set<String>             xeroIdsToDelete,
        Map<String, Id>         existingInvoiceMap,
        List<Xero_Error_Log__c> errorLogs
    ) {
        // Resolve SF record ids for invoices we are about to delete
        Set<Id> sfInvoiceIds = new Set<Id>();
        for (String xeroId : xeroIdsToDelete) {
            Id sfId = existingInvoiceMap.get(xeroId);
            if (sfId != null) sfInvoiceIds.add(sfId);
        }

        if (sfInvoiceIds.isEmpty()) return;

        // ── Delete line items first (safe for both Lookup and Master-Detail) ─
        List<Xero_Invoice_Line_Item__c> childLines = [
            SELECT Id
            FROM   Xero_Invoice_Line_Item__c
            WHERE  Xero_Invoice__c IN :sfInvoiceIds
        ];

        if (!childLines.isEmpty()) {
            List<Database.DeleteResult> childResults =
                Database.delete(childLines, false);
            for (Integer i = 0; i < childResults.size(); i++) {
                if (!childResults[i].isSuccess()) {
                    errorLogs.add(makeErrorLog(
                        null,
                        childLines[i].Id,
                        'Line item delete failed: ' + childResults[i].getErrors()[0].getMessage()
                    ));
                }
            }
        }

        // ── Delete parent invoices ────────────────────────────────────────
        List<Xero_Invoice__c> invoicesToDelete = [
            SELECT Id, Xero_Invoice_Id__c, Name
            FROM   Xero_Invoice__c
            WHERE  Id IN :sfInvoiceIds
        ];

        if (!invoicesToDelete.isEmpty()) {
            List<Database.DeleteResult> delResults =
                Database.delete(invoicesToDelete, false);
            for (Integer i = 0; i < delResults.size(); i++) {
                if (!delResults[i].isSuccess()) {
                    errorLogs.add(makeErrorLog(
                        invoicesToDelete[i].Xero_Invoice_Id__c,
                        invoicesToDelete[i].Name,
                        'Invoice delete failed: ' + delResults[i].getErrors()[0].getMessage()
                    ));
                }
            }
        }
    }

    /**
     * Returns true if the invoice has at least one non-zero line item that
     * carries a "Projects" tracking category.  Used to distinguish a genuine
     * project-tracking conflict from a simple absence of tracking data.
     */
    private static Boolean invoiceHasProjectTracking(XeroInvoiceParser.XeroInvoice inv) {
        if (inv.LineItems == null) return false;
        for (XeroInvoiceParser.XeroLineItem line : inv.LineItems) {
            if (line.LineAmount == null || line.LineAmount == 0) continue;
            if (line.Tracking == null) continue;
            for (XeroInvoiceParser.XeroTracking t : line.Tracking) {
                if (t.Name != null &&
                    t.Name.equalsIgnoreCase(XeroInvoiceParser.PROJECT_TRACKING_NAME)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static Xero_Error_Log__c makeErrorLog(
        String xeroInvoiceId,
        String invoiceNumber,
        String reason
    ) {
        return new Xero_Error_Log__c(
            Xero_Invoice_Id__c = xeroInvoiceId,
            Invoice_Number__c  = invoiceNumber,
            Failure_Reason__c  = reason,
            TImestamp__c       = DateTime.now()
        );
    }

    private static Set<String> getExcludedContacts() {
        Set<String> result = new Set<String>();
        for (Xero_Invoice_Exclusion__mdt rec : [
            SELECT Label FROM Xero_Invoice_Exclusion__mdt
        ]) {
            result.add(rec.Label);
        }
        return result;
    }
}
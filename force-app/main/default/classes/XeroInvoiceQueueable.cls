public class XeroInvoiceQueueable implements Queueable, Database.AllowsCallouts {

    private DateTime lastSync;

    public XeroInvoiceQueueable(DateTime lastSync) {
        this.lastSync = lastSync;
    }

    public void execute(QueueableContext context) {
        Boolean isSuccess = false;

        try {
            isSuccess = XeroInvoiceRetriever.fetchInvoices(lastSync);

            if (isSuccess) {
                Xero_Sync_Config__c cfg = Xero_Sync_Config__c.getOrgDefaults();
                if (cfg == null) cfg = new Xero_Sync_Config__c();

                cfg.Last_Sync_Time__c = DateTime.now();
                upsert cfg;
            }

        } catch (Exception e) {
            System.debug('Xero sync failed: ' + e.getMessage());
        }
    }
}
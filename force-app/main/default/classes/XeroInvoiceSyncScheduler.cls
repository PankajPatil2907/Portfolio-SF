global class XeroInvoiceSyncScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        List<Xero_Tenant_Config__mdt> activeTenants = [SELECT Label, Tenant_Id__c, Is_Active__c FROM   Xero_Tenant_Config__mdt
            WHERE  Is_Active__c = true];
        System.debug('activeTenants>>>>'+activeTenants);    

        DateTime lastSync = getLastSyncTime();

        System.enqueueJob(new XeroInvoiceQueueable(lastSync));
    }

    
    public static void enqueueJobs(){
        System.schedule('Xero_Invoice_Sync - 10 Min of Every Hr', '0 10 00-23 ? * MON-SUN', new XeroInvoiceSyncScheduler());
        System.schedule('Xero_Invoice_Sync - 20 Min of Every Hr', '0 20 00-23 ? * MON-SUN', new XeroInvoiceSyncScheduler());
        System.schedule('Xero_Invoice_Sync - 30 Min of Every Hr', '0 30 00-23 ? * MON-SUN', new XeroInvoiceSyncScheduler());
        System.schedule('Xero_Invoice_Sync - 40 Min of Every Hr', '0 40 00-23 ? * MON-SUN', new XeroInvoiceSyncScheduler());
        System.schedule('Xero_Invoice_Sync - 50 Min of Every Hr', '0 50 00-23 ? * MON-SUN', new XeroInvoiceSyncScheduler());
        System.schedule('Xero_Invoice_Sync - 60 Min of Every Hr', '0 00 00-23 ? * MON-SUN', new XeroInvoiceSyncScheduler());
    }

    private static DateTime getLastSyncTime() {
        Xero_Sync_Config__c cfg = Xero_Sync_Config__c.getOrgDefaults();
        if (cfg != null && cfg.Last_Sync_Time__c != null) {
            return cfg.Last_Sync_Time__c;
        }
        return DateTime.now().addDays(-7);
    }
}
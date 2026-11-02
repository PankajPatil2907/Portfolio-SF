/**
 * XeroInvoiceRetriever
 * Fetches ALL invoices modified since lastSyncTime using Xero's page-based
 * pagination (required to receive LineItems in the response).
 *
 * Uses pagination.pageCount from the first response to know the total pages.
 */
public class XeroInvoiceRetriever {

    public static Boolean fetchInvoices(DateTime lastSyncTime) {
        Boolean isSuccess = true;
        String test = 'test';
        try {
            String formattedDate = formatToRFC1123(lastSyncTime);
            Integer currentPage  = 1;
            Integer totalPages   = null; 

            List<XeroInvoiceParser.XeroInvoice> allInvoices = new List<XeroInvoiceParser.XeroInvoice>();

            do {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Xero_Connection_Credential/api.xro/2.0/Invoices?page=' + currentPage);
                req.setMethod('GET');
                req.setHeader('If-Modified-Since', formattedDate);
                req.setHeader('Accept', 'application/json');
                req.setHeader('xero-tenant-id', Label.Xero_Tenant_Id);

                HttpResponse res = new Http().send(req);

                if (res.getStatusCode() == 200) {
                    XeroInvoiceParser.XeroInvoiceResponse parsed = XeroInvoiceParser.parse(res.getBody());

                    if (parsed == null || parsed.Invoices == null || parsed.Invoices.isEmpty()) {
                        break;
                    }
                    
                    // On first page, read totalPages from pagination block
                    if (totalPages == null) {
                        totalPages = (parsed.pagination != null && parsed.pagination.pageCount != null)
                            ? parsed.pagination.pageCount
                            : 1;
                    }

                    allInvoices.addAll(parsed.Invoices);
                    currentPage++;

                } else {
                    // Log API error and stop
                    insert new Xero_Error_Log__c(
                        Invoice_Number__c = 'SYSTEM ERROR',
                        Failure_Reason__c = 'Xero API call failed. HTTP '+ res.getStatusCode()+ ' | '+ res.getBody().left(5000),
                        TImestamp__c      = DateTime.now()
                    );
                    break;
                }

            } while (currentPage <= totalPages);

            if (!allInvoices.isEmpty()) {
                XeroInvoiceProcessor.process(allInvoices);
            }

        } catch (Exception e) {
            isSuccess = false;

            insert new Xero_Error_Log__c(
                Invoice_Number__c = 'SYSTEM ERROR',
                Failure_Reason__c = e.getMessage(),
                TImestamp__c = DateTime.now()
            );
        }

        return isSuccess;
    
    }

    private static String formatToRFC1123(DateTime dt) {
        return dt.formatGMT('EEE, dd MMM yyyy HH:mm:ss \'GMT\'');
    }
}
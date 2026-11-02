public class XeroRestApiUtility {
    public static HttpResponse executeCallout (String method, String resourceName) {
        return executeCallout(method, resourceName, null, null);
    }
    
    public static HttpResponse executeCallout (String method, String resourceName, String requestBody) {
        return executeCallout(method, resourceName, requestBody, null);
    }
    
    public static HttpResponse executeCallout (String method, String resourceName, String requestBody, Map<String, String> headers) {
        
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint('callout:Xero_Connection_Credential/' + 'api.xro/2.0/' + resourceName);
        request.setHeader('Accept', 'application/json');
        request.setHeader('xero-tenant-id', Label.Xero_Tenant_Id);
        request.setTimeout(120000);
        
        if (String.isNotBlank(requestBody)) {
            request.setBody(requestBody);
            request.setHeader('Content-Type', 'application/json');
        }
        
        HttpResponse response = new Http().send(request);
        
        system.debug('###  Callout Endpoint: ' + request.getEndpoint());
        system.debug('###  Callout Method: ' + request.getMethod());
        system.debug('###  Callout Body: ' + request.getBody());
        
        system.debug('###  Response Status: ' + response.getStatusCode() + ': ' + response.getStatus());
        system.debug('###  Response Body: ' + response.getBody());
        
        return response;
    } 
    
    // public static void getTenantId(){
    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint('callout:Xero_Connection_Credential/connections');
    //     req.setMethod('GET');
    //     req.setHeader('Accept', 'application/json');

    //     HttpResponse res = new Http().send(req);
    //     System.debug(res.getStatusCode());
    //     System.debug(res.getBody());

    // }

    public static void getTenantId() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Xero_Connection_Credential/connections');
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');

        HttpResponse res = new Http().send(req);

        System.debug('Status Code: ' + res.getStatusCode());

        if (res.getStatusCode() == 200) {
            List<Object> connections = (List<Object>) JSON.deserializeUntyped(res.getBody());

            for (Object obj : connections) {
                Map<String, Object> conn = (Map<String, Object>) obj;

                String tenantId = (String) conn.get('tenantId');
                String tenantName = (String) conn.get('tenantName');

                System.debug('Tenant Name: ' + tenantName + ' | Tenant Id: ' + tenantId);
            }
        } else {
            System.debug('Error Response: ' + res.getBody());
        }
    }
}
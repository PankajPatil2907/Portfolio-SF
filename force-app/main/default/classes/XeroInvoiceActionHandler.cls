/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : XeroInvoiceActionHandler
 * Author          : <YourName>
 * Created Date    : Apr 9, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Apr 9, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 9, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class XeroInvoiceActionHandler {

@AuraEnabled
public static void syncFromLWC(Datetime lastSyncTime) {

    Datetime finalSync;

    if (lastSyncTime != null) {
        finalSync = lastSyncTime;
    } else {
        finalSync = System.now().addMinutes(-10);
    }
    XeroInvoiceRetriever.fetchInvoices(finalSync);
}

}
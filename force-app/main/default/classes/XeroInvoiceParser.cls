/**
 * XeroInvoiceParser
 * Parses the raw JSON response from Xero /Invoices API (paginated, with LineItems).
 *
 * NOTES on field naming:
 *  - 'Date' and 'DueDate' are reserved words in Apex. Xero also provides
 *    'DateString' and 'DueDateString' (ISO format) which we use instead.
 *  - Tracking category for project matching is named "Projects" in this org.
 *  - AmountPaid in Salesforce = Xero AmountPaid + AmountCredited (payments + credits).
 */
public class XeroInvoiceParser {

    // ── Top-level response ─────────────────────────────────────────────────
    public class XeroInvoiceResponse {
        public cls_pagination pagination;
        public List<XeroInvoice> Invoices;
    }

    // ── Pagination ─────────────────────────────────────────────────────────
    public class cls_pagination {
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;   // use this to know total pages
        public Integer itemCount;
    }

    // ── Invoice ────────────────────────────────────────────────────────────
    public class XeroInvoice {
        public String  InvoiceID;
        public String  InvoiceNumber;
        public String  Reference;
        public String  Status;         
        public String  DateString;     
        public String  DueDateString;   
        public Decimal SubTotal;        // Net Amount
        public Decimal TotalTax;    
        public Decimal Total;          
        public Decimal AmountPaid;      
        public Decimal AmountCredited;  
        public Decimal AmountDue;       
        public XeroContact Contact;
        public List<XeroLineItem> LineItems;
    }

    // ── Contact ────────────────────────────────────────────────────────────
    public class XeroContact {
        public String ContactID;
        public String Name;
    }

    // ── Line Item ──────────────────────────────────────────────────────────
    public class XeroLineItem {
        public String LineItemID;
        public String  Description;
        public Decimal LineAmount;  
        public Decimal Quantity;
        public Decimal UnitAmount;
        public Decimal TaxAmount;
        public Decimal DiscountRate;
        public List<XeroTracking> Tracking;
    }

    // ── Tracking category ─────────────────────────────────────────────────
    public class XeroTracking {
        public String TrackingCategoryID;
        public String Name;    
        public String Option; 
    }

    // ── TRACKING CATEGORY NAME ─────────────────────────────────────────────
    // Change this if your Xero org uses a different name for the project tracking category
    public static final String PROJECT_TRACKING_NAME = 'Projects';

    // ── Parse ──────────────────────────────────────────────────────────────
    public static XeroInvoiceResponse parse(String jsonBody) {
        return (XeroInvoiceResponse) JSON.deserialize(jsonBody, XeroInvoiceResponse.class);
    }

    /**
     * Extracts the Project tracking option value from an invoice's line items.
     *
     * Rules (per requirements):
     *  - Only inspect lines with a non-null, non-zero LineAmount.
     *  - All such lines must share the same project option; if they conflict → return null.
     *  - If no "Projects" tracking found on any line → return null.
     *
     * Example from real data:
     *  INV-0012 has lines with P2, P2, P3 → conflict → returns null → logged as error
     *  INV-0011 has one line with P2 → returns "P2"
     */
    public static String extractProjectNumber(XeroInvoice inv) {
        if (inv.LineItems == null || inv.LineItems.isEmpty()) return null;

        String projectNumber = null;

        for (XeroLineItem line : inv.LineItems) {
            // Skip description-only lines (no amount)
            if (line.LineAmount == null || line.LineAmount == 0) continue;
            if (line.Tracking == null || line.Tracking.isEmpty()) continue;

            for (XeroTracking t : line.Tracking) {
                if (t.Name != null && t.Name.equalsIgnoreCase(PROJECT_TRACKING_NAME)) {
                    if (projectNumber == null) {
                        projectNumber = t.Option;
                    } else if (projectNumber != t.Option) {
                        // Conflicting project numbers across lines — log and skip
                        return null;
                    }
                }
            }
        }
        return projectNumber;
    }

    /**
     * Total amount paid including credits.
     * AmountPaid (cash) + AmountCredited (credit notes applied)
     */
    public static Decimal getTotalAmountPaid(XeroInvoice inv) {
        Decimal paid     = inv.AmountPaid     != null ? inv.AmountPaid     : 0;
        Decimal credited = inv.AmountCredited != null ? inv.AmountCredited : 0;
        return paid + credited;
    }

    /**
     * Safely parse "YYYY-MM-DDThh:mm:ss" → Salesforce Date.
     * Falls back to /Date(ms+0000)/ format if needed.
     */
    public static Date parseDate(String dtString) {
        if (String.isBlank(dtString)) return null;
        try {
            if (dtString.startsWith('/Date(')) {
                String msStr = dtString.substringAfter('/Date(').substringBefore('+');
                if (String.isBlank(msStr)) {
                    msStr = dtString.substringAfter('/Date(').substringBefore(')');
                }
                return DateTime.newInstance(Long.valueOf(msStr)).date();
            }
            return Date.valueOf(dtString.left(10)); // "YYYY-MM-DD"
        } catch (Exception e) {
            return null;
        }
    }
}
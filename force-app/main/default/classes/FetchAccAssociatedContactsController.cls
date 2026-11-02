public class FetchAccAssociatedContactsController {
    @AuraEnabled
    public static List<Contact> fetchRelatedContacts(Id accId) {
        List <Contact> lstContacts = new List <Contact>();
        lstContacts = [Select Id, Name, Email from Contact where AccountId =: accId]; 
        return lstContacts;  
    }

}
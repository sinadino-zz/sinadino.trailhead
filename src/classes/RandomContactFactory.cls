public class RandomContactFactory {
    
     public static List<Contact> generateRandomContacts(Integer numCts, String lastName) {
        List<Contact> cts = new List<Contact>();
        
        for(Integer i=0;i<numCts;i++) {
            Contact c = new Contact(FirstName='TestNumber' + i, LastName = lastName);
            cts.add(c);
        }
        
         return cts;
        
        }

        
        
    }
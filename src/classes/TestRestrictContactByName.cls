@isTest
public class TestRestrictContactByName {
        @isTest static void TestRestrictContactByNameMethod() {
                // Test data setup
                // Create an account with an opportunity, and then try to delete it
                // 
                // 
                // 
                // 
                // 
                
            Contact ct = new Contact ( FirstName= 'Test Linvio', LastName ='INVALIDNAME');
		//	insert ct;
               
                
                // Perform test
                Test.startTest();
                Database.SaveResult resultInsert = Database.insert(ct, false);
                Database.SaveResult resultUpdate = Database.update(ct, false);
                Test.stopTest();
        
                // Verify 
                // In this case the deletion should have been stopped by the trigger,
                // so verify that we got back an error.
                System.assert(!resultInsert.isSuccess());
                System.assert(resultInsert.getErrors().size() > 0);
                System.assertNotEquals('The Last Name "'+ ct.LastName + '"  is not allowed for DML',
                                     resultInsert.getErrors()[0].getMessage());
            
                 System.assert(!resultUpdate.isSuccess());
                System.assert(resultUpdate.getErrors().size() > 0);
                System.assertNotEquals('The Last Name "'+ ct.LastName + '"  is not allowed for DML',
                                     resultUpdate.getErrors()[0].getMessage());
    }
    
    
    
    
}
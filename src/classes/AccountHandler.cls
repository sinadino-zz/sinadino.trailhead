public class AccountHandler {
 //    To pass this challenge, create an Apex class that inserts a new account named after an incoming parameter.
 //    If the account is successfully inserted, the method should return the account record. 
 //    If a DML exception occurs, the method should return null.
    public static void insertNewAccount(String account_name){  
        
         Account acct = new Account(Name='account_name');
        
        try {
                    
                    insert acct;
                
        		} catch (DmlException e) {
                    System.debug('A DML exception has occurred: ' +
                                e.getMessage());
                }
                        
    	
    }
    
}
public without sharing class AccessControllerWithoutSharing {
// ---------------------------------------------------------------------------
// AccessControllerWithoutSharing class for PaymentConnect
// Copyright: Linvio, Inc.
// URL: www.linvio.com
// Last Update: 03/24/2016 
// ---------------------------------------------------------------------------      
        public List<SObject> dbQuery(String query) { return Database.query(query); }
        public Database.SaveResult dbInsert(sObject obj) { return Database.insert (obj); }
        public Database.SaveResult dbUpdate(sObject obj) { return Database.update (obj); }
        public Database.DeleteResult dbDelete(sObject obj) { return Database.delete( obj); }
        public Database.SaveResult[] dbInsert(sObject[] objList) { return Database.insert (objList); }
        public Database.SaveResult[] dbUpdate(sObject[] objList) { return Database.update (objList); }
        public Database.DeleteResult[] dbDelete(sObject[] objList) { return Database.delete( objList); }
        
 
        
}
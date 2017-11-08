public with sharing class EmgPayDepositController {

    
        public Opportunity currentRecord{get;set;}
    
        public EmgPayDepositController (){
        currentRecord = [SELECT Id, Name, Amount, Deposit__c FROM Opportunity WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        
        }
        
       public Opportunity getOpportunity(){
       return currentRecord;
           }
    
   }
public with sharing class OpportunityTab {

    List<Opportunity> Opp;
    
    public List<Opportunity> getOpp() {
        return Opp;
    }


    public PageReference opportunites() {
        
        Opp = [SELECT ID FROM Opportunity];
        
        return null;
    }

}
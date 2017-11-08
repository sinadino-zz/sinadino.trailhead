global with sharing class HotelRemoter {

    @RemoteAction
    global static List<sinadino__Hotel__c> findAll() {
        return [SELECT Id, Name, sinadino__Location__Latitude__s, sinadino__Location__Longitude__s
                    FROM sinadino__Hotel__c];
    }

}
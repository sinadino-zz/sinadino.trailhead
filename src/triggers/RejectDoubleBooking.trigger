trigger RejectDoubleBooking on sinadino__Session_Speaker__c (before insert, before update) {

    for(sinadino__Session_Speaker__c sessionSpeaker : trigger.new) {

        sinadino__Session__c session = [SELECT Id, sinadino__Session_Date__c FROM sinadino__Session__c
                                WHERE Id=:sessionSpeaker.sinadino__Session__c];

        List<sinadino__Session_Speaker__c> conflicts =
            [SELECT Id FROM sinadino__Session_Speaker__c
                WHERE sinadino__Speaker__c = :sessionSpeaker.sinadino__Speaker__c
                AND sinadino__Session__r.sinadino__Session_Date__c = :session.sinadino__Session_Date__c];

        if(!conflicts.isEmpty()){
            sessionSpeaker.addError('The speaker is already booked at that time');
        }

    }

}
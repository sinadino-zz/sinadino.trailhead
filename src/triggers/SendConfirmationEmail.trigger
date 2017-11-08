trigger SendConfirmationEmail on sinadino__Session_Speaker__c (after insert) {

    for(sinadino__Session_Speaker__c newItem : trigger.new) {

        // Retrieve session name and time + speaker name and email address
        List<sinadino__Session_Speaker__c> sessionSpeakers =
            [SELECT sinadino__Session__r.Name,
                    sinadino__Session__r.Session_Date__c,
                    sinadino__Speaker__r.First_Name__c,
                    sinadino__Speaker__r.Last_Name__c,
                 sinadino__Speaker__r.Email__c
             FROM sinadino__Session_Speaker__c WHERE Id=:newItem.Id];
                if(sessionSpeakers.size() > 0) {  
            // Send confirmation email if we know the speaker's email address
                sinadino__Session_Speaker__c sessionSpeaker = sessionSpeakers[0];
                 if (sessionSpeaker.sinadino__Speaker__r.Email__c != null) {
                    String address = sessionSpeaker.sinadino__Speaker__r.Email__c;
                    String subject = 'Speaker Confirmation';
                    String message = 'Dear ' + sessionSpeaker.sinadino__Speaker__r.First_Name__c +
                    ',\nYour session "' + sessionSpeaker.sinadino__Session__r.Name + '" on ' +
                    sessionSpeaker.sinadino__Session__r.sinadino__Session_Date__c + ' is confirmed.\n\n' +
                    'Thanks for speaking at the conference!';
                EmailManager.sendMail(address, subject, message);
            }
        }
    }

    
    
}
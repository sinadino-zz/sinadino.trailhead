public with sharing class ThankYouController {
    
    public pymt__PaymentX__c pymtRecord {get; set;}
    public Id pymtId {get; set;}
    public Boolean Basic {get; set; }
    public Boolean BasicPlus {get; set; }
    public Boolean Premmium {get; set; }
    public Boolean PremmiumPlus {get; set; }
    
    
    public ThankYouController() {
        
       this.Basic = false;
       this.BasicPlus = false;
       this.Premmium = false;
       this.PremmiumPlus = false;
        
        this.pymtId = ApexPages.currentPage().getParameters().get('pid');
        if (pymtId <> null) {
            this.pymtRecord = [SELECT Id,pymt__Amount__c FROM pymt__PaymentX__c WHERE Id = :pymtId ];
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No payment record id found.'));
                        
        }
        
        if ( pymtRecord.pymt__Amount__c == 10) this.Basic = true;
        if ( pymtRecord.pymt__Amount__c == 30) this.BasicPlus = true;
        if ( pymtRecord.pymt__Amount__c == 50) this.Premmium = true;
        if ( pymtRecord.pymt__Amount__c > 50) this.PremmiumPlus = true;
        
    }


    
    
   

}

/*

public PageReference saveChanges() {

        
        try {   
            // See if notifications need to be sent before saving record.
            String[] iaddresses = new String[]{};
            String[] caddresses = new String[]{};

            String[] distList = new String[]{}; 
            if (this.settings <> null && this.settings.Internal_Email_List__c <> null && this.settings.Internal_Email_List__c <> '') {
                distList = this.settings.Internal_Email_List__c.split(',');
            }
            if (this.notifySupport && distList.size()>0) {
                for (String addr :distList) {
                    iaddresses.add(addr);
                }
            }
            if (this.notifyCustomer){
                if (!String.isEmpty(this.caseRecord.SuppliedEmail)) {
                    caddresses.add(this.caseRecord.SuppliedEmail);
                } else if(this.caseRecord.Contact.Email <> null) {
                    caddresses.add(this.caseRecord.Contact.Email);
                }
                if (this.caseRecord.Additional_Contact__r.Email <> null) {
                    caddresses.add(this.caseRecord.Additional_Contact__r.Email);
                }
            }
            String bodyText = 'Case Subject: '+this.caseRecord.Subject;
            bodyText += '\n\nA comment has been added or updated for case # '+this.caseRecord.CaseNumber+' in the Linvio support system.';
            bodyText += '\n\nAccount: '+this.caseRecord.Account.Name;
            bodyText += '\nContact: '+this.caseRecord.Contact.Firstname+ ' '+this.caseRecord.Contact.Lastname;
            bodyText += '\n\nCase Comment:\n\n'+this.comment.CommentBody;
            bodyText += '\n\nView/post comments to your case at: '+'http://linvio.com/portal/case_detail.php?caseId='+comment.parentId;
            bodyText += '\n\n*** DO NOT REPLY DIRECTLY TO THIS EMAIL. PLEASE LOG IN TO THE SUPPORT CASE PORTAL AT http://linvio.com/portal AND POST COMMENTS THERE. REPLIES TO THIS EMAIL WILL NOT POST TO YOUR CASE ***';
            //String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + comment.parentId;
            String fullRecordURL = '\nhttps://na5.salesforce.com/' + comment.parentId;
                            
            
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'donotreply@linvio.com'];
            
            if (caddresses.size()>0) {
                // Notify customer addressees
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(caddresses);
                if (owea.size()>0) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                } else {
                    mail.setReplyTo('support@linvio.com');  // doesn't work
                    mail.setSenderDisplayName('Linvio Support');
                }
                mail.setSubject('Case Comment Notification');
                mail.setPlainTextBody(bodyText);
                if (Test.isRunningTest() == false) {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
                
            }
            Set<string> iaddressSet = new Set<string>{};
            iaddressSet.addAll(iaddresses);
            if (iaddressSet.size() ==0 || !iaddressSet.contains('ron@linvio.com')) {
                iaddresses.add('ron@linvio.com');
            }
            if (iaddresses.size()>0) {
                // Notify internal addressees
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(iaddresses);
                if (owea.size()>0) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                } else {
                    mail.setReplyTo('donotreply@linvio.com');  // doesn't work
                    mail.setSenderDisplayName('Linvio Support');
                }
                mail.setSubject('Case Comment Notification. Case number '+caseRecord.CaseNumber);
                String internalBodyText = bodyText +'\n'+fullRecordURL+ '\n\nPosted By: '+ UserInfo.getName() +'\n\nCase Owner:'+caseRecord.owner.name ;
                
                mail.setPlainTextBody(internalBodyText);
                if (Test.isRunningTest() == false) {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
            }
            
            // Save record  
            upsert this.comment;
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return null;
        }
        return cancelEdit();
    
    }

*/
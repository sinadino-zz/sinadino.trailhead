// ---------------------------------------------------------------------------
// SiteQuoteApproval Test Class for PaymentConnect Stand Alone SiteQuote
// Developer: Cristiano Sinadino
// Copyright: Linvio, Inc.
// URL: www.linvio.com
// Last Update: 09/15/2016
// ---------------------------------------------------------------------------

@isTest
private class SiteQuoteApprovalTest {

    public static testmethod void testSiteQuoteApprovalController() {
        
        // --------------- Set up records for test scenarios ------------------
        
        // Check to make sure settings record has been created, and PC is in Simulation Mode (to
        // prevent API callouts from being made during test method execution.
        pymt__Settings__c settings = new pymt__Settings__c();
        settings.name = 'ApexTestSettings';
        settings.pymt__Gateway_Simulation_Mode__c = true;                    
        insert settings;
        
        // Add processor connections
        pymt__Processor_Connection__c connection1 = new pymt__Processor_Connection__c(
                name = 'ApexTestProcessorConnection1',
                pymt__PaymentConnect_Setup__c = settings.id,
                pymt__Assigned_To_Terminal__c = true,
                pymt__Default_Connection__c = true,
                pymt__Processor_Id__c = 'Authorize.Net',
                pymt__Enabled_Card_Types__c = 'Visa;Mastercard',
                pymt__Authnet_Enable_Echecks__c = true);
            Database.SaveResult sr =    Database.insert(connection1);
            System.assert(sr.isSuccess(), 'Error inserting test processor connection object. '+sr);     
        pymt__Processor_Connection__c connection2 = new pymt__Processor_Connection__c(
                name = 'ApexTestProcessorConnection2',
                pymt__PaymentConnect_Setup__c = settings.id,
                pymt__Assigned_To_Terminal__c = true,
                pymt__Processor_Id__c = 'PayPal',
                pymt__Authnet_Enable_Echecks__c = false);
            sr =    Database.insert(connection2);
            System.assert(sr.isSuccess(), 'Error inserting test processor connection object: '+sr);     
                    
        System.assert( settings.Id <> null, 'Error finding/creating settings record for test methods to use.');
 
        // Retrieve a closed/won stage
        String stagename = [Select o.MasterLabel, o.IsClosed, o.IsActive From OpportunityStage o where o.IsClosed = true and o.IsWon = true limit 1].MasterLabel;
        
        String apexTestLabel = 'ApexTestSiteQuoteApprovalPageController';
        
        Account[] accounts = [Select id from Account where isDeleted = false and name = :apexTestLabel ];
        if (accounts != null && accounts.size() > 0) delete accounts;
        Account account = new Account( name = apexTestLabel, BillingState = 'CA' );
        insert account;
         
        Contact[] contacts = [Select id from Contact where isDeleted = false and lastname = :apexTestLabel];
        if (contacts != null && contacts.size() > 0) delete contacts;
        Contact contact = new Contact(firstname = 'Albert', 
                                      lastname = apexTestLabel,
                                      mailingstreet = '123 Test Street',
                                      mailingcity = 'Encinitas',
                                      mailingstate = 'CA',
                                      mailingpostalcode = '92024',
                                      mailingcountry = 'US',
                                      otherstreet = '456 Test Street',
                                      othercity = 'Encinitas',
                                      otherstate = 'CA',
                                      otherpostalcode = '92024',
                                      othercountry = 'US',
                                      accountId = account.id
                                      );
        insert contact;

        String oppName = apexTestLabel+'Opp';
        Opportunity[] opps = [Select id from Opportunity where isDeleted = false and name = :oppName];
        if (opps != null && opps.size() > 0) delete opps;
        Opportunity newOppNotInserted = new Opportunity(name = oppName,
                                            closedate = System.today(),
                                            stagename = stagename,
                                          //  Publish_As_Quote__c = true,
                                            amount = 450.00
                                            );
        Opportunity newOpp = new Opportunity(name = oppName,
                                            closedate = System.today(),
                                            stagename = stagename,
                                         //   Publish_As_Quote__c = true,
                                            amount = 450.00
                                            );
        insert newOpp;
        Opportunity newOppRecurring = new Opportunity(name = oppName+'-recurring',
                                            closedate = System.today(),
                                            pymt__sitequote_expiration__c = Date.today().addDays(30),
                                            stagename = stagename,
                                            amount = 1000,
                                            pymt__tax__c = 50,
                                            pymt__shipping__c = 150,
                                            pymt__recurring_amount__c = 100,
                                        //   Publish_As_Quote__c = true,
                                            pymt__frequency__c = 1,
                                            pymt__period__c = 'Month',
                                            pymt__occurrences__c = 12,
                                            pymt__SiteQuote_Recurring_Setup__c = 'Recurring Payments = Total Amount', 
                                            accountid = account.id
                                            );
        insert newOppRecurring;
         Opportunity newOppRecurring2 = newOppRecurring.clone(false, true); // don't clone Id, deep clone
         newOppRecurring2.pymt__SiteQuote_Recurring_Setup__c = 'Total Amount + Recurring Payments';
        insert newOppRecurring2;
        
        System.assert(newOpp.Id <> null,'Error creating test opportunity for SiteQuoteApprovalController');
        System.assert((newOppRecurring.Id <> null && newOppRecurring2.Id <> null),'Error creating recurring test opportunities for SiteQuoteApprovalController');
                
 
    System.debug('======>Begin Tests');
        // ------------------ Begin Tests -------------------------
        SiteQuoteApprovalController controller;  
      
        // No Opp -----------------
        // Provoke error for not specifying opportunity record id...
        controller = new SiteQuoteApprovalController();
        
        controller.isURL('1123');
        controller.isURL('');
        controller.isURL('http://www.salesforce.com');
        String ipAddr = controller.getCurrentIPAddress();

        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteQuoteApprovalController();
        
       
    System.debug('======>Paid Off');

        // Opportunity is already "Paid Off"
        newOpp.pymt__Paid_Off__c = true;
        update newOpp;
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteQuoteApprovalController();
        System.assert(controller.disableForm == true, 'Expected form to be disabled after instantiating controller with paid opportunity');
                
    System.debug('=====> default processor connection: '+pymt.PaymentX.getSiteDefaultProcessorConnection(Site.getName()));            
    System.debug('======>Quote Expired');
                
        // Quote is expired
        newOpp.pymt__Paid_Off__c = false;  // undo flag for previous test scenario
        newOpp.pymt__SiteQuote_Expiration__c = Date.today().addDays(-1); // set expiration to yesterday
        update newOpp;
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteQuoteApprovalController();
        System.assert(controller.disableForm == true, 'Expected form to be disabled after instantiating controller with expired quote');
        
        // set expiration to 1 month out
        newOpp.pymt__SiteQuote_Expiration__c = Date.today().addDays(30); 
        update newOpp;
        
    System.debug('======>No Contact');

        // No Contact
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        controller = new SiteQuoteApprovalController();
        System.assert(controller.disableForm == true, 'Expected form to be disabled after instantiating controller without an opportunity contact');

        // Create opportunity contacts (primary)
        OpportunityContactRole oppContact = new OpportunityContactRole(isPrimary = true, opportunityId = newOpp.id, contactId = contact.id, role = 'Decision Maker');
        insert oppContact;
        oppContact = new OpportunityContactRole(isPrimary = true, opportunityId = newOppRecurring.id, contactId = contact.id, role = 'Decision Maker');
        insert oppContact;
        oppContact = new OpportunityContactRole(isPrimary = true, opportunityId = newOppRecurring2.id, contactId = contact.id, role = 'Decision Maker');
        insert oppContact;
                
        // Add account
        newOpp.AccountId = account.Id; 
        update newOpp;
        
        // Pass in all required parameters and process the quote
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOpp.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        ApexPages.currentPage().getParameters().put('cancel_url','http%253A%252F%252Fwww.amazon.com%252Fdummy.css');
        ApexPages.currentPage().getParameters().put('finish_url','http%253A%252F%252Fwww.amazon.com%252Fdummy.css');
        controller = new SiteQuoteApprovalController();
        //controller.getLineItems();
        controller.processQuote();
        controller.finishTransaction();

        // Pass in same parameters and add account id, and contact id as parameters 
        ApexPages.currentPage().getParameters().put('aid',account.Id);
        ApexPages.currentPage().getParameters().put('cid',contact.Id);
        controller = new SiteQuoteApprovalController();

    System.debug('======>Authnet recurring');
        
        // Process a quote with recurring payment terms using AuthNet
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOppRecurring.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        controller = new SiteQuoteApprovalController();
        
        // 
        controller.changeBillingInformation();
        controller.updatedContact.FirstName = 'Sam';
        controller.updatedContact.LastName = 'ApexTest';
        controller.updatedContact.email = 'sam.apextest@test.com';
        controller.updatedContact.mailingstreet = '123 Oak';
        controller.updatedContact.mailingcity = 'Encinitas';
        controller.updatedContact.mailingstate = 'CA';
        controller.updatedContact.mailingpostalcode = '92024';
        controller.updatedContact.mailingcountry = 'US';
        controller.termsAccepted = true;
        controller.processQuote();      

        // Process a quote with recurring payment terms (incorrect installment amount)
        ApexPages.currentPage().getParameters().clear();
        newOppRecurring.pymt__Recurring_Amount__c = 50; // incorrect amount - doesn't add up to total amount of opportunity over 12 payments
        update newOppRecurring;
        ApexPages.currentPage().getParameters().put('id',newOppRecurring.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        controller = new SiteQuoteApprovalController();
         
        
    System.debug('======>PayPal recurring');

        // Process a quote with recurring payment terms using PayPal (change the default payment processor and go again)
        connection2.pymt__Default_Connection__c = true;
        connection1.pymt__Default_Connection__c = false;
        update connection1; 
        update connection2;
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('id',newOppRecurring2.Id);
        ApexPages.currentPage().getParameters().put('debug','1');
        controller = new SiteQuoteApprovalController();
        controller.termsAccepted = true;
        
        controller.processQuote();      

    System.debug('======>PayPal recurring done');
        
    }
 
          
}
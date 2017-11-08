public without sharing virtual class SiteQuoteApprovalController {
// ---------------------------------------------------------------------------
// SiteQuoteApproval controller for PaymentConnect Stand Alone SiteQuote
// Developer: Cristiano Sinadino
// Copyright: Linvio, Inc.
// URL: www.linvio.com
// Last Update: 09/15/2016
// ---------------------------------------------------------------------------


    private AccessControllerWithoutSharing acwos;

    // Parameters
    public String cancelURL {get;set;}
    public String finishURL {get;set;}
    public String contactId {get;set;}
    public String accountId {get;set;}
    public String oppId {get;set;}

    public Boolean debug {get;set;}
    public Boolean enableBillingInfoEdit {get;set;}
    public Boolean requireSignatory {get;set;}  // controls whether or not "Accept Terms" options are displayed
    public String signature {get;set;}
    public String lang {get;set;}

    private OpportunityLineItem[] lineItems;
    public Opportunity opportunity {get;set;}
    public Contact contact {get;set;}
    public Contact updatedContact {get;set;}
    public Account account {get;set;}
    public pymt__PaymentX__c payment {get;set;}
    public pymt__Payment_Profile__c paymentProfile {get;set;}
    public pymt__Processor_Connection__c processor {get;set;}
    public String processorName {get;set;}

    public Boolean isMultiCurrencyOrg {get;set;}
    public String oppCurrencyIsoCode {get;set;}
    public String currencySymbol {get;set;}
    public String currencyShortFormatExpression {get;set;}
    public String currencyFormatExpression {get;set;}

    public Boolean disableForm {get;set;}
    public Boolean hasRecurringAmount {get;set;}
    public Boolean termsAccepted {get;set;}
    public String recurringSetup {get;set;}

    public String shipToName {get;set;}
    public String shipToStreet {get;set;}
    public String shipToCity {get;set;}
    public String shipToState {get;set;}
    public String shipToPostalCode {get;set;}
    public String shipToCountry {get;set;}
    public String shipToCompany {get;set;}
    public String shipToPhone {get;set;}

//    public String billingName {get;set;}
//    public String billingFirstName {get;set;}
//    public String billingLastName {get;set;}
//    public String billingStreet {get;set;}
//    public String billingCity {get;set;}
//    public String billingState {get;set;}
//    public String billingPostalCode {get;set;}
//    public String billingCountry {get;set;}
//    public String emailAddress {get;set;}


    public Decimal discount {get;set;}
    public Decimal subtotal {get;set;}
    public Decimal tax {get;set;}
    public Decimal shipping {get;set;}
    public Decimal total {get;set;}

    private String accessKey = pymt.PaymentX.generateAccessKey();

//    public quot__QI_Settings__c settings {get;set;}

    public class LocalException extends Exception {
        String privateErrorMsg = '';
        String publicErrorMsg = '';
        public String getPrivateMessage() {
            return this.privateErrorMsg;
        }
        public LocalException( String publicMsg, String privateMsg) {
            this.setMessage(publicMsg);
            this.privateErrorMsg = privateMsg;
        }
    }



    public SiteQuoteApprovalController() {
     //   this.settings = quot__QI_Settings__c.getOrgDefaults();
     //   if (this.settings == null) this.settings = new quot__QI_Settings__c();

        this.oppId = ApexPages.currentPage().getParameters().get('id');

        this.lang = pymt.Util.assignIfNotEmpty(ApexPages.currentPage().getParameters().get('lang'),this.lang);
        if (String.isEmpty(this.lang)) {
            ApexPages.currentPage().getParameters().put('lang', UserInfo.getLocale());
        }

        this.termsAccepted = false;
        this.requireSignatory = true;  // set to false to disable options for accepting terms and conditions
        this.signature = '';
        this.hasRecurringAmount = false;
        this.isMultiCurrencyOrg = UserInfo.isMultiCurrencyOrganization();

        this.debug = !String.isEmpty(ApexPages.currentPage().getParameters().get('debug'));
        this.enableBillingInfoEdit = false; // Initially hide billing info editor fields

        this.acwos = new AccessControllerWithoutSharing();


        try {
            if (this.oppId == null || this.oppId == '') {
                throw new LocalException('Sorry, your quote could not be found.', 'Quote record Id is null or empty');
            }


            this.contactId = ApexPages.currentPage().getParameters().get('cid');     // contact id
            this.contactId = pymt.Util.isValidSalesforceId(this.contactId)?this.contactId:null;  // Make sure parm is a valid SF Id
            this.accountId = ApexPages.currentPage().getParameters().get('aid');     // account id
            this.accountId = pymt.Util.isValidSalesforceId(this.accountId)?this.accountId:null;  // Make sure parm is a valid SF Id


            String baseURL = Site.getBaseUrl();
            String pageURL = ApexPages.currentPage().getUrl();   // it will return: < /apex/myVFpage?id=906F00000008w9wIAA >
            String prefix = Site.getPathPrefix();   // e.g. '/mysite or '' if not a site request
            if (!String.isEmpty(prefix)) {
                pageURL = pageURL.replace('/apex', '');
            }

            this.cancelURL = baseURL+pageURL;
            this.finishURL = ApexPages.currentPage().getParameters().get('finish_url');


            String soql = 'Select id, name, amount, pymt__paid_off__c, owner.firstname, owner.lastname, '+
                                'description, account.name, account.billingstreet, account.billingcity, '+
                                'account.billingpostalcode, CloseDate, account.billingstate, account.billingcountry,  '+
                                'account.shippingstreet, account.shippingcity, '+
                                'account.shippingpostalcode, account.shippingstate, account.shippingcountry, '+
                                'HasOpportunityLineItem, pymt__recurring_amount__c, '+
                                'pymt__frequency__c, pymt__occurrences__c, pymt__period__c,  pymt__SiteQuote_Expiration__c, '+
                                'pymt__Invoice_Number__c, pymt__SiteQuote_Recurring_Setup__c, '+
                                'pymt__Tax__c, pymt__Shipping__c, pymt__Total_Amount__c, '+ (isMultiCurrencyOrg?' CurrencyIsoCode, ':'') +
                                '(Select ContactId, Role, IsPrimary From OpportunityContactRoles where IsPrimary = true) '+
                                ' from Opportunity where id = \''+ String.escapeSingleQuotes(this.oppId)+ '\'';
            Opportunity[] opps = this.acwos.dbQuery(soql);
            if (opps.size() >0 ) {
                this.opportunity = opps[0];  // replace current opp with queries opp (to ensure all required fields have been loaded)
                // If contactId is provided as a parameter, use it, otherwise try to use the id of the primary opportunity contact
                if (String.isEmpty(this.contactId) && this.opportunity.opportunitycontactroles <> null && this.opportunity.opportunitycontactroles.size()>0) {
                    this.contactId = this.opportunity.opportunitycontactroles[0].ContactId;
                }
                if (!String.isEmpty(this.contactId)) {
                    soql = 'Select id, accountId, name, firstname, lastname, mailingstreet, mailingcity, mailingpostalcode, mailingstate, mailingcountry, '+
                            'email from Contact where id = \''+ String.escapeSingleQuotes(this.contactId)+'\'';
                    Contact[] contacts = this.acwos.dbQuery(soql);
                    if (contacts == null || contacts.size() ==0)  {
                        throw new LocalException('Quote configuration error - contact not assigned.','Unable to find primary opportunity contact.');
                    }
                    this.contact = contacts[0];
                    this.updatedContact = this.contact.clone(false,true); // clone: clear id, deep clone
                }
                // If account is provided as a parameter, use it, otherwise try to use the account from the opportunity record
                if (String.isEmpty(this.accountId)) {
                    this.accountId = this.opportunity.AccountId;
                }
                if (String.isEmpty(this.accountId)) {
                    this.accountId = this.contact.AccountId;
                }
                if (!String.isEmpty(this.accountId)) {
                    soql = 'Select id, name, shippingstreet, shippingcity, shippingpostalcode, shippingstate, shippingcountry, billingstreet, billingcity, billingpostalcode, billingstate, billingcountry from Account where id = \''+ String.escapeSingleQuotes(this.accountId)+'\'';
                    Account[] accts = this.acwos.dbQuery(soql);
                    if (accts.size()>0) {
                        this.account = accts[0];
                    }
                }
                if (this.account <> null) {
                    this.shipToName = this.contact.firstname + ' '+ this.contact.lastname;
                    this.shipToStreet = !String.isEmpty(this.account.shippingstreet)?this.account.shippingstreet:this.account.billingstreet;
                    this.shipToCity = !String.isEmpty(this.account.shippingstreet)?this.account.shippingcity:this.account.billingcity;
                    this.shipToState = !String.isEmpty(this.account.shippingstreet)?this.account.shippingstate:this.account.billingstate;
                    this.shipToPostalCode = !String.isEmpty(this.account.shippingstreet)?this.account.shippingpostalcode:this.account.billingpostalcode;
                    this.shipToCountry = !String.isEmpty(this.account.shippingstreet)?this.account.shippingcountry:this.account.billingpostalcode;
                    //this.shipToPhone = this.account.phone;
                    this.shipToCompany = this.account.name;

                }
                this.subtotal = this.opportunity.amount;
                this.discount = 0;
                this.tax = this.opportunity.pymt__Tax__c;
                this.shipping = this.opportunity.pymt__Shipping__c;
                this.total = this.opportunity.pymt__Total_Amount__c;

                Map<String,String> recurringSetupOptions = new Map<String,String>{
                                    'Recurring Payments = Total Amount'=>'Installment',
                                    'Total Amount + Recurring Payments'=>'RecurringTackedOn',
                                    'Total Amount Includes First Recurring Payment'=>'FirstRecurringIncluded'};
                this.recurringSetup = recurringSetupOptions.get(this.opportunity.pymt__SiteQuote_Recurring_Setup__c);
                if (this.recurringSetup == 'Installment' ) {
                    if (this.opportunity.pymt__Occurrences__c == null) throw new LocalException('Quote configuration error.  Installment payments must have a fixed number of occurrences.');
                    if (this.opportunity.pymt__Recurring_Amount__c == null
                        || this.opportunity.pymt__Occurrences__c == 0
                        || this.opportunity.pymt__Recurring_Amount__c == 0
                        || Math.abs(this.opportunity.pymt__Recurring_Amount__c * this.opportunity.pymt__Occurrences__c
                                - this.total) > 0.01 * this.opportunity.pymt__Occurrences__c) { // account for possible rounding errors
                            throw new LocalException('Quote configuration error.  Installment payments do not equal the total amount.');
                        }
                }
                if (this.recurringSetup == 'FirstRecurringIncluded' &&
                    this.total < this.opportunity.pymt__recurring_amount__c) {
                      throw new LocalException('Quote configuration error.  Total amount must be greater than or equal to the first recurring payment amount when '+
                                'including first recurring payment in total.');

                }
            } else {
                throw new LocalException('Sorry, your quote could not be found or has not been published yet.', 'Quote record could not be located.');
            }


            if (this.opportunity.pymt__Recurring_Amount__c != null && this.opportunity.pymt__Recurring_Amount__c > 0 && this.opportunity.pymt__Frequency__c != null &&
                this.opportunity.pymt__Frequency__c > 0 && !String.isEmpty(this.opportunity.pymt__Period__c) && this.recurringSetup <> null) {
                    this.hasRecurringAmount = true;
                }
            if (this.opportunity.pymt__paid_off__c) throw new LocalException('This order has already been processed.');

            if (this.opportunity.pymt__sitequote_expiration__c <> null && this.opportunity.pymt__sitequote_expiration__c < Date.today()) {
                throw new LocalException('This quote has expired.');
            }

            if (this.contact == null) {
                throw new LocalException('Quote configuration error - contact not assigned', 'Cannot process quote without a contact record.  Please add a primary opportunity contact to the opportunity record.');
            }
            if (this.account == null) {
                throw new LocalException('Quote configuration error - account not assigned', 'Cannot process quote without an account record.  Please add an account to the opportunity record.');
            }

            // Retrieve default processor connection record

            Set<String> supportRecurring = new Set<String>{'Authorize.Net', 'PayPal', 'WorldPay'};
            Set<String> supported = new Set<String>{'Authorize.Net', 'PayPal', 'WorldPay', 'Google','eWay'};
            String connectionId = pymt.PaymentX.getSiteDefaultProcessorConnection(Site.getName());
            if (connectionId <> null) {
            this.processor = [Select id, pymt__default_connection__c, pymt__processor_id__c, pymt__test_mode__c, pymt__Default_Currency__c,
                                    pymt__PP_Merchant_Id__c from pymt__Processor_Connection__c where isDeleted = false and id = :connectionId
                                ];
            }
            if (this.processor <> null ) {

                this.processorName = this.processor.pymt__processor_id__c;
                this.oppCurrencyIsoCode = this.processor.pymt__Default_Currency__c;
                if (isMultiCurrencyOrg) {
                    this.oppCurrencyIsoCode = (String)this.opportunity.get('CurrencyIsoCode');  // override processor connection default currency value using multicurrency iso code on opp (if present).
                }
                this.currencySymbol = Pymt.Util.currencySymbol(this.oppCurrencyIsoCode);
                this.currencyShortFormatExpression = Pymt.Util.getShortCurrencyFormatExpression(Site.getName(),this.oppCurrencyIsoCode);
                this.currencyFormatExpression = Pymt.Util.getCurrencyFormatExpression(Site.getName(),this.oppCurrencyIsoCode);

                // See if the processor supports the type of payment required on this page
                if (!supported.contains(this.processor.pymt__Processor_Id__c) ||
                    (this.hasRecurringAmount && !supportRecurring.contains(this.processor.pymt__Processor_Id__c))) {
                    throw new LocalException('Configuration Error.', 'The processor connection '+ this.processorName + ' cannot be used for this quote.');
                }
            } else {
                throw new LocalException('Configuration Error.', 'Could not find a processor connection to use for this quote.  Please check your settings.');
            }

            getLineItems();


        } Catch (LocalException lex) {
            System.debug('An error encountered loading the SiteQuote page: '+lex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, (this.debug?lex.getPrivateMessage():lex.getMessage())));
            this.disableForm = true;
        } Catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading page.'+ ex.getMessage()));
            this.disableForm = true;
        }

    }

    public PageReference changeBillingInformation() {
        this.enableBillingInfoEdit = true;
        return null;
    }




    public OpportunityLineItem[] getLineItems() {
        if (this.lineItems == null && this.opportunity <> null && this.opportunity.HasOpportunityLineItem ) {
            this.lineItems = [Select ListPrice, Discount, Subtotal, UnitPrice, TotalPrice, SystemModstamp, SortOrder, ServiceDate,
                Quantity, PricebookEntryId, PricebookEntry.Name,
                pricebookentry.product2.pymt__on_Payment_Completed__c, pricebookentry.productcode,
                pricebookentry.product2.pymt__Taxable__c,
                pricebookentry.product2.pymt__Tangible__c,
                OpportunityId, LastModifiedDate, LastModifiedById, IsDeleted, Id, Description, CreatedDate, CreatedById
            From OpportunityLineItem
            where isDeleted = false and OpportunityId = :this.opportunity.Id ORDER BY SortOrder Asc];
        }
        System.Debug( ' These are the line items: ' + this.lineItems);
        return this.lineItems;

    }

    @TestVisible
    private Boolean isURL(String str) {
        if (String.isEmpty(str)) return false;
        if (str.contains('https:') || str.contains('http:')) return true;
        return false;
    }


    public PageReference cancelTransaction() {
        PageReference cancelPage = null;
        if (!String.isEmpty(this.cancelURL)) {
            cancelPage = new PageReference(this.cancelURL);
        }
        return cancelPage;

    }

    public PageReference finishTransaction() {
        PageReference finishPage = null;
        if (!String.isEmpty(this.finishURL)) {
            finishPage = new PageReference(this.finishURL);
        }
        return finishPage;

    }
    // Creates a Recurring Payment Profile record to be passed to the checkout page.
    public pymt__Payment_Profile__c setupRecurringPaymentProfile() {
        String recordTypeId;

        try {
            if (this.paymentProfile == null) {
                this.paymentProfile = new pymt__Payment_Profile__c();
                this.paymentProfile.pymt__Contact__c = this.contactId;
                this.paymentProfile.pymt__Opportunity__c = this.opportunity.Id;
                this.paymentProfile.pymt__Account__c = this.account.Id;
            }
            String period;
            Double frequency = 1;
            Double recurringAmount = this.opportunity.pymt__Recurring_Amount__c;
            Double occurrences = this.opportunity.pymt__Occurrences__c;
            if (this.processor.pymt__processor_id__c.equalsIgnoreCase('PayPal')){
                // Retrieve PayPal recurring payment record type to store in payment profile
                recordTypeId = [Select id from RecordType where developername like 'PayPal_Recurring_Payment'].id;
                this.paymentProfile.recordTypeId = recordTypeId;
                this.paymentProfile.pymt__Profile_Type__c = 'PayPal Recurring Payment';

                if (this.recurringSetup == 'FirstRecurringIncluded') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.total - recurringAmount;
                } else if (this.recurringSetup == 'RecurringTackedOn') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.total;
                }
                frequency = this.opportunity.pymt__Frequency__c;
                period = this.opportunity.pymt__Period__c;


            } else if (this.processor.pymt__processor_id__c.equalsIgnoreCase('authorize.net')){
                // Retrieve PayPal recurring payment record type to store in payment profile

                recordTypeId = [Select id from RecordType where developername like 'AuthNet_Subscription'].id;
                this.paymentProfile.recordTypeId = recordTypeId;
                this.paymentProfile.pymt__Profile_Type__c = 'AuthNet Subscription';

                if (this.recurringSetup == 'FirstRecurringIncluded' || this.recurringSetup == 'RecurringTackedOn') {
                    this.paymentProfile.pymt__Trial_Amount__c = this.total;
                    this.paymentProfile.pymt__Trial_Occurrences__c = 1;
                }
                if (this.recurringSetup == 'FirstRecurringIncluded') {
                    occurrences = occurrences == null?null:occurrences -1;

                }
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Day')) {period = 'Day'; frequency = this.opportunity.pymt__Frequency__c;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Week')) { period = 'Day'; frequency = this.opportunity.pymt__Frequency__c * 7;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Semi/Month')) { period = 'Day'; frequency = this.opportunity.pymt__Frequency__c * 15;} // approximate of every half month as authnet doesn't offer semi-monthly option
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Month')) {period = 'Month';frequency = this.opportunity.pymt__Frequency__c; }
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Year')) { period = 'Month'; frequency = this.opportunity.pymt__Frequency__c * 12;}

            } else if (this.processor.pymt__processor_id__c.equalsIgnoreCase('worldpay')){
                // Retrieve worldpay recurring payment record type to store in payment profile

                recordTypeId = [Select id from RecordType where developername like 'WorldPay_Recurring_Payment'].id;
                this.paymentProfile.recordTypeId = recordTypeId;
                this.paymentProfile.pymt__Profile_Type__c = 'WorldPay Recurring Payment';

                if (this.recurringSetup == 'FirstRecurringIncluded') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.opportunity.pymt__total_amount__c;
                    occurrences = occurrences == null?null:occurrences -1;

                }  else if (this.recurringSetup == 'RecurringTackedOn') {
                    this.paymentProfile.pymt__Initial_Amount__c = this.opportunity.pymt__total_amount__c;
                }
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Day')) {period = 'Day'; frequency = this.opportunity.pymt__Frequency__c;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Week')) { period = 'Week'; frequency = this.opportunity.pymt__Frequency__c * 1;}
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Semi/Month')) { period = 'Day'; frequency = this.opportunity.pymt__Frequency__c * 15;} // approximate of every half month as authnet doesn't offer semi-monthly option
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Month')) {period = 'Month';frequency = this.opportunity.pymt__Frequency__c; }
                if (this.opportunity.pymt__Period__c.equalsIgnoreCase('Year')) { period = 'Year'; frequency = this.opportunity.pymt__Frequency__c * 1;}

             } else {
                // recurring payments for this processor type not yet supported.
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Current default payment processor not supported for recurring payments ('+this.processorName+').'));
                return null;
            }

            this.paymentProfile.name = this.opportunity.Name;
            this.paymentProfile.pymt__Key__c = this.accessKey;
            this.paymentProfile.pymt__Processor_Connection__c = this.processor.Id;
            this.paymentProfile.pymt__Subscription_Start_Date__c = Date.today();
            this.paymentProfile.pymt__Subscription_Status__c = 'Not Activated';  // temporary status used until subscription has been activated
            this.paymentProfile.pymt__Period__c = period;
            this.paymentProfile.pymt__Frequency__c = frequency;
            this.paymentProfile.pymt__Amount__c = recurringAmount;
            this.paymentProfile.pymt__Currency_ISO_Code__c = this.oppCurrencyIsoCode;
            this.paymentProfile.pymt__Total_Occurrences__c = this.opportunity.pymt__Occurrences__c;

            this.paymentProfile.pymt__Ship_To_Name__c = this.shipToName;
            this.paymentProfile.pymt__Ship_To_Street__c = this.shipToStreet;
            this.paymentProfile.pymt__Ship_To_City__c = this.shipToCity;
            this.paymentProfile.pymt__Ship_To_State__c = this.shipToState;
            this.paymentProfile.pymt__Ship_To_Postal_Code__c = this.shipToPostalCode;
            this.paymentProfile.pymt__Ship_To_Country__c = this.shipToCountry;
            this.paymentProfile.pymt__Ship_To_Phone__c = this.shipToPhone;
            this.paymentProfile.pymt__Ship_To_Company__c = this.shipToCompany;

            if (this.paymentProfile.Id == null) {
                this.acwos.dbInsert(this.paymentProfile);
            } else {
                this.acwos.dbUpdate(this.paymentProfile);
            }
            return this.paymentProfile;

        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error setting up payment profile: '+ex.getMessage()));

            return null;
        }
    }


    public Boolean setupPaymentRecord() {

            // Setup Payment record
            if (this.payment == null) {
                this.payment = new pymt__PaymentX__c();
            }
            try {
                this.payment.name = pymt.Util.assignIfNotEmpty(this.opportunity.name,'Payment');
                this.payment.pymt__amount__c = this.total;
                this.payment.pymt__key__c = this.accessKey;
                this.payment.pymt__tax__c = this.tax;
                this.payment.pymt__shipping__c = this.shipping;
                this.payment.pymt__discount__c = 0;
                this.payment.pymt__contact__c = this.contactId;
                this.payment.pymt__status__c = 'In Process';
                this.payment.pymt__date__c = System.today();
                this.payment.pymt__Currency_ISO_Code__c = this.oppCurrencyIsoCode;
                this.payment.pymt__payment_processor__c = this.processor.pymt__processor_id__c;
                this.payment.pymt__processor_connection__c = this.processor.id;
                this.payment.pymt__opportunity__c = this.opportunity.id;
                this.payment.pymt__account__c = this.account.id;
                this.payment.pymt__Is_Test_Transaction__c = this.processor.pymt__Test_Mode__c;
                this.payment.pymt__log__c = ' ++++ Payment on Opportunity Sales Quote:\n'+ 'Online payment for '+
                                          this.payment.pymt__Amount__c + this.oppCurrencyIsoCode;
                this.payment.pymt__Ship_To_Name__c = this.shipToName;
                this.payment.pymt__Ship_To_Street__c = this.shipToStreet;
                this.payment.pymt__Ship_To_City__c = this.shipToCity;
                this.payment.pymt__Ship_To_State__c = this.shipToState;
                this.payment.pymt__Ship_To_Postal_Code__c = this.shipToPostalCode;
                this.payment.pymt__Ship_To_Country__c = this.shipToCountry;
                this.payment.pymt__Ship_To_Phone__c = this.shipToPhone;
                this.payment.pymt__Ship_To_Company__c = this.shipToCompany;

                if (this.lineItems <> null) {
                    Decimal discountAmount = 0;
                    for (OpportunityLineItem lineItem :this.lineItems) {
                        if (lineItem.TotalPrice <> lineItem.Subtotal) {
                            discountAmount += lineItem.TotalPrice - lineItem.Subtotal;
                        }
                    }
                    this.payment.pymt__Discount__c = discountAmount;
                }

                if (this.payment.id == null) {
                    insert this.payment;
                } else {
                    update this.payment;
                }

                // Insert/update related shopping cart items
                Decimal discountAmount = 0.0;
                pymt__Shopping_Cart_Item__c[] itemsToInsert = new pymt__Shopping_Cart_Item__c[]{};
                if (this.lineItems <> null) {
                    for (OpportunityLineItem lineItem :this.lineItems) {
                        discountAmount += lineItem.UnitPrice - lineItem.TotalPrice;  // tally up the discounts on each line item
                        itemsToInsert.add(new pymt__Shopping_Cart_Item__c(name = pymt.Util.firstN(lineItem.pricebookentry.name,80),
                                                                            pymt__quantity__c = lineItem.quantity,
                                                                            pymt__line_number__c = lineItem.SortOrder,
                                                                            pymt__unit_price__c = lineItem.UnitPrice,
                                                                            pymt__contact__c = this.contact.id,
                                                                            pymt__product__c = lineItem.pricebookentry.product2id,
                                                                            pymt__product_code__c = lineItem.pricebookentry.productcode,
                                                                            pymt__payment__c = this.payment.id,
                                                                            pymt__Taxable__c = lineItem.pricebookentry.product2.pymt__Taxable__c,
                                                                            pymt__Tangible__c = lineItem.pricebookentry.product2.pymt__Tangible__c,
                                                                            pymt__On_Payment_Completed__c = lineItem.pricebookentry.product2.pymt__on_Payment_Completed__c
                                                                        )
                                            );

                    }
                    if (itemsToInsert.size()>0) insert itemsToInsert;

                    if (discountAmount >0) {  // Set discount total from line items on payment record
                        this.payment.pymt__discount__c = discountAmount;
                        update this.payment;
                    }
                }



            } catch (Exception ex) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Error setting up purchase records:' + ex.getMessage()));
                return false;


            }

        return true;

    }

    // Returns IP address of current user.
    public String getCurrentIPAddress(){
        string ipAddress;
        if (String.isEmpty(ipAddress)){
            ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
            if (String.isEmpty(ipAddress)) ipAddress='255.255.255.0';
        }
        return ipAddress;
    }

    // Set up payment or payment profile records and redirect to checkout page
    public PageReference processQuote() {
        PageReference nextPage;
        Blob blobQuotePDF;

        // Call pdf first as salesforce now considers getContentAsPDF() an api call
        PageReference newPage = Page.Preview;
        DateTime timestamp = Datetime.now();
        newPage.getParameters().put('id', this.opportunity.Id);
        newPage.getParameters().put('signature', this.signature);
        newPage.getParameters().put('timestamp', timestamp.format());
        newPage.getParameters().put('ipaddr', this.getCurrentIPAddress());
        if (Test.isRunningTest()) {  // SF doesn't support getContent when in test mode
            blobQuotePDF = Blob.valueOf('');
        } else {
            blobQuotePDF = newPage.getContentAsPDF();
        }

        // If billing contact info changed, upsert contact
        if (this.enableBillingInfoEdit) {
            if (String.isEmpty(this.updatedContact.email)) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide the billing contact email address.'));
                return null;
            }
            Boolean isUpdate = false;
            // Determine whether we are updating an existing contact or creating a new one
            Contact tempContact;
            if (this.updatedContact.email == this.contact.email &&  !String.isEmpty(this.contact.email)) {
                // email matches, update current contact
                isUpdate = true;
                tempContact = new Contact(id = this.contact.id);
                tempContact.accountId = this.contact.accountId;
            } else {
                // new email address, upsert this contact
                Contact[] existing = [Select id, accountId, name, firstname, lastname, email, mailingstreet, mailingcity, mailingstate, mailingpostalcode,
                                mailingcountry from Contact where email = :this.updatedContact.email limit 1];
                if (existing.size()>0) {
                    // contact with same email found, update this contact
                    isUpdate = true;
                    tempContact = new Contact(id = existing[0].id);
                    tempContact.accountId = existing[0].accountId;
                } else {
                    // no match in the database, insert new contact
                    isUpdate = false;
                    tempContact = new Contact();
                    tempContact.accountId = this.opportunity.accountId;
                }
            }

            tempContact.firstname = this.updatedContact.firstname;
            tempContact.lastname = this.updatedContact.lastname;
            tempContact.mailingstreet = this.updatedContact.mailingstreet;
            tempContact.mailingcity = this.updatedContact.mailingcity;
            tempContact.mailingstate = this.updatedContact.mailingstate;
            tempContact.mailingpostalcode = this.updatedContact.mailingpostalcode;
            tempContact.mailingcountry = this.updatedContact.mailingcountry;
            tempContact.email = this.updatedContact.email;
            tempContact.phone = this.updatedContact.phone;


            if (isUpdate) {
                this.acwos.dbUpdate(tempContact);

            } else {
                this.acwos.dbInsert(tempContact);
            }
            this.contact = tempContact.clone(true, true);
            this.updatedContact = tempContact.clone(false, true); // false/true = don't preserve id, and make this a complete copy (non reference)


            // Also update opportunity roles to include the new contact as a primary contact
            Integer roleCount = [Select Count() From OpportunityContactRole where ContactId = :tempContact.id and OpportunityId = :this.opportunity.id];
            if (roleCount == 0) {
                // Contact is not currently an opportunity contact
                this.acwos.dbInsert(new OpportunityContactRole( ContactId = tempContact.id,
                                                                OpportunityId = this.opportunity.id,
                                                                IsPrimary = true,
                                                                Role = 'Economic Buyer'
                                                                ));
            }

        }

        if (this.requireSignatory && this.termsAccepted) {
            String descr = 'SiteQuote Terms & Conditions accepted by '+ this.signature + ' for '+
                                    this.opportunity.Name+' (Document: '+this.opportunity.Id+') from IP:'+ this.getCurrentIPAddress();
            Task newTask = new Task(Subject = 'SiteQuote Terms & Conditions Accepted',
                                    Description= descr,
                                    whatId = this.opportunity.Id,
                                    whoId = this.contact.Id,
                                    status = 'Completed'

                                    );
            insert newTask;


            Attachment att = new Attachment();
            att.Name = 'Accepted Quote.pdf';
            att.Description = descr;
            att.IsPrivate = false;
            att.ParentId = this.opportunity.id;
            att.Body = blobQuotePDF;
            insert att;

            Opportunity opp = new Opportunity( Id = this.opportunity.Id );
            this.acwos.dbUpdate(opp);
        }
        if (this.hasRecurringAmount) {
            // This is a recurring payment opportunity
            this.paymentProfile = setupRecurringPaymentProfile();
            if (this.paymentProfile == null) return null;
            if (processorName.equalsIgnoreCase('paypal')) {
                nextPage = subscribePage();
            }   else if (processorName.equalsIgnoreCase('authorize.net')) {
                nextPage = subscribePage();
            }   else if (processorName.equalsIgnoreCase('worldpay')) {
                nextPage = subscribePage();
            } else {
                return null;  // processor is not supported for recurring payments
            }
            nextPage.getParameters().put('ppid',this.paymentProfile.Id);    // pass payment profile record  id to checkout page
            nextPage.getParameters().put('key',this.accessKey);
        } else {
            // This is a single charge opportunity
            if (!setupPaymentRecord()) return null;
            nextPage = Page.pymt__SiteCheckout;
            nextPage.getParameters().put('pid',this.payment.Id);  // pass payment record id to checkout page
            nextPage.getParameters().put('key',this.accessKey);
        }
        if (String.isEmpty(this.cancelURL)) {
            this.cancelURL = ApexPages.currentPage().getURL();
        }

        if (this.debug) nextPage.getParameters().put('debug', '1');
        if (!String.isEmpty(this.cancelURL)) nextPage.getParameters().put('cancel_url', EncodingUtil.urlEncode(this.cancelURL,'UTF-8'));
        if (!String.isEmpty(this.finishURL)) nextPage.getParameters().put('finish_url', EncodingUtil.urlEncode(this.finishURL,'UTF-8'));
        System.debug('Next page parameters:'+nextPage.getParameters());
        return nextPage;

    }

     public virtual PageReference subscribePage() {
        return Page.pymt__SiteSubscribe;
    }


}
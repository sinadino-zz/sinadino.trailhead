public with sharing class MobileBaseController {


// Copyright 2014, Linvio, Inc.
//
// Library of static remoting classes for use in the PaymentConnect mobile companion app.
// MbOpprtunities Page used methods:
//   - searchOpportunities
//
public String contact { get; set; }
public Boolean isAndroid {get;set;}
public Boolean isIOS {get;set;}
// public pymt__Mobile_Settings__c mobileSettings {get;set;}

public MobileBaseController() {
      checkPlatform();
//      this.mobileSettings = pymt__Mobile_Settings__c.getInstance();
//      if (this.mobileSettings == null) {
//          this.mobileSettings = new pymt__Mobile_Settings__c(pymt__Default_Results_Size__c = 10);
//      }
  }
//  where is the mobile settings class???
// We instantiate the class in two different ways: a) without an argument which implies we won't need basic std objects methods and b) with a standard object controller.
public MobileBaseController(ApexPages.StandardController controller) {
      checkPlatform();
  }

private void checkPlatform() {
         String userAgent = System.currentPageReference().getHeaders().get('User-Agent');
         if (userAgent <> null) {
         if (userAgent.contains('iPhone') || userAgent.contains('iPad')){
             this.isIOS = true;
             this.isAndroid = false;
         }else if (userAgent.contains('Android')){
             this.isIOS = false;
             this.isAndroid = true;
         }
         }
     }
  // getting all the opportunity stages that will be available to be displayed at the VisualForce page.
  // SelectOption: A SelectOption object specifies one of the possible values for a Visualforce selectCheckboxes, selectList, or selectRadio component.
  public SelectOption[] getOppStageNameOptions() {
         OpportunityStage[] oppStages = [Select SortOrder, MasterLabel, IsWon, IsClosed, Id, Description From OpportunityStage order by SortOrder ASC limit 200];
         SelectOption[] result = new SelectOption[]{};
         if (oppStages <> null && oppStages.size()>0) {
             for (OpportunityStage oppStage :oppStages) {
                 SelectOption opt = new SelectOption(oppStage.MasterLabel, oppStage.MasterLabel);
                 result.add(opt);
             }
         }
         return result;
     }
  // PaymentWrapper Class
    public class PaymentWrapper{
         public String name{get;set;}
         public String customerName{get;set;}
         public Id pmtId {get;set;}
         public Date pmtDate {get;set;}
         public String cardType {get;set;}
         public Decimal amount{get;set;}
         public String currencyISOCode{get;set;}
         public String status{get;set;}
         public Decimal latitude{get;set;}
         public Decimal longitude{get;set;}
         public String memo{get;set;}


         public PaymentWrapper(){
         }
     }
  // CartItemWrapper Class
    public class CartItemWrapper{
         public String name{get;set;}
         public Id prodId {get;set;}
         public Decimal unitPrice{get;set;}
         public String currencyISOCode{get;set;}
         public String productCode{get;set;}
         public String imageId{get;set;}
         public String opcTag {get;set;}
         public String description{get;set;}
         public Boolean tangible {get;set;}
         public Boolean taxable{get;set;}
         public Decimal quantity {get;set;}


         public CartItemWrapper(){
         }
     }
// Log results in a meaningful way.
     public class ActionResult {
         public Boolean success {get;set;}
         public String message {get;set;}
         public ActionResult( Boolean success, String message) {
             this.success = success;
             this.message = message;
         }
     }

     public class InsertResult {
         public Boolean success {get;set;}
         public Id recordId {get;set;}
         public String message {get;set;}
         public InsertResult( Boolean success, Id recordId, String message) {
             this.success = success;
             this.recordId = recordId;
             this.message = message;
         }
     }


// remoteAction method to be consumed by visualforce pages with remote javascript logic.
/*
     @remoteAction
       public static ActionResult saveMobileSettings(Id userId, pymt__Mobile_Settings__c settingsObj) {
           try {
         MobileSettingsProxy proxy = new MobileSettingsProxy();
         proxy.updateUserSettings(userId, settingsObj);

           } catch (Exception ex) {
               return new ActionResult(false, ex.getMessage());

           }
           return new ActionResult(true, 'Settings saved');
       }

       public without sharing class MobileSettingsProxy {
         public void updateUserSettings(Id userId, pymt__Mobile_Settings__c settingsObj) {
               pymt__Mobile_Settings__c mobileSettings = pymt__Mobile_Settings__c.getInstance(userId);
               if (mobileSettings == null) {
                 mobileSettings = new pymt__Mobile_Settings__c(SetupOwnerId = userId);
               }
               mobileSettings.pymt__Processor_Connection_Id__c = settingsObj.pymt__Processor_Connection_Id__c;
               mobileSettings.pymt__Pricebook_Id__c = settingsObj.pymt__Pricebook_Id__c;
               mobileSettings.pymt__Default_Results_Size__c = settingsObj.pymt__Default_Results_Size__c;
               mobileSettings.pymt__Default_Country__c = settingsObj.pymt__Default_Country__c;
         upsert mobileSettings;
         }

       }

*/
@remoteAction
  public static ActionResult assignContactToAccount(Id contactId, Id accountId) {
      if (accountId <> null && contactId <> null) {
          try {
              Contact contact = new Contact(id = contactId, accountId = accountId);
              update contact;
              return new ActionResult(true, 'Contact assigned to account.');
          } catch (Exception ex) {
                 return new ActionResult(false, ex.getMessage());
          }
      } else {
         return new ActionResult(false, 'Parameters contain a null value');
       }
     return new ActionResult(false,'Unexpected error.');
  }
  @remoteAction
  public static InsertResult insertPaymentWithCartItems(String status, String name, Decimal amount, String contactId, CartItemWrapper[] cartItems) {

      Contact contact = [Select id, accountId, firstname, lastname, mailingstreet, mailingcity, mailingstate, mailingpostalcode, mailingcountry, email from Contact where id = :contactId];



      pymt__PaymentX__c newPayment = new pymt__PaymentX__c(name = name,
                              pymt__status__c = status,
                              pymt__Amount__c = amount,
                              pymt__Currency_ISO_Code__c = 'USD',
                              pymt__Contact__c = contact.Id,
                              pymt__Billing_First_Name__c = contact.firstname,
                              pymt__Billing_Last_Name__c = contact.lastname,
                              pymt__Billing_Street__c = contact.mailingstreet,
                              pymt__Billing_City__c = contact.mailingcity,
                              pymt__Billing_State__c = contact.mailingstate,
                              pymt__Billing_Postal_Code__c = contact.mailingpostalcode,
                              pymt__Billing_Country__c = contact.mailingcountry,
                              pymt__Account__c = contact.accountId,
                              pymt__Date__c = Date.today());

       insert newPayment;

       if (cartItems <> null && cartItems.size()>0) {
           pymt__Shopping_Cart_Item__c[] newItems = new pymt__Shopping_Cart_Item__c[]{};
           for (CartItemWrapper item :cartItems) {
               pymt__Shopping_Cart_Item__c newItem = new pymt__Shopping_Cart_Item__c(name = item.name,
                               pymt__Unit_Price__c = item.unitPrice,
                               pymt__Product__c = item.prodId,
                               pymt__Product_Code__c = item.productCode,
                               pymt__Quantity__c = item.quantity,
                               pymt__Tangible__c = item.tangible,
                               pymt__Taxable__c = item.taxable,
                               pymt__On_Payment_Completed__c = item.opcTag,
                               pymt__Payment__c = newPayment.Id);
               newItems.add(newItem);
           }
           insert newItems;
       }
       return new InsertResult(true, newPayment.Id, 'Success');
//        return newPayment.Id;

  }

  public class AddressInfo {
      public String firstName {get;set;}
      public String lastName {get;set;}
      public String street {get;set;}
      public String city {get;set;}
      public String state {get;set;}
      public String country {get;set;}
      public String postalCode {get;set;}
      public String email {get;set;}
      public String phone {get;set;}
  }

  public class ProcessPaymentResult {
      Boolean success {get;set;}
      String message {get;set;}

      public ProcessPaymentResult(Boolean success, String message) {
        this.success = success;
        this.message = message;
      }
  }

  private class LocalException extends Exception {}
/*
  @remoteAction
  public static ProcessPaymentResult processPayment(String paymentId,
                  String connectionId,
                  String cardNumber,
                  String expMonth,
                  String expYear,
                  String cardType,
                  String cvv,
                  Decimal amount,
                  AddressInfo billingAddress,
                  String signatureDataURL,
                  Decimal latitude,
                  Decimal longitude) {
      String submitStatus;

      // List of results messages to be returned to page
      String[] pageMessages = new String[]{};

      // Insert code here to call API and process credit card.
      AccessControllerWithoutSharing acwos = new AccessControllerWithoutSharing();
      String soql = 'Select p.pymt__Tokenized_Card_Service_Enabled__c, p.pymt__Test_Mode__c, p.pymt__Processor_Id__c, p.pymt__Assigned_to_Terminal__c, p.pymt__Account_Type__c, p.RecordTypeId, p.Name, p.Id From pymt__Processor_Connection__c p where id = \''+String.escapeSingleQuotes(connectionId)+'\'';
      pymt__Processor_Connection__c[] pcs = acwos.dbQuery(soql);
      pymt__Processor_Connection__c connection;
      if (pcs <> null && pcs.size()>0) {
        connection = pcs[0];
      } else {
        return new ProcessPaymentResult(false, 'Unable to find/access processor connection record.');

      }
      /*
      pymt__PaymentX__c payment = paymentXUtil.getPaymentWithCartItems(paymentId);
      pymt__Shopping_Cart_Item__c[] cartItems = payment.R00N40000001tGNtEAM;

      if (connection.pymt__Processor_Id__c == 'Authorize.Net' && connection.pymt__Account_Type__c == 'AIM') {
              pymt.AuthNetAimAPI.CustomerInfo customerInfo = new pymt.AuthNetAimAPI.CustomerInfo();
              customerInfo.firstname = Util.assignIfNotEmpty(billingAddress.firstName,'').left(50);
              customerInfo.lastname = Util.assignIfNotEmpty(billingAddress.lastName,'').left(50);
              customerInfo.address = Util.assignIfNotEmpty(billingAddress.street,'').left(60);
              customerInfo.city = Util.assignIfNotEmpty(billingAddress.city,'').left(40);
              customerInfo.state = Util.assignIfNotEmpty(billingAddress.state,'').left(40);
              customerInfo.country = Util.assignIfNotEmpty(billingAddress.country,'').left(60);
              customerInfo.postalcode = Util.assignIfNotEmpty(billingAddress.postalcode,'').left(20);
              customerInfo.email = Util.assignIfNotEmpty(billingAddress.email,'').left(255);
              customerInfo.phone = Util.assignIfNotEmpty(billingAddress.phone,'').left(25);
              //customerInfo.customerIP = getPtlIPAddress();


              pymt.AuthNetAimAPI.ShippingInfo shippingInfo = new pymt.AuthNetAimAPI.ShippingInfo();
              if (!String.isEmpty(payment.pymt__Ship_To_First_Name__c) && !String.isEmpty(payment.pymt__Ship_To_Last_Name__c)) {

                shippingInfo.firstname = payment.pymt__Ship_To_First_Name__c.left(50);
               shippingInfo.lastname = payment.pymt__Ship_To_Last_Name__c.left(50);
                shippingInfo.company = Util.assignIfNotEmpty(payment.pymt__Ship_To_Company__c,'').left(50);
                shippingInfo.address = Util.assignIfNotEmpty(payment.pymt__ship_to_street__c,'').left(60);
                shippingInfo.city = Util.assignIfNotEmpty(payment.pymt__ship_to_city__c,'').left(40);
                shippingInfo.state = Util.assignIfNotEmpty(payment.pymt__ship_to_state__c,'').left(40);
                shippingInfo.postalcode = Util.assignIfNotEmpty(payment.pymt__ship_to_postal_code__c,'').left(20);
                shippingInfo.country = Util.assignIfNotEmpty(payment.pymt__ship_to_country__c,'').left(60);
                shippingInfo.phone = Util.assignIfNotEmpty(payment.pymt__Ship_To_Phone__c,'').left(25);



              }

      Boolean emailCustomer = null; // leave null, so customer can configure email notifications in their authnet merchant account.
              String authCode;
              Boolean taxExempt = false;
              Boolean isAuthorizationOnly = false;
              String authenticationIndicator;
              String cardholderAuthValue;
              String poNumber;
              String invoiceNumber = payment.pymt__Invoice_Number__c;
              String description = (String.isEmpty(payment.name))? 'Mobile Payment':payment.name;

      pymt.PaymentX.TransactionResultExt result = pymt.AuthNetConnector.processCreditCard(
                          payment,
                          cartItems,
                          connection.Id,
                          description,
                          payment.pymt__amount__c,
                          payment.pymt__shipping__c,
                          payment.pymt__tax__c,
                          payment.pymt__currency_iso_code__c,
                          invoiceNumber,
                          poNumber,
                          emailCustomer,
                          customerInfo,
                          shippingInfo,
                          cardNumber,
                          cardType,
                          expMonth+expYear,
                          cvv,
                          authCode,
                          taxExempt,
                          authenticationIndicator,
                          cardholderAuthValue,
                          isAuthorizationOnly
                      );

            if (result == null) throw new LocalException('Null return value from charge card request.');
            String transResult = result.transResult;
            if (transResult == null) transResult = '';
            if (result.pxSuccess) {
                if (transResult.equalsIgnoreCase('Success') || transResult.equalsIgnoreCase('SuccessWithWarning')) {

                pymt__PaymentX__c updatedPayment = new pymt__PaymentX__c(id = paymentId,
                        //        pymt__status__c = 'Completed',
                        //        pymt__Billing_First_Name__c = billingAddress.firstName,
                        //        pymt__Billing_Last_Name__c = billingAddress.lastName,
                        //        pymt__Billing_Street__c = billingAddress.street,
                        //        pymt__Billing_City__c = billingAddress.city,
                        //        pymt__Billing_State__c = billingAddress.state,
                        //        pymt__Billing_Postal_Code__c = billingAddress.postalCode,
                        //        pymt__Billing_Country__c = billingAddress.country,
                        //        pymt__Last_4_Digits__c = String.isEmpty(cardNumber)?'':cardNumber.right(4),
                        //        pymt__Date__c = Date.today(),
                                pymt__Latitude__c = latitude ==  0?null:latitude,
                                pymt__Longitude__c = longitude == 0?null:longitude
                        );
                 update updatedPayment;



                    if (result.transResult.equalsIgnoreCase('Success')) {
                        pageMessages.add( 'Payment accepted.');
                    } else {
                        pageMessages.add( 'Transaction completed with warning(s): '+result.transMessage);
                    }
                    submitStatus = 'completed';

                } else {
                      pageMessages.add('Transaction failed: '+result.transMessage);
                    submitStatus = 'failed';
                }


            } else {
              pageMessages.add('Request failed: '+result.pxMessage);
                submitStatus = 'failed';
            }

      } else {
        // Return not supported error.
        return new ProcessPaymentResult(false, 'Processor or processor account type is not supported for this operation.');
      }

  if (submitStatus == 'completed') {

       // create signature attachment
       String image64 = signatureDataURL.replaceAll('data:image/png;base64,','');
       Attachment att = new Attachment(parentId = paymentId,
                               Name = 'Signature',
                               Body = EncodingUtil.base64Decode(image64),
                               ContentType = 'image/png');
       insert att;

       return new ProcessPaymentResult(true, 'Success');

  } else {

      return new ProcessPaymentResult(false, String.join(pageMessages,', '));
  }

  }
*/

  @remoteAction
  public static Contact getContact(String contactId) {
      Contact result;
    //  if (!String.isEmpty(contactId) && Util.isValidSalesforceID(contactId)){
    if (!String.isEmpty(contactId)){
          String soql = 'Select id, title, AccountId, Account.Name, name, '+
          'email, mailingstreet, mailingcity, mailingstate, mailingpostalcode, '+
          'mailingcountry, otherstreet, othercity, otherstate, otherpostalcode, '+
          'othercountry, phone '+
          ' from Contact where isDeleted = false ';
          result = Database.query(soql);
      }
      return result;
  }


  @remoteAction
  public static Contact[] searchContacts(String searchString, String orderByField, String direction, decimal itemLimit) {
      if (itemLimit == null || itemLimit < 1) {
          itemLimit = 20;
       }
      Set<String> validOrderByFields = new Set<String>{'Name','FirstName', 'CreatedDate', 'LastViewedDate', 'LastName', 'Email'};
      if (orderByField == null || !validOrderByFields.contains(orderByField)) {
          orderByField = 'Name';
       }


      Set<String> validDirections = new Set<String>{'Asc','Desc'};
      if (String.isEmpty(direction) || !validDirections.contains(direction)) {
          direction = 'Asc';
       }
      if (String.isEmpty(searchString)) searchString = '';

      String soql = 'Select id, title, AccountId, Account.Name, name, email, mailingstreet, mailingcity, mailingstate, mailingpostalcode, mailingcountry '+
                      ' from Contact where isDeleted = false ';
      if (!String.isEmpty(searchString)) {
          soql += ' and (name like \'%'+String.escapeSingleQuotes(searchString)+'%\' or ( email <> null and email like \''+  String.escapeSingleQuotes(searchString)+'\')) ';
      }
      soql += ' order by '+ orderByField + ' ' + direction + ' limit  '+ itemLimit;
      Contact[] results = Database.query(soql);
      return results;
  }

  @remoteAction
  public static InsertResult insertContact(Contact contact, Boolean addIndividualAcct) {
  System.debug('-----> contact: '+contact);
      System.Savepoint sp = Database.setSavepoint();  // if any step fails, rollback and return null

      try {
          if (addIndividualAcct) {
              Account newAccount = new Account(name = contact.firstname + ' ' + contact.lastname,
                                      pymt__Convert_To_Person_Account__c = true);
              insert newAccount;
              contact.AccountId = newAccount.Id;
           }
          insert contact;
          return new InsertResult(true, contact.id, 'Success');

      } catch (Exception ex) {
          Database.rollback(sp);
          return new InsertResult(false, null, ex.getMessage());
      }
      return new InsertResult(false, null, 'Unexpected Error');
  }

  @remoteAction
  public static InsertResult insertAccount(Account account, Id relatedContactId) {
  System.debug('-----> account: '+account);
      System.Savepoint sp = Database.setSavepoint();
      try {
          insert account;
          if (relatedContactId <> null) {
              // attach contact to the new account
              Contact contact = new Contact(id = relatedContactId, AccountId = account.Id);
              update contact;
           }
          return new InsertResult(true, account.Id, 'Success');
      } catch (Exception ex) {
          Database.rollback(sp);
          return new InsertResult(false, null, ex.getMessage());
      }
      return new InsertResult(false, null, 'Unexpected Error');
  }


  @remoteAction
  public static Opportunity[] searchOpportunities(String searchString, String orderByField, String direction, decimal itemLimit) {
      if (itemLimit == null || itemLimit < 1) {
          itemLimit = 20;
       }
      Set<String> validOrderByFields = new Set<String>{'Name','LastModifiedDate', 'StageName', 'Probability', 'CreatedDate', 'LastViewedDate'};
      if (orderByField == null || !validOrderByFields.contains(orderByField)) {
          orderByField = 'Name';
       }


      Set<String> validDirections = new Set<String>{'Asc','Desc'};
      if (String.isEmpty(direction) || !validDirections.contains(direction)) {
          direction = 'Asc';
       }
      if (String.isEmpty(searchString)) searchString = '';
      String soql = 'Select id, name, Probability, accountId, account.name, amount, pymt__tax__c, pymt__shipping__c, '+
                  'pymt__Total_Amount__c, pymt__Subscription_Start_Date__c, pymt__SiteQuote_Recurring_Setup__c, '+
                  'pymt__SiteQuote_Expiration__c, pymt__Recurring_Amount__c, pymt__Period__c, pymt__Payments_Made__c, pymt__Paid_Off__c, '+
                  'pymt__PO_Number__c, pymt__Occurrences__c, pymt__Number_of_Payments_Made__c, pymt__Invoice_Number__c, '+
                  'pymt__Currency_ISO_Code__c, pymt__Balance__c, Type, StageName, Pricebook2Id, IsWon, IsClosed, Description '+
                      ' from Opportunity where isDeleted = false ';
      if(!String.isEmpty(searchString)) {
          soql += ' and name like \'%'+String.escapeSingleQuotes(searchString)+'%\' ';
      }

      System.debug('=====> opp soql '+soql);


      soql +=   ' order by '+ String.escapeSingleQuotes(orderByField) + ' ' + String.escapeSingleQuotes(direction) + ' limit  '+itemLimit;
      Opportunity[] results = Database.query(soql);
      return results;
  }

  @remoteAction
  public static Account[] searchAccounts(String searchString, String orderByField, String direction, decimal itemLimit) {
      if (itemLimit == null || itemLimit < 1) {
          itemLimit = 20;
       }
      Set<String> validOrderByFields = new Set<String>{'Name','LastModifiedDate', 'CreatedDate', 'LastViewedDate'};
      if (orderByField == null || !validOrderByFields.contains(orderByField)) {
          orderByField = 'Name';
       }


      Set<String> validDirections = new Set<String>{'Asc','Desc'};
      if (String.isEmpty(direction) || !validDirections.contains(direction)) {
          direction = 'Asc';
       }
      if (String.isEmpty(searchString)) searchString = '';
      String soql = 'Select id, name, billingstreet, billingcity, billingstate, billingpostalcode, billingcountry '+
                      ' from Account where isDeleted = false ';
      if(!String.isEmpty(searchString)) {
          soql += ' and name like \'%'+String.escapeSingleQuotes(searchString)+'%\' ';
      }
      soql +=   ' order by '+ String.escapeSingleQuotes(orderByField) + ' ' + String.escapeSingleQuotes(direction) + ' limit  '+itemLimit;
      Account[] results = Database.query(soql);
      return results;
  }
/*
  @remoteAction
  public static PaymentWrapper[] searchPayments(String contactId, String searchString, String orderByField, String direction, decimal itemLimit) {
      if (itemLimit == null || itemLimit < 1) {
          itemLimit = 20;
       }
      Set<String> validOrderByFields = new Set<String>{'Name','pymt__Amount__c', 'CreatedDate', 'LastViewedDate', 'pymt__Scheduled_Payment_Date__c', 'pymt__Date__c', 'pymt__Status__c'};
      if (orderByField == null || !validOrderByFields.contains(orderByField)) {
          orderByField = 'pymt__Date__c';
       }


      Set<String> validDirections = new Set<String>{'Asc','Desc'};
      if (String.isEmpty(direction) || !validDirections.contains(direction)) {
          direction = 'Desc';
       }

      String soql = 'Select id, name, pymt__Amount__c, pymt__Currency_ISO_Code__c, '+
              'pymt__Billing_First_Name__c, pymt__Billing_Last_Name__c, pymt__Contact__r.name, '+
              'pymt__Memo__c, pymt__Date__c, pymt__Status__c, pymt__Card_Type__c, '+
              'pymt__Payment_Processor__c '+
              ' from pymt__PaymentX__c '+
                  ' where pymt__Date__c <> null '+
                  //' and pymt__Date__c = Last_N_Days:60 '+
                  'and pymt__Amount__c <> null and pymt__Status__c <> \'In Process\' '+
                  (String.isEmpty(searchString)?'':' and name like \'%'+searchString+'%\' ')+
                  ' order by '+  orderByField + ' '+ direction + ' limit '+itemLimit;
        pymt__PaymentX__c[] payments = Database.query(soql); //[Select id, name from pymt__PaymentX__c order by name limit 20];
        PaymentWrapper[] results = new PaymentWrapper[]{};
        if (payments <> null && payments.size()>0) {
            for (pymt__PaymentX__c pmt :payments) {
                PaymentWrapper pw = new PaymentWrapper();
                pw.pmtId = pmt.id;
                pw.amount = pmt.pymt__Amount__c;
                pw.cardType = pmt.pymt__Card_Type__c;
                if (String.isEmpty(pw.cardType) && pmt.pymt__Payment_Processor__c == 'PayPal') {
                  pw.cardType = 'PayPal';
                }
                pw.currencyISOCode = String.isEmpty(pmt.pymt__Currency_ISO_Code__c)?'':pmt.pymt__Currency_ISO_Code__c;
                pw.name = pmt.name;
                if (String.isEmpty(pmt.pymt__Billing_Last_Name__c)) {
                    pw.customerName = pmt.pymt__Contact__r.name;
                } else {
                    pw.customerName = pmt.pymt__Billing_First_Name__c + ' ' + pmt.pymt__Billing_Last_Name__c;
                }
                pw.pmtDate = pmt.pymt__Date__c;
                pw.status = pmt.pymt__Status__c;
                pw.memo = pmt.pymt__Memo__c == null?'':pmt.pymt__Memo__c;
                results.add(pw);
            }
        }
      return results;
  }
*/
 public class ProductWrapper{
      public String name{get;set;}
      public Id prodId {get;set;}
      public Decimal unitPrice{get;set;}
      public String currencyISOCode{get;set;}
      public String productCode{get;set;}
      public String imageId{get;set;}
      public String opcTag {get;set;}
      public Boolean tangible {get;set;}
      public Boolean taxable{get;set;}
      public String description{get;set;}
      public Decimal inventory {get;set;}


      ProductWrapper(){
      }
  }


  @remoteAction
  public static ProductWrapper[] searchProducts(Id pricebookId, String searchString, String prodFamily,  String orderByField, String direction, Decimal itemLimit) {
      if (itemLimit == null || itemLimit < 1) {
          itemLimit = 20;
       }
       if (String.isEmpty(prodFamily) || prodFamily == '-- All --') {
         prodFamily = '';
       }
      Set<String> validOrderByFields = new Set<String>{'Name','ProductCode', 'Family', 'CreatedDate', 'LastModifiedDate'};
      if (orderByField == null || !validOrderByFields.contains(orderByField)) {
          orderByField = 'Name';
       }


      Set<String> validDirections = new Set<String>{'Asc','Desc'};
      if (String.isEmpty(direction) || !validDirections.contains(direction)) {
          direction = 'Asc';
       }
       if (pricebookId == null) {
           Pricebook2[] pbs = [Select id from Pricebook2 where isStandard = true and isActive = true];
           if (pbs <> null && pbs.size()>0 && pricebookId == null) {
               pricebookId = pbs[0].id;  // use standard pricebook if not set in mobile app
           }
       }

      String soql = 'Select p.UnitPrice, p.ProductCode, p.Product2.pymt__Inventory__c, p.Product2.pymt__Weight_Class__c, '+
                  'p.Product2.pymt__Weight__c, p.Product2.pymt__Taxable__c, p.Product2.pymt__Tangible__c, p.Product2.pymt__Category__c, '+
                  'p.Product2.pymt__On_Payment_Completed__c, p.Product2.IsDeleted, p.Product2.Family, p.Product2.SystemModstamp, '+
                  'p.Product2.LastModifiedById, p.Product2.LastModifiedDate, p.Product2.CreatedById, p.Product2.CreatedDate, '+
                  'p.Product2.IsActive, p.Product2.Description, p.Product2.ProductCode, p.Product2.Name, p.Product2.Id, p.Product2Id, '+
                  'p.Pricebook2Id, p.Name, p.IsActive, p.Id From PricebookEntry p WHERE isActive = true and Pricebook2Id = \''+ pricebookId + '\''+
                  (String.isEmpty(searchString)?'':' and (name like \'%'+searchString+'%\' OR Product2.Description like \'%'+
                  searchString+'%\'  OR ProductCode = \''+searchString+'\')')+
                  (String.isEmpty(prodFamily)?'':' and Product2.Family = \''+prodFamily+'\' ')+
                  ' order by '+  orderByField + ' '+ direction + ' limit '+itemLimit;
        PricebookEntry[] pbes = Database.query(soql);

        ProductWrapper[] results = new ProductWrapper[]{};

        Set<Id> recIds = new Set<Id>{};
        if (pbes <> null && pbes.size()>0) {
            for (PricebookEntry pbe :pbes) {
                ProductWrapper pw = new ProductWrapper();
                pw.prodId = pbe.Product2.id;
                pw.name = pbe.name;
                pw.description = pbe.Product2.Description;
                pw.unitPrice = pbe.UnitPrice;
                pw.opcTag = pbe.Product2.pymt__On_Payment_Completed__c;
                pw.tangible = pbe.Product2.pymt__Tangible__c;
                pw.taxable = pbe.Product2.pymt__Taxable__c;
                pw.productCode = pbe.Product2.ProductCode;
                pw.inventory = pbe.Product2.pymt__Inventory__c;
                results.add(pw);
                recIds.add(pbe.Product2.id);
            }
            Set<String> ctypes = new Set<String>{'image/png', 'image/jpeg', 'image/gif', 'image/jpg'};
            Attachment[] atts = [Select id, ContentType, ParentId from Attachment where ParentId in :recIds and ContentType in :ctypes];
            if (atts <> null && atts.size()>0) {
                for (ProductWrapper pw :results) {
                    for (Attachment att :atts) {
                       if (att.parentId == pw.prodId) {
                          pw.imageId = att.Id;
                          break;

                       }
                    }
                }
            }
        }


      return results;
  }

  @remoteAction
  public static ProductWrapper productCodeLookup(String productCode, String priceBookId) {

        ProductWrapper results;
        if (pricebookId == null) {
            Pricebook2[] pbs = [Select id, name, isStandard from Pricebook2 where isStandard = true];
            if (pbs <> null && pbs.size()>0) {
                pricebookId = pbs[0].id;
            } else {
                return null;
            }
        }
      Set<String> ctypes = new Set<String>{'image/png', 'image/jpeg', 'image/gif', 'image/jpg'};

      Product2[] products = [Select id, name, Description, (Select id, name from Attachments where ContentType in :ctypes limit 1), (Select Id, Name, Pricebook2Id, Product2Id, UnitPrice, IsActive From PricebookEntries where IsActive = true and Pricebook2Id = :pricebookId) from Product2 where ProductCode = :productCode];
      if (products <> null &&  products.size()>0) {
          results = new ProductWrapper();
          results.prodId = products[0].id;
          results.name = products[0].name;
          results.Description = products[0].Description;
          if (products[0].PricebookEntries <> null && products[0].PricebookEntries.size()>0) {
             PricebookEntry pbe = products[0].PricebookEntries[0];
              results.unitPrice = pbe.UnitPrice;
              }
          if (products[0].Attachments <> null && products[0].Attachments.size()>0) {
              results.imageId = products[0].Attachments[0].Id;
              }
          return results;
      }
      return null;
  }

  public Component.Apex.IncludeScript getCordovaJS() {
      String userAgent = System.currentPageReference().getHeaders().get('User-Agent');
      if (userAgent == null) userAgent = '';
      Component.Apex.IncludeScript jsScript;
      if (userAgent.contains('iPhone') || userAgent.contains('iPad')){
          jsScript = new Component.Apex.IncludeScript();
          jsScript.expressions.value = '{!URLFOR($Resource.PaymentConnectMobile,"Cordova/ios/cordova.js")}';
      }else if (userAgent.contains('Android')){
          jsScript = new Component.Apex.IncludeScript();
          jsScript.expressions.value = '{!URLFOR($Resource.PaymentConnectMobile,"Cordova/android/cordova.js")}';
      } else { // test section .... remove this else after testing
          jsScript = null;
      }
      return jsScript;
  }



}
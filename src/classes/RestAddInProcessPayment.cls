@RestResource(urlMapping='/AddInProcessPayment/v1/*')
global with sharing class RestAddInProcessPayment {

    global class AddInProcessPaymentRequest {
        public pymt__PaymentX__c payment;
        public Account account;
        public Contact contact;
        public pymt__Shopping_Cart_Item__c[] cartItems;
        public Boolean overwriteExistingContact;
    }

    global class AddInProcessPaymentResponse {
        public String statusCode;
        public String statusMessage;
        public pymt__PaymentX__c payment;
        public Account account;
        public Contact contact;
        public pymt__Shopping_Cart_Item__c[] cartItems;
    }
  

    private class LocalException extends Exception {}

    public static Integer matchScore(Contact c1, Contact c2) {
        Integer result = 0;
        if (c1.email == c2.email) {
            result +=1;
        }
        if (!String.isEmpty(c1.lastname) && c1.lastname == c2.lastname) {
            result +=1;
        }
        if (!String.isEmpty(c1.firstname) && c1.firstname == c2.firstname) {
            result +=1;
        }
        if (!String.isEmpty(c1.phone) && c1.phone == c2.phone) {
            result +=1;
        }
        if (!String.isEmpty(c1.mailingcity) && c1.mailingcity == c2.mailingcity) {
            result +=1;
        }
        if (!String.isEmpty(c1.mailingstate) && c1.mailingstate == c2.mailingstate) {
            result +=1;
        }
        return result;
    }

    @HttpGet
    global static Account doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        System.debug('Account Id:'+accountId);
        Account result = [SELECT Id, Name, Phone, Website FROM Account WHERE Id = :accountId];
        return result;
    }

    @HttpPost
    global static AddInProcessPaymentResponse doPost(AddInProcessPaymentRequest reqst) {
        // Inserts a new "In Process" payment record in Saleforce.
        // Checks amount, currency code, contact and other required fields
        // Retotals payment amount if shopping cart items are included
        // Inserts shopping cart items if included.
        AddInProcessPaymentResponse resp = new AddInProcessPaymentResponse();

        try {
            reqst.payment.pymt__Status__c = 'In Process';
            reqst.payment.pymt__Transaction_Type__c = 'Payment';
            reqst.payment.pymt__Scheduled_Payment_Date__c = null;
            reqst.payment.pymt__Batch_Processing_Action__c = '';
            Boolean overwriteOK = reqst.overwriteExistingContact == true;

            if (String.isBlank(reqst.payment.Name)) {
                reqst.payment.Name = 'Payment';                     // default record name
            }
            if (String.isBlank(reqst.payment.pymt__Currency_ISO_Code__c)) {
                reqst.payment.pymt__Currency_ISO_Code__c = 'USD';   // default currency code
            }
            if (reqst.contact == null && reqst.payment.pymt__Contact__c == null) {
                throw new LocalException('A contact record or contact id is required.');
            }
            if (reqst.payment.pymt__Date__c == null) {
                reqst.payment.pymt__Date__c = Date.today();
            }

            Boolean newContactInserted = false;

            if (reqst.payment.pymt__Contact__c == null) {
                if (reqst.contact <> null) {
                    // upsert new contact

                    if (reqst.contact.id == null ) {  // This might be a new contact
                        if (!String.isEmpty(reqst.contact.email)) {
                            // look for existing contact before adding a new one
                            Contact[] contacts = [Select id, accountId, email, firstname, lastname,
                                    mailingcity, mailingstate, othercity, otherstate, phone
                                    from Contact where email = :reqst.contact.email
                                    order by createdDate desc limit 10 ];
                            Contact matchingContact;
                            if (contacts <> null && contacts.size()>0) {
                                matchingContact = contacts[0];
                                if (contacts.size()>1) {
                                // If more than one matching contact disambiguate using
                                // name and address fields
                                    for (Contact ct :contacts) {
                                        if (matchScore(ct,reqst.contact) > matchScore(matchingContact, reqst.contact)) {
                                            matchingContact = ct;
                                        }
                                    }
                                }
                            }
                            if (matchingContact <> null) {
                                // found an existing contact.  Either merge the new contact with existing
                                // or just use the existing.
                                if (overwriteOK) {
                                    // merge new contact with existing
                                    try {
                                        insert reqst.contact;
                                        Database.MergeResult mrgResults =
                                            Database.merge(reqst.contact, matchingContact, true);
                                        if (mrgResults.isSuccess()) {
                                            reqst.contact = reqst.contact; // stays as master record
                                        } else {
                                            reqst.contact = matchingContact;
                                        }
                                    } Catch (exception x1) {
                                        System.debug('Error: unable to merge new contact ('+reqst.contact.id+') with existing contact ('+matchingContact.Id+'): '+x1.getMessage());
                                    }
                                } else {
                                    reqst.contact = matchingContact;

                                }

                                reqst.payment.pymt__Account__c = matchingContact.accountid;

                            } else {
                                // no matches found, insert the new contact
                                insert reqst.contact;
                                newContactInserted = true;
                            }
                        } else {
                            // not enough information to search for an existing contact,
                            // go ahead and insert the new one without searching
                            insert reqst.contact;
                            newContactInserted = true;
                        }
                    } else { // existing SF contact, see if we need to update it
                        if (overwriteOK) {
                            update reqst.contact;
                        }
                    }

                }
                reqst.payment.pymt__Contact__c = reqst.contact.Id;
                if (reqst.payment.pymt__Account__c == null) {
                    reqst.payment.pymt__Account__c = reqst.contact.accountId;
                }
            }

            if (reqst.account <> null && reqst.payment.pymt__Account__c == null) {
                // if account record provided and no account found on payment or
                // contact record, upsert account record
                if (reqst.account.id <> null) {
                    update reqst.account;
                } else {
                    insert reqst.account;
                }

                reqst.payment.pymt__Account__c = reqst.account.id;

                if (newContactInserted) {  // Attach the new contact to this account
                    reqst.contact.accountId = reqst.account.id;
                    update reqst.contact;
                }
            }

            if (reqst.cartItems <> null && reqst.cartItems.size()>0) {
            // If cart items present, total payment from cart item amounts and tax,
            // shipping, discount fields
                Decimal totalAmt = 0;
                if (reqst.payment.pymt__Discount__c <> null) {
                    totalAmt -= reqst.payment.pymt__Discount__c;
                }
                if (reqst.payment.pymt__Tax__c <> null) {
                    totalAmt += reqst.payment.pymt__Tax__c;
                }
                if (reqst.payment.pymt__Shipping__c <> null) {
                    totalAmt += reqst.payment.pymt__Shipping__c;
                }

                for (pymt__Shopping_Cart_Item__c item :reqst.cartItems) {
                    totalAmt += item.pymt__Quantity__c * item.pymt__Unit_Price__c;
                }
                insert reqst.cartItems;
                reqst.payment.pymt__Amount__c = totalAmt;
            }
            if (reqst.payment.pymt__Amount__c == null || reqst.payment.pymt__Amount__c < 0) {
                throw new LocalException('Invalid amount.');
            }


            insert reqst.payment;

            // Attach cart items to new payment record.
            if (reqst.cartItems <> null && reqst.cartItems.size()>0) {
                for (pymt__Shopping_Cart_Item__c item :reqst.cartItems) {
                    item.pymt__Payment__c = reqst.payment.Id;
                }
                update reqst.cartItems;
            }

        } catch (Exception ex) {
            System.debug('=====> '+ex);
            resp.statusCode = 'Error';
            resp.statusMessage = 'Exception : ' + ex.getMessage();
        }
        resp.statusCode = 'Success';
        resp.statusMessage = 'Record(s) added.';
        resp.payment = reqst.payment;
        resp.cartItems = reqst.cartItems;
        resp.account = reqst.account;
        resp.contact = reqst.contact;

        return resp;
    }


}
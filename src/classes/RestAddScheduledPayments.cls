@RestResource(urlMapping='/AddScheduledPayments/v1/*')
global with sharing class RestAddScheduledPayments {


    global class AddScheduledPaymentsResponse {
        public String statusCode;
        public String statusMessage;
    }

    global class AddScheduledPaymentsRequest {
        public Decimal totalAmount;
        public String currencyISOCode;
        public String installmentName;
        public Integer numberOfInstallments;
        public Date startDate;
        public Integer frequency;  
        public String period;    // Month, Day
        public Id contactId;
        public Id opportunityId;
        public Id accountId;
        public Id processorConnectionId;
    }

    private class LocalException extends Exception {}

    @HttpPost
    global static AddScheduledPaymentsResponse doPost(
                Decimal totalAmount,
                String currencyISOCode,
                String installmentName,
                Integer numberOfInstallments,
                Date startDate,
                Integer frequency,
                String period,    // Month, Day
                Id contactId,
                Id opportunityId,
                Id accountId,
                Id processorConnectionId) {
        // Inserts a new "In Process" payment record in Saleforce.
        // Checks amount, currency code, contact and other required fields
        // Retotals payment amount if shopping cart items are included
        // Inserts shopping cart items if included.
        AddScheduledPaymentsResponse resp = new AddScheduledPaymentsResponse();
        try {

            if (startDate == null) throw new LocalException('Start date must be provided.');

             system.debug('=====> processor connection '+processorConnectionId);

            pymt__PaymentX__c[] paymentsToInsert = new pymt__PaymentX__c[]{};
            Decimal installmentAmt = (totalAmount / numberOfInstallments).setScale(2, System.RoundingMode.HALF_EVEN);
            Decimal runningTotal = 0;
            for (Integer i=0; i< numberOfInstallments; i++) {
                pymt__PaymentX__c newPmt = new pymt__PaymentX__c(name = String.isEmpty(installmentName)?'Installment Payment':installmentName,
                                                        pymt__Status__c = 'Scheduled',
                                                        pymt__Scheduled_Payment_Date__c = period == 'Month'?startDate.addMonths(i*frequency):startDate.addDays(i*frequency),
                                                        pymt__Transaction_type__c = 'Payment',
                                                        pymt__Contact__c = contactId,
                                                        pymt__Opportunity__c = opportunityId,
                                                        pymt__Account__c = accountId,
                                                        pymt__Amount__c = installmentAmt,
                                                        pymt__Currency_ISO_Code__c = currencyISOCode,
                                                        pymt__Processor_Connection__c = processorConnectionId
                                                        );
                runningTotal += installmentAmt;
                if (totalAmount - runningTotal < installmentAmt) {
                    newPmt.pymt__Amount__c += totalAmount - runningTotal; // add remainder onto last payment in series.
                }
                paymentsToInsert.add(newPmt);

            }
            if ( paymentsToInsert <> null && paymentsToInsert.size()>0) {
                insert paymentsToInsert;
            }
            resp.statusCode = 'Success';
            resp.statusMessage = 'Scheduled payments added.';
            } catch (Exception ex) {
                resp.statusCode = 'Error';
                resp.statusMessage = 'Exception : '+ ex.getMessage();
            }

        return resp;
    }

}
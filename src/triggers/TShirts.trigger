trigger TShirts on Account (after insert) {
    for (Account acc : Trigger.new) {
        Case shirtCase      = new Case();
        shirtCase.Subject   = 'Send them a free T-shirt!';
        shirtCase.Priority  = 'Ultra High';
        shirtCase.AccountId = acc.Id;
        insert shirtCase;
    }
 }
@isTest
public class TestTShirts {
    static testMethod void accountCreator() {
        Account acc = new Account();
        acc.Name    = 'Tesla Motors';
        insert acc;
    }
}
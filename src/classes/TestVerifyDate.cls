@isTest
public class TestVerifyDate {
    
    @isTest static void testCheckDatesSecond(){
        Date myDate = Date.newInstance(2001, 3, 21);
        Date myDate2 = Date.newInstance(2002, 3, 21);
        Date myDate3 = Date.newInstance(2001, 3, 25);
        Date d = VerifyDate.CheckDates(myDate,myDate3);
        System.assertEquals( myDate3, d);
        Date t = VerifyDate.CheckDates(myDate,myDate2);
        Integer totalDays = Date.daysInMonth(myDate.year(), myDate.month());
        Date lastDay = Date.newInstance(myDate.year(), myDate.month(), totalDays);
        System.assertEquals( lastDay, t);
        
    }
    

    
    @isTest static void testSetEndOfMonth(){
        Date myDate = Date.newInstance(2001, 3, 21);
        Date expectedDate = Date.newInstance(2001, 3, 31);
        Date d = VerifyDate.SetEndOfMonthDate(myDate);
        
        System.assertEquals(expectedDate, d);
        
        
        
    }
    
    @isTest static void testDateWithin30Days(){
        Date myDate = Date.newInstance(2001, 3, 21);
        Date myDate2 = Date.newInstance(2000, 3, 21);
        
        Boolean f = VerifyDate.DateWithin30Days(myDate,myDate2);
        Boolean t = VerifyDate.DateWithin30Days(myDate2,myDate);
        System.assertEquals(false, f);
        System.assertNotEquals(true, t);
        
        
    }

}
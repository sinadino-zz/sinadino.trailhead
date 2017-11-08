public class StringArrayTest{

//The generateStringArray method must return an array (or list) of strings. 
//Each string must have a value in the format 'Test n' where n is the index of the current string in the array. 
// The number of returned strings is specified by the integer parameter to the 'generateStringArray' method.

       public static List<String> generateStringArray(Integer n){
   
       String[] test = new List<String>();
   
       for (integer i = 0; i <= n; ++i){
        test.add('test' + i);
        System.debug('test' + i);
       }
        System.debug(test);
        return test;
   }
}
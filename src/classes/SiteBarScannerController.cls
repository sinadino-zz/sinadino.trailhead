public class SiteBarScannerController {

	  public integer i;
    public integer j;
		public String scanData {get; set;}
		List<String> scanDataList = new List<String> {};
		public String z = '';
		public boolean flag = true;
		public List<String> x = new List<String>{};
		List<evt__Session_Assignment__c> attended = new List<evt__Session_Assignment__c> {};
		List<evt__Attendee__c> attendedList = new List<evt__Attendee__c> {};


		public SiteBarScannerController() {
      //logic here
		}

		public boolean hasNext(){

							 if(i >= scanDataList.size()) {
									 return false;
							 } else {
									 return true;
							 }
		}


	  public PageReference processData(){
		scanDataList = scanData.split('\\n');
		System.debug('this is i  ' + i);
		System.debug('this is scanDataList size ' + scanDataList.size());
		System.debug('this is scanData size ' + scanData.length());

				i = 0;
				j = 0;
				while( i <= scanDataList.size() - 1){
						System.debug('this is i  ' + i);
						// the list must start with the session id
		        if (scanDataList[i].trim().startswith('a0w')){
		           z = scanDataList[i].trim();
							 System.debug('this is the session ID ' + z);
							 j = i + 1;

			            for (integer idx = j; idx < scanDataList.size(); idx++){
			 							 // if there are two session ids one after another we want to break because no one has attended the session.
			                if (scanDataList[idx].trim().startswith('a0w')) break;
							        x.add(scanDataList[idx].trim());
										  System.debug('this is an attendee  ' + scanDataList[idx] );

			            }

									System.debug(' =====> I am outside the loop. x = '+x);
									attended = [SELECT evt__Attendee__r.Name, evt__Event_Session__c, evt__Status__c FROM evt__Session_Assignment__c where evt__Attendee__r.Name IN :x and evt__Event_Session__c = :z];
									System.debug(' =====> This is the attended List' + attended);
									// we now iterate through the list and set session assignment status field to attended
									for ( evt__Session_Assignment__c sessions : Attended ){
											sessions.evt__Status__c = 'Attended';
											System.debug(' =====> session assignment status' + sessions);
											upsert sessions;
									}

		         }
		         x.clear(); // clear the list for next event session attendees list
	           i++;

		    }

     return null;

		 }



   }
/*

/*	attended = [SELECT evt__Attendee__r.Name,evt__Event_Session__c,evt__Status__c FROM evt__Session_Assignment__c where evt__Attendee__r.Name IN :x and evt__Event_Session__c = :z];
	// we now iterate through the list and set session assignment
	for ( evt__Session_Assignment__c sessions : Attended ){
			sessions.evt__Status__c = 'Cancelled';
			System.debug(' =====> session assignment status' + sessions);
			upsert sessions;
	}



	 Map<Id,Set<String>> advisorCarriers = new Map<Id,Set<String>>();
	        Boolean firstPass;

	        for(Policy__c p: [SELECT Id,Carrier__r.Name,Contact__c FROM Policy__c WHERE Contact__c =: advisorIds ORDER BY Contact__c]){
	            if(advisorCarriers.isEmpty()){
	                Set<String> carriers = new Set<String>();
	                carriers.add(p.Carrier__r.Name);
	                advisorCarriers.put(p.Contact__c,carriers);
	                firstPass = true;
	                System.Debug('firstAdd : ' + advisorCarriers);
	            }
	            if(advisorCarriers.containsKey(p.Contact__c) && firstPass == false){
	                advisorCarriers.get(p.Contact__c).add(p.Carrier__r.Name);
	                System.Debug('Add if same key found: ' + advisorCarriers);
	            }
	            if(!advisorCarriers.containsKey(p.Contact__c)){
	                Set<String> carriers = new Set<String>();
	                carriers.add(p.Carrier__r.Name);
	                advisorCarriers.put(p.Contact__c,carriers);
	                System.Debug('Add if key not found: ' + advisorCarriers);
	            }
	            firstPass = false;
	        }

	        for(Id i: advisorCarriers.keySet()){
	            System.Debug('Contact = ' + i);
	            for(String s : advisorCarriers.get(i)){
	                System.Debug('Carrier = ' + s);
	            }

	        }




	 // functionality ready for one record at time
 		/*  System.debug('=======>'+ this.scanData);
 			attendedList = [Select Name, evt__Attended__c from evt__Attendee__c where Name = :scanData ];
 			attendedList[0].evt__Attended__c = true;
       System.debug('=======> attended?'+ attendedList[0].evt__Attended__c);
 			upsert attendedList[0];
   /* // trying to trim thescanDataList string and remove commas, then adding the substring wrapped on white spaces into cleanFields List
 	    if (scanData == null)   {
 					System.debug('=======> no input has been detected');
       }

 	      List<String> lines =scanDataList.split('[\n] , [\r]');

 				for (String line : lines){
 	          if (line.replaceAll(',','').trim().length() == 0) break;

 						List<String> fields = line.split(',');
 						List<String> cleanFields = new List<String>();

 							for( String field : fields){
 								 if (field.startsWith('') || field.endsWith(''))
 								 		cleanFields.add(field);
 										System.debug('========> These are the cleaned field' + field);
 							}

 							this.allfields.add(cleanFields);
 							attendee = [SElECT evt__attended__c from evt__attendee__c where evt__attendee__c.Name = :lines ];

 				}




 			// trying to split thescanDataList string into parts and populate a List string
       List<String> parts = scanData.split('[\\r],[\\n]');
 			String attendee1 = parts.split('[\\r],[\\n]');
 			attendee1 = parts.get(0);
 			System.debug('=======> attendee1' + attendee1);
 		  		for ( String i : parts){

 						System.debug('========> this is the size of your part' + parts );

 		  	}

       List<String> brokenParts = parts[0].split('[\\r],[\\n]');
 			for ( String j : brokenParts) {
 				  System.debug('========> this is the broken parts' + brokenParts);
 			} */
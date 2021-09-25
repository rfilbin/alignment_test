/**
 * @description       : 
 * @author            : robert@venturetechgroup.com
 * @group             : VentureTech Group
 * @last modified on  : 2021-08-30
 * @last modified by  : robert@venturetechgroup.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   2021-06-18   robert@venturetechgroup.com   Initial Version
**/
@IsTest
private class EmbeddedSigningControllerTest {

    @TestSetup
    static void setup_EmbddedSigningTest(){
          // Create test data
          Account myAccount = new Account(Name = 'Test Account');
          insert myAccount;
              
          Contact myContact = new Contact(
              AccountId = myAccount.Id,
              FirstName = 'Test',
              LastName = 'Contact',
              Phone = '555-1234-5678',
              Email = 'test.contact@example.com');
          insert myContact;

          String orgId = UserInfo.getOrganizationId();  
          String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
          Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
          String uniqueName = orgId + dateString + randomInt;  

          Id profileId = [Select Id From Profile Where Name ='Partner Community User'].Id;

          User tempUser = new User(  
            FirstName = 'TestDSDCommunity',  
            LastName = 'Contact',  
            email = uniqueName + '@sfdc' + orgId + '.org',  
            Username = uniqueName + '@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId
          );    

          tempUser.ContactId = myContact.Id;

          insert tempUser;

          Co_Developer_Application__c devApp = new Co_Developer_Application__c(Portal_Account__c=myAccount.Id, Title__c='Test User');
          insert devApp;
    }

    @IsTest
    static void test_embeddedSigning_SendEnvelope() {
        // Mock the DocuSign eSignature API
        dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());

        User docuSignTestSender = dfsle.UserMock.createDocuSignSender();
        
        // Run the test as a DocuSign Sender. This is required by dfsle.EnvelopeService.sendEnvelope
        System.runAs(docuSignTestSender) {

            Test.startTest();
            String envelopeId = EmbeddedSigningController.sendEnvelope(String.valueOf(dfsle.UUID.randomUUID()), 'test template', docuSignTestSender.Id);
            Test.stopTest();

            System.assertNotEquals(null, envelopeId);
        }
    }

    @IsTest
    static void test_embeddedSigning_GetEmbeddedSigningUrl() {
        // Mock the DocuSign eSignature API
        dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());

        User docuSignTestSender = dfsle.UserMock.createDocuSignSender();
        
        // Run the test as a DocuSign Sender. This is required by dfsle.EnvelopeService.sendEnvelope
        System.runAs(docuSignTestSender) {

            Test.startTest();
            String signUrl = EmbeddedSigningController.getEmbeddedSigningUrl(String.valueOf(dfsle.UUID.randomUUID()), 'https://www.dsdconnect.net');
            Test.stopTest();
            
            System.assertNotEquals(null, signurl);
        }
    }

    @IsTest
    static void test_badpermissions() {
        String errorMessage;

        Test.startTest();
        try {
            Contact c = [SELECT Id FROM Contact WHERE Email = 'test.contact@example.com'];
            String envelopeId = EmbeddedSigningController.sendEnvelope(String.valueOf(dfsle.UUID.randomUUID()), 'test template', c.Id);
        } catch(AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertEquals('Script-thrown exception', errorMessage);
    }

    @IsTest
    static void test_updateAccountSigningDate() {
        Account a = [SELECT Id, NDA_Date__c, Partnership_Agreement_Signed__c FROM Account WHERE Name = 'Test Account'];

        User u = [SELECT Id, Contact.AccountId FROM User WHERE FirstName = 'TestDSDCommunity'];

        String ndaResponse = EmbeddedSigningController.updateAccountSigningDate('NDA', u.Id);

        Account ndaUpdatedAccount = [SELECT Id, NDA_Date__c, Partnership_Agreement_Signed__c FROM Account WHERE Name = 'Test Account'];

        System.assertEquals(Date.today(), ndaUpdatedAccount.NDA_Date__c);

        String partnerResponse = EmbeddedSigningController.updateAccountCollaborationSigningDate('Collaboration', u.Id);

        Account collabUpdatedAccount = [SELECT Id, NDA_Date__c, Partnership_Agreement_Signed__c, Portal_Status__c FROM Account WHERE Name = 'Test Account'];

        System.assertEquals(Date.today(), collabUpdatedAccount.Partnership_Agreement_Signed__c);
        System.assertEquals('Onboarding - Application', collabUpdatedAccount.Portal_Status__c);
    }
}
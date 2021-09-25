@isTest
public class FinancialAnalysisTriggerHandler_Test {
    
    @testSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Account 1234');
        insert testAccount;

        Contact testContact = new Contact(LastName = 'TestCon12345', AccountId = testAccount.id);
        insert testContact;

        User newUser1 = createPartnerUser(testContact.Id);
    }

    @isTest
    static void createShareRecords_Test() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
            PortfolioFinancialAnalysis__c testFinancialAnalysis = new PortfolioFinancialAnalysis__c(
                Name = 'Test Financial Analysis',
                Customers_Partner__c = testAccount.Id
            );

            insert testFinancialAnalysis;
        Test.stopTest();

        List<PortfolioFinancialAnalysis__Share> shareRecords = [SELECT Id FROM PortfolioFinancialAnalysis__Share];

        System.assert(shareRecords.size() == 1);
    }

    private static user createPartnerUser(Id contactId){
        Profile portalProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'DSD Partner User'
        ];

        User u = new User(
            UserName = 'test_' + Math.random() + '@test.com',
            FirstName = 'Test-First',
            LastName = 'Test-Last',
            Alias = 'test',
            email = 'test' + Math.random() + '@test.com',
            CommunityNickName = string.valueOf(Math.random()).substring(0,6),
            ProfileID = portalProfile.id,
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US',
            ContactID = contactId
        );

        insert u;

        return u;
    }
}
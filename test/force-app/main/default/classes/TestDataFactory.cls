public with sharing class TestDataFactory {
    public static Opportunity createOpportunity(String recordType) {
        Opportunity opp = new Opportunity();
        opp.StageName = 'Pre-Qualified';
        opp.Name = String.valueOf(Math.abs(Crypto.getRandomLong()));
        opp.CloseDate = Date.today().addDays(1);
        
        if(recordType == 'Portfolio') {
            opp.RecordTypeId = Util.getrecordTypIdByName(recordType);
            return opp;
        }
        
        opp.RecordTypeId = Util.getrecordTypIdByName(recordType);
        return opp;
    }
    
    public static User createUser(String name, String username, Id profileId, Boolean insertUser) {
        if (name == null) {name = 'Test';}
        if (username == null) {
            username = String.format('test{0}{1}@email.com',
                new List<String> {
                    String.valueOf(Datetime.now()),
                    String.valueOf(Crypto.getRandomInteger())
                }).replaceAll('[^A-Za-z0-9@.]+', '');
        }
        if (profileId == null) {profileId = [SELECT Id FROM Profile WHERE Name LIKE '%System Administrator%' LIMIT 1 ].Id;}
        User newUser = new User(
            LastName = name, Alias = 'test', Email = username, Username = username,
            CommunityNickname = username, TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', ProfileId = profileId
        );

        if (insertUser) {
            if (!Schema.sObjectType.User.isCreateable()) {return null;}
            insert newUser;
        }
        return newUser;
    }
}
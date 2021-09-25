public class FinancialAnalysisTriggerHelper {
    
    public static void shareRecordsWithPortalUsersOnTheSameAccount(List<PortfolioFinancialAnalysis__c> financialAnalysisList) {
        Map<Id, Account> partnerAccountMap;
        Map<Id, List<PortfolioFinancialAnalysis__c>> accountAndFinancialAnalysisMap = new Map<Id, List<PortfolioFinancialAnalysis__c>>();

        for(PortfolioFinancialAnalysis__c financialAnalysis : financialAnalysisList) {
            if(financialAnalysis.Customers_Partner__c != null) {
                if(!accountAndFinancialAnalysisMap.containsKey(financialAnalysis.Customers_Partner__c)) {
                    accountAndFinancialAnalysisMap.put(financialAnalysis.Customers_Partner__c, new List<PortfolioFinancialAnalysis__c>{financialAnalysis});
                } else {
                    List<PortfolioFinancialAnalysis__c> tempList = accountAndFinancialAnalysisMap.get(financialAnalysis.Customers_Partner__c);
                    tempList.add(financialAnalysis);
                    accountAndFinancialAnalysisMap.put(financialAnalysis.Customers_Partner__c, tempList);
                }
            }
        }

        try {
            partnerAccountMap = new Map<Id, Account>([
                SELECT Id,
                    (
                        SELECT Id
                        FROM Users
                    )
                FROM Account
                WHERE Id IN :accountAndFinancialAnalysisMap.keySet()
                AND IsPartner = true
            ]);
        } catch(Exception e) {
            partnerAccountMap = new Map<Id, Account>();
        }

        if(partnerAccountMap.size() > 0) {
            shareRecords(partnerAccountMap, accountAndFinancialAnalysisMap);
        }
    }

    private static void shareRecords(Map<Id, Account> partnerAccountMap, Map<Id, List<PortfolioFinancialAnalysis__c>> accountAndFinancialAnalysisMap) {
        List<PortfolioFinancialAnalysis__Share> shareRecordsList = new List<PortfolioFinancialAnalysis__Share>();

        for(Id accountId : partnerAccountMap.keySet()) {
            Account tempAccount = partnerAccountMap.get(accountId);
            
            if(tempAccount.Users != null && tempAccount.Users.size() > 0) {
                for(User tempUser : tempAccount.Users) {
                    List<PortfolioFinancialAnalysis__c> financialAnalysisList = accountAndFinancialAnalysisMap.get(accountId);

                    for(PortfolioFinancialAnalysis__c tempFinancialAnalysis : financialAnalysisList) {
                        if(tempFinancialAnalysis.OwnerId != tempUser.Id) {
                            shareRecordsList.add(
                                new PortfolioFinancialAnalysis__Share(
                                    AccessLevel = 'Edit',
                                    ParentId = tempFinancialAnalysis.Id,
                                    UserOrGroupId = tempUser.Id
                                )
                            );
                        }
                    }
                }
            }
        }

        if(shareRecordsList.size() > 0) {
            insert shareRecordsList;
        }
    }
}
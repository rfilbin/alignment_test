public class FinancialAnalysisTriggerHandler {
    
    public static void handleAfterInsert(List<PortfolioFinancialAnalysis__c> financialAnalysisList) {
        FinancialAnalysisTriggerHelper.shareRecordsWithPortalUsersOnTheSameAccount(financialAnalysisList);
    }
}
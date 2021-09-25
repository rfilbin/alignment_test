trigger FinancialAnalysisTrigger on PortfolioFinancialAnalysis__c (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            FinancialAnalysisTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}
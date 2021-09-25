@IsTest
public with sharing class Test_OpportunityService {
    @IsTest
    private static void updateTotalKilowattOnPortfolioAndSite_sucess() {
        Opportunity portfolio = TestDataFactory.createOpportunity('Portfolio');
        portfolio.Approved_Opportunity__c = true;
        insert portfolio;
        
        Opportunity site = createSiteRecord(portfolio.Id);
        insert site;
        
        Opportunity siteTwo = createSiteRecord(portfolio.Id);
        insert siteTwo;
        
        
        site = OpportunitySelector.getOpportunityById(site.Id);
        siteTwo = OpportunitySelector.getOpportunityById(siteTwo.Id);
        portfolio = OpportunitySelector.getOpportunityById(portfolio.Id);
        System.assertEquals(portfolio.Total_Portfolio_kwDC__c, site.Total_Portfolio_kwDC__c + siteTwo.Total_Portfolio_kwDC__c);
        
        Opportunity portfolioTwo = TestDataFactory.createOpportunity('Portfolio');
        portfolioTwo.Approved_Opportunity__c = true;
        insert portfolioTwo;
        
        Opportunity siteThree = createSiteRecord(portfolioTwo.Id);
        siteThree.Roof_DC_kW__c = 499;
        insert siteThree;
        
        siteThree = OpportunitySelector.getOpportunityById(siteThree.Id);
        portfolioTwo = OpportunitySelector.getOpportunityById(portfolioTwo.Id);
        
        System.assertEquals(siteThree.Total_kWdc__c, siteThree.Total_Portfolio_kwDC__c);
        System.assertEquals(portfolioTwo.Total_Portfolio_kwDC__c, siteThree.Total_Portfolio_kwDC__c);
        
    }
    
    private static Opportunity createSiteRecord(Id portfolioId) {
        Opportunity record = TestDataFactory.createOpportunity('Portfolio Site');
        record.Name = 'HD-4564';
        record.Toggle__c = true;
        record.Cost_W__c = 30.00;
        record.Price_W__c = 20.00;
        record.Roof_DC_kW__c = 50.00;
        record.Ground_DC_kW__c = 41.00;
        record.Carport_DC_kW__c = 56.00;
        record.StageName = 'Pre-Qualified';
        record.Posted_to_RFP_Team__c = true;
        record.Approved_Opportunity__c = true;
        record.Posted_to_Dev_Eng_Mgr__c = true;
        record.Portfolio_Opportunity__c = portfolioId;
        return record;
    }
}
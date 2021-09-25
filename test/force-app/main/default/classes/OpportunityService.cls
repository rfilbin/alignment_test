public with sharing class OpportunityService {
    public static void updateTotalKilowattOnPortfolioAndSite(List<Opportunity> records, Map<Id, Opportunity> oldRecordsMap) {
        List<Opportunity> opportunitiesWithUpdatedKilowatts = new List<Opportunity>();
        for(Opportunity opp : records){
            // Get the opptys with updated Total kWdc as well as ones that changed to/from Closed Lost
            if(oldRecordsMap == null || !oldRecordsMap.containsKey(opp.Id) ||
               (oldRecordsMap.containsKey(opp.Id) && (
                opp.StageName == 'Closed Lost' && oldRecordsMap.get(opp.Id).StageName != 'Closed Lost' ||
                opp.StageName != 'Closed Lost' && oldRecordsMap.get(opp.Id).StageName == 'Closed Lost'))){
                   opportunitiesWithUpdatedKilowatts.add(opp);
               }
        }
        
        if(opportunitiesWithUpdatedKilowatts.isEmpty()) return;
        List<Id> portfolioIds = new List<Id>();

        for(Opportunity site : opportunitiesWithUpdatedKilowatts) {
            if(Util.getrecordTypeOpportunityNameById(site.RecordTypeId) == 'Portfolio Site') {
                portfolioIds.add(site.Portfolio_Opportunity__c);
            }
        }

        List<Opportunity> sites = OpportunitySelector.getOpportunitySites(portfolioIds);
        
        Map<Id, List<Opportunity>> portfolioIdToSites = new Map<Id, List<Opportunity>>();
        
        for(Opportunity site : sites) {
            if(portfolioIdToSites.get(site.Portfolio_Opportunity__c) == null) {
                portfolioIdToSites.put(site.Portfolio_Opportunity__c, new List<Opportunity>{site});
                continue;
            }
            portfolioIdToSites.get(site.Portfolio_Opportunity__c).add(site);   
        }
        
       Map<Id, Decimal> portfolioIdToTotalKilowatts = new Map<Id, Decimal>();
       portfolioIds = Util.removeDuplicatesFromList(portfolioIds);
       
       Map<Id, Opportunity> portfolioMap = OpportunitySelector.getPortfolioMapByRecordIds(portfolioIds);
       
       List<Opportunity> toUpdate = new List<Opportunity>();
       Decimal totalKilowatts = 0.0;
       
       for(Id porfoilioId : portfolioIds) {
            if(!portfolioMap.containsKey(porfoilioId) || !portfolioIdToSites.containsKey(porfoilioId)) { continue; }
            for(Opportunity site : portfolioIdToSites.get(porfoilioId)) {
                site.Total_Portfolio_kwDC__c = site.Total_kWdc__c;
                totalKilowatts += site.Total_kWdc__c;
                toUpdate.add(site);
            }
            portfolioMap.get(porfoilioId).Total_Portfolio_kwDC__c = totalKilowatts;
            toUpdate.add(portfolioMap.get(porfoilioId));
            totalKilowatts = 0;
       }
       
       update toUpdate;
    }
}
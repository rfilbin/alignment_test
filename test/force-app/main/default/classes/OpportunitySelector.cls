public with sharing class OpportunitySelector {
    public static Opportunity getOpportunityById(Id recordId) {
        return [
            SELECT
                Id,
                Roof_DC_kW__c,
                Ground_DC_kW__c,
                Carport_DC_kW__c,
                Total_Cost__c,
                Total_kWdc__c,
                Portfolio_Opportunity__c,
                Total_Portfolio_kwDC__c
            FROM Opportunity
            WHERE Id =: recordId
            LIMIT 1
        ];
    }
    
    public static List<Opportunity> getOpportunities(List<Id> recordIds) {
        return [
            SELECT
                Id,
                Roof_DC_kW__c,
                Ground_DC_kW__c,
                Carport_DC_kW__c,
                Total_Cost__c,
                Total_kWdc__c,
                Total_Portfolio_kwDC__c,
                Portfolio_Opportunity__c
            FROM Opportunity
            WHERE Portfolio_Opportunity__c IN: recordIds
        ];
    }
    
    public static List<Opportunity> getOpportunitySites(List<Id> recordIds) {
        return [
            SELECT
                Id,
                Roof_DC_kW__c,
                Ground_DC_kW__c,
                Carport_DC_kW__c,
                Total_Cost__c,
                Total_kWdc__c,
                RecordTypeId,
                Total_Portfolio_kwDC__c,
                Portfolio_Opportunity__c
            FROM Opportunity
            WHERE Portfolio_Opportunity__c IN: recordIds
            AND StageName != 'Closed Lost'
            
        ];
    }
    
    public static Map<Id, Opportunity> getPortfolioMapByRecordIds(List<Id> recordIds) {
        return new Map<Id, Opportunity>([
            SELECT 
                Id, 
                Total_Portfolio_kwDC__c 
            FROM Opportunity 
            WHERE Id IN: recordIds]
        );
    }
    
    public static List<Opportunity> getOpportunitiesWithTeamMembers(List<Id> recordIds){
        return [
            SELECT
                Id,
                (SELECT
                    Id,
                    UserId,
                    OpportunityId
                FROM
                    OpportunityTeamMembers
                )
            FROM Opportunity
            WHERE Id IN :recordIds
        ];
    }
    
    public static Map<Id, Set<Id>> mapOpportunityToTeamMembers(List<Id> recordIds){
        List<Opportunity> opps = getOpportunitiesWithTeamMembers(recordIds);
        Map<Id, Set<Id>> teamMap = new Map<Id, Set<Id>>();
        for(Opportunity opp : opps){
            teamMap.put(opp.Id, new Set<Id>());
            for(OpportunityTeamMember teamMember : opp.OpportunityTeamMembers){
                teamMap.get(opp.Id).add(teamMember.UserId);
            }
        }
        
        return teamMap;
    }
}
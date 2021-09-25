public with sharing class OpportunityTriggerHandler extends TriggerHandler {
   public override void afterInsert() {
       OpportunityService.updateTotalKilowattOnPortfolioAndSite((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
       
       //Financial Scenario Modeling Service
       Set<Id> opportunityIds = new Set<Id>();
       for(Opportunity o : (List<Opportunity>)Trigger.new) {
           opportunityIds.add(o.id);
       }
       
       ScenarioModelingService.runModelForScenario(opportunityIds);
   }
   
   public override void afterUpdate() {
       OpportunityService.updateTotalKilowattOnPortfolioAndSite((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
       //Financial Scenario Modeling Service
       //ScenarioModelingService.runModelForScenario(Trigger.oldMap.keySet());
    }
}
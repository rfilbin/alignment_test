public with sharing class TaskRayTaskTriggerHandler extends TriggerHandler{
    
    public override void afterInsert(){
        TaskRayTaskService.createOpptyTeamMembers(Trigger.new, (Map<Id, TASKRAY__Project_Task__c>)Trigger.oldMap);
    }
    
    public override void afterUpdate(){
        TaskRayTaskService.createOpptyTeamMembers(Trigger.new, (Map<Id, TASKRAY__Project_Task__c>)Trigger.oldMap);
    }
}
public with sharing class TaskRayTaskService {

    public static void createOpptyTeamMembers(List<TASKRAY__Project_Task__c> newRecords, Map<Id, TASKRAY__Project_Task__c> oldRecordsMap){
        List<TASKRAY__Project_Task__c> ownerChanged = Util.getRecordsWithChangedValues(newRecords, oldRecordsMap, 'OwnerId');
        if(ownerChanged.isEmpty()) { return; }
        List<TASKRAY__Project_Task__c> ownerIsUser = new List<TASKRAY__Project_Task__c>();
        Set<Id> opptyIds = new Set<Id>();
        for(TASKRAY__Project_Task__c trTask : ownerChanged){
            if(trTask.OwnerId.getSObjectType() == Schema.getGlobalDescribe().get('User')){
                ownerIsUser.add(trTask);
                opptyIds.add(trTask.TASKRAY__trOpportunity__c);
            }
        }
        if(ownerIsUser.isEmpty()) { return; }
        Map<Id, Set<Id>> relatedOppty = OpportunitySelector.mapOpportunityToTeamMembers(new List<Id>(opptyIds));
        List<OpportunityTeamMember> newTeamMembers = new List<OpportunityTeamMember>();
        
        for(TASKRAY__Project_Task__c trTask : ownerIsUser){
            if(relatedOppty.containsKey(trTask.TASKRAY__trOpportunity__c)){
                Boolean found = false;
                for(Id taskOwnerId : relatedOppty.get(trTask.TASKRAY__trOpportunity__c)){
                    if(taskOwnerId == trTask.OwnerId){
                        found = true;
                        break;
                    }
                }
                if(!found){
                    OpportunityTeamMember teamMember = new OpportunityTeamMember(
                        OpportunityId = trTask.TASKRAY__trOpportunity__c,
                        UserId = trTask.OwnerId,
                        TeamMemberRole = trTask.Team__c
                    );
                    newTeamMembers.add(teamMember);
                }
            }
        }
        if(!newTeamMembers.isEmpty()) insert newTeamMembers;
    }
}
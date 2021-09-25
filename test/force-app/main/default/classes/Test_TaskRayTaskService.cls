@IsTest
public class Test_TaskRayTaskService {

    @IsTest
    static void testCreateTeamMemberOnInsert(){
        User testUser = TestDataFactory.createUser(null, null, null, true);
        Opportunity testOpp = TestDataFactory.createOpportunity('Portfolio');
        insert testOpp;
        TASKRAY__Project_Task__c testTask = new TASKRAY__Project_Task__c(OwnerId = testUser.Id, TASKRAY__trOpportunity__c = testOpp.Id);
        insert testTask;
        
        List<OpportunityTeamMember> teamMembers = getTestTeamMembers(testOpp.Id);
        System.assertEquals(1, teamMembers.size());
    }
    
     @IsTest
    static void testCreateTeamMemberOnUpdate(){
        Group taskRayQueue = getTaskRayQueue();
        User testUser = TestDataFactory.createUser(null, null, null, true);
        Opportunity testOpp = TestDataFactory.createOpportunity('Portfolio');
        insert testOpp;
        TASKRAY__Project_Task__c testTask = new TASKRAY__Project_Task__c(OwnerId = taskRayQueue.Id, TASKRAY__trOpportunity__c = testOpp.Id);
        insert testTask;
        
        List<OpportunityTeamMember> teamMembers = getTestTeamMembers(testOpp.Id);
        System.assertEquals(0, teamMembers.size());
        
        testTask.OwnerId = testUser.Id;
        update testTask;
        teamMembers = getTestTeamMembers(testOpp.Id);
        System.assertEquals(1, teamMembers.size());
    }
    
    private static List<OpportunityTeamMember> getTestTeamMembers(Id oppId){
        return[
            SELECT
                Id,
                UserId
            FROM OpportunityTeamMember
            WHERE OpportunityId = :oppId
        ];
    }
    
    private static Group getTaskRayQueue(){
        return [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'trUnassigned'
            LIMIT 1
        ];
    }
}
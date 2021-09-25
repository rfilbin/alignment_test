trigger TaskRayTaskTrigger on TASKRAY__Project_Task__c (after insert, after update) {
    new TaskRayTaskTriggerHandler().run();
}
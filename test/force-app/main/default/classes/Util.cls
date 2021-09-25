public with sharing class Util {
    public class UtilException extends Exception {}
    
    public static Id getrecordTypOpportunityIdByName(String recordTypeName) {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }
    
    public static Set<Id> getUniqueIdFieldValues(List<sObject> records, String idField) {
        Set<Id> results = new Set<Id>();
        if (records != null) {
            for(sObject record : records) {
                results.add((Id)record.get(idField));
            }
        }
        return results;
    }
    
    public static String getrecordTypeOpportunityNameById(Id recordTypeId) {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(recordTypeId).getname();
    }
    
    public static List<Id> getIdFromSObject(List<SObject> records) {
        Set<Id> filtered = new Set<Id>();
        for(SObject record : records) {
            filtered.add(record.Id);
        }
        
        List<Id> results = new List<Id>(filtered);
        return results;
    }
    
    public static List<Id> removeDuplicatesFromList(List<Id> recordIds) {
        Set<Id> filtered = new Set<Id>();
        
        for(Id i : recordIds) {
            filtered.add(i);    
        }
        List<Id> results = new List<Id>(filtered);
        return results;
    }
    
    public static Id getrecordTypIdByName(String recordTypeName) {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }
    
    public static List<SObject> getRecordsWithChangedValues(List<SObject> records, Map<Id, SObject> oldRecordsMap, String field){
        if(records == null) throw new UtilException('Util.isValueChanged : record parameter cannot be null');
        if(field == null) throw new UtilException('Util.isValueChanged : field parameter cannot be null');
        if(oldRecordsMap == null) {
            // this is as a record insert - treat as changed
            return records;
        }

        List<SObject> updatedRecords = new List<SObject>();
        for(SObject record : records){
            if(!oldRecordsMap.containsKey(record.Id) || record.get(field) != oldRecordsMap.get(record.Id).get(field)){
                updatedRecords.add(record);
            }
        }
        
        return updatedRecords;
    }
}
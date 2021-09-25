public class ScenarioModelingService {
	
    @future(callout=true)
    public static void runModelForScenario(Set<Id> oppIds) {
        // Start with a SOQL Query of Opps to get data you need
        // Then for each result
        // DO YOUR HTTP STUFF HERE

		List<Opportunity> opportunities = [SELECT Id, Assumption_Set__r.Term_Years__c, 
                                           Assumption_Set__r.Degradation__c,  
                                           Assumption_Set__r.Depreciation_Allocation__c,  
                                           Assumption_Set__r.Escalator__c, 
                                           Assumption_Set__r.Income_Tax_Rate__c,  
                                           Assumption_Set__r.ITC_Eligibility__c,  
                                           Assumption_Set__r.OandM_Escalator__c, 
                                           Assumption_Set__r.Planned_Maintenance__c, 
                                           Assumption_Set__r.Unplanned_Maintenance__c,
                                           Contractual_Commercial_Operation_Date__c,
                                           Price__c,
                                           DC_Size__c,
                                           Year_One_Yield__c,
                                           Total_Build_Cost__c
                                              FROM Opportunity WHERE Id = :oppIds ];        
        for ( Opportunity o : opportunities) {
            
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            ModelRequestPayload payload = new ModelRequestPayload();
            payload.query = 'mutation calc($assumptionSet:AssumptionSet, $inputs:InputSet) { calculateProforma(assumption_set:$assumptionSet, input_set: $inputs) {netPresentValue internalRateOfReturn }}';
            
            
            //payload.variables.assumptionSet.projectDetails.comOperationDate = '1/1/2021';
            //payload.variables.assumptionSet.contractDetails.termYears = 20;
            //payload.variables.assumptionSet.contractDetails.escalator = 1;
            //payload.variables.assumptionSet.productionAssumptions.degradation = 0.5;
            //payload.variables.assumptionSet.operationCosts.plannedMaintenance = 7.3;
            //payload.variables.assumptionSet.operationCosts.unplannedMaintenance = 3.6;
            //payload.variables.assumptionSet.operationCosts.oAndMEscalator = 2.0;
            //payload.variables.assumptionSet.depreciation.allocation = 97.0;
            //payload.variables.assumptionSet.taxes.itcEligibility = 26.0;
            //payload.variables.assumptionSet.taxes.incomeTaxRate = 21.0;
            //payload.variables.inputs.projectDetails.comOperationDate = '1/1/2021';
            //payload.variables.inputs.contractDetails.price = 0.09;
            //payload.variables.inputs.systemDetails.dcSize = 1000.0;
            //payload.variables.inputs.productionAssumptions.yearOneYield = 1500.0;
            //payload.variables.inputs.devAndContruction.totalBuildCost = 1.6;
            
            payload.variables.assumptionSet.projectDetails.comOperationDate = '1/1/2021';
            payload.variables.assumptionSet.contractDetails.termYears = o.Assumption_Set__r.Term_Years__c.intValue();
            payload.variables.assumptionSet.contractDetails.escalator = o.Assumption_Set__r.Escalator__c;
            payload.variables.assumptionSet.productionAssumptions.degradation = o.Assumption_Set__r.Degradation__c;
            payload.variables.assumptionSet.operationCosts.plannedMaintenance = o.Assumption_Set__r.Planned_Maintenance__c;
            payload.variables.assumptionSet.operationCosts.unplannedMaintenance = o.Assumption_Set__r.Unplanned_Maintenance__c;
            payload.variables.assumptionSet.operationCosts.oAndMEscalator = o.Assumption_Set__r.OandM_Escalator__c;
            payload.variables.assumptionSet.depreciation.allocation = o.Assumption_Set__r.Depreciation_Allocation__c;
            payload.variables.assumptionSet.taxes.itcEligibility = o.Assumption_Set__r.ITC_Eligibility__c;
            payload.variables.assumptionSet.taxes.incomeTaxRate = o.Assumption_Set__r.Income_Tax_Rate__c;
            payload.variables.inputs.projectDetails.comOperationDate = o.Contractual_Commercial_Operation_Date__c.format();
            payload.variables.inputs.contractDetails.price = o.Price__c;
            payload.variables.inputs.systemDetails.dcSize = o.DC_Size__c;
            payload.variables.inputs.productionAssumptions.yearOneYield = o.Year_One_Yield__c;
            payload.variables.inputs.devAndContruction.totalBuildCost = o.Total_Build_Cost__c;
            
            String payloadStr = ModelRequestPayload.serialize(payload);
            
            System.debug(payloadStr);
            
            request.setEndpoint('https://dsd-model-api.azurewebsites.net/api/graphqlapi');
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json;charset=UTF-8');
            request.setBody(payloadStr);
            
            HttpResponse response = http.send(request);
            if(response.getStatusCode() != 200) {
                System.debug('The status code was not expected" ' +
                            response.getStatusCode() + ' ' + response.getStatus());
            }
            else {
                
                System.debug(response.getBody());
                ModelResponsePayload resPayload = ModelResponsePayload.parse(response.getBody());
                o.Net_Present_Value_NPV__c = resPayload.data.calculateProforma.netPresentValue;
                o.Internal_Rate_of_Return_IRR__c = resPayload.data.calculateProforma.internalRateOfReturn * 100;
                update o;
            }
        }
        
    }
}